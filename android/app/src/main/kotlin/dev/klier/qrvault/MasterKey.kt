package dev.klier.qrvault

import android.app.KeyguardManager
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer
import java.security.KeyStore
import java.util.logging.Logger
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlin.coroutines.resume

/**
 * This is our Android-specific crypto implementation to securely seal and unseal the master key.
 *
 * The master key is unsealed using these steps:
 * 1. Take the user's raw entered master password, not the hash - **this is the master key**.
 * 2. If not existing, generate a new random AES key in hardware (if available). This random AES key
 *    can be retrieved after the user provided their PIN or biometrics. - **this is the device key**.
 * 3. Use this random AES key to encrypt/decrypt a file in private storage which stores the hash
 *    from step 1)
 *
 * This approach allows the user to quickly create and access QR codes in a secure manner.
 * It's also portable. The user can enter the same master password on a new device and retain access
 * to their old QR codes.
 */
class MasterKey(private val context: Context) {

    companion object {
        private const val CIPHER_MODE = "AES/GCM/NoPadding"

        // This alias is used to identify our encryption key in the Android KeyStore.
        private const val KEY_ALIAS = "MasterKey"
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
    }

    private val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
    private val biometricManager = context.getSystemService(Context.BIOMETRIC_SERVICE) as android.hardware.biometrics.BiometricManager
    private val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE)
    private val logger = Logger.getLogger(MasterKey::class.simpleName.toString())

    init {
        keyStore.load(null)
    }

    /**
     * This file contains the user password used to protect our QR codes but encrypted.
     */
    private val keyFile = File(context.filesDir, "masterkey.bin")

    /**
     * Returns `true` if the Android device has a lock-screen and has a biometric authentication set
     * up. This is required to use the KeyStore and therefore this feature.
     */
    fun hasSecureStorage(): Boolean {
        return keyguardManager.isDeviceSecure
                && biometricManager.canAuthenticate(
            android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG or android.hardware.biometrics.BiometricManager.Authenticators.DEVICE_CREDENTIAL
                ) == android.hardware.biometrics.BiometricManager.BIOMETRIC_SUCCESS
    }

    /**
     * Returns `true` if a random key has already been generated on this device.
     */
    fun hasDeviceKey(): Boolean {
        return keyStore.containsAlias(KEY_ALIAS)
    }

    /**
     * Returns `true` if the master key file has already been created.
     */
    fun hasKeyFile(): Boolean {
        return keyFile.exists();
    }

    /**
     * Enroll a new protection key for the masterkey.bin file.
     * @return False if the operation failed.
     */
    private fun enrollDeviceKey(): Boolean {
        if (hasDeviceKey()) {
            // This shouldn't happen. The user must explicitly delete the current one.
            logger.warning("Tried to enroll new device key while a device key already exists.")
            return false
        }

        try {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE)
            val keyGenParameterSpecBuilder = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )

            val keyGenParameter = keyGenParameterSpecBuilder
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                // Force Android to generate a secure IV
                .setRandomizedEncryptionRequired(true)
                // Force user authentication in general for access
                .setUserAuthenticationRequired(true)
                // Force user authentication on every use (e. g. for every en-/and decryption attempt)
                // Also, we only want to allow the user to use biometrics or their PIN.
                .setUserAuthenticationParameters(0,
                    KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL)
                .build()

            keyGenerator.init(keyGenParameter)

            val secretKey = keyGenerator.generateKey()
            logger.info("Enrolled new device encryption key (format: ${secretKey.format})")
        } catch (e: Exception) {
            logger.severe("Failed to enroll new master encryption key: $e")
            return false
        }

        return true
    }

    /**
     * This will write (or override) a new master key to permanent storage, protecting it with this
     * device's enrolled AES key.
     * @param userSecret "Content" of the new file which MUST be a 32 byte Argon2id hash.
     */
    suspend fun enrollMasterKey(activity: FragmentActivity, userSecret: String, userHint: String): Boolean = withContext(Dispatchers.IO) {
        if (!hasSecureStorage()) {
            logger.severe("This device has no secure storage. A master key cannot be safely stored on this device.")
            return@withContext false
        }

        if (!hasDeviceKey()) {
            logger.severe("No device secret enrolled yet. Start enrolling process ...")
            if (!enrollDeviceKey()) {
                logger.severe("Device secret failed to enroll. Cannot proceed further.")
                return@withContext false
            }
        }

        try {
            if (!keyFile.createNewFile()) {
                logger.warning("A master key is already set. The old one will be overridden!")
                keyFile.delete()
                keyFile.createNewFile()
            }
        } catch (e: IOException) {
            logger.severe("Failed to create new key file: ${e.message}")
            return@withContext false
        }

        if (!keyFile.canWrite()) {
            logger.severe("Cannot write into master key file due to missing write permissions.")
            return@withContext false
        }

        val deviceSecret = keyStore.getKey(KEY_ALIAS, null) as SecretKey
        val cipher = Cipher.getInstance(CIPHER_MODE)
        cipher.init(Cipher.ENCRYPT_MODE, deviceSecret)
        val userKeyBinary = userSecret.toByteArray()

        val authResult = withContext(Dispatchers.Main) {
            suspendCancellableCoroutine { continuation ->
                authenticate(activity, cipher,
                    onSuccess = {
                        continuation.resume(true)
                    },
                    onError = {
                        continuation.resume(false)
                    }
                )

                continuation.invokeOnCancellation {
                    logger.warning("Authentication dialogue cancelled.")
                    continuation.resume(false)
                }
            }
        }

        if (authResult) {
            try {
                val encryptedData = cipher.doFinal(userKeyBinary)

                /* The master key file looks like this:
                 * [12 byte IV][Size of encrypted content][Encrypted content][Cleartext hint]
                 */
                keyFile.outputStream().use {
                    it.write(cipher.iv)
                    it.write(ByteBuffer.allocate(Int.SIZE_BYTES).putInt(encryptedData.size).array())
                    it.write(encryptedData)
                    it.write(userHint.toByteArray())
                    it.flush();
                }

                return@withContext true
            } catch (e: Exception) {
                logger.severe("Master key file couldn't be written: ${e.message}")
                return@withContext false
            }
        } else {
            return@withContext false
        }
    }

    suspend fun retrieveMasterKey(activity: FragmentActivity): List<String>? = withContext(Dispatchers.IO) {
        if (!hasSecureStorage()) {
            logger.severe("This device has no secure storage. A master key cannot be retrieved.")
            return@withContext null
        }

        if (!hasDeviceKey()) {
            logger.severe("No device secret enrolled yet. A master key can therefore not be retrieved.")
            return@withContext null
        }

        if (!keyFile.canRead()) {
            logger.severe("Cannot read into master key file due to missing read permissions.")
            return@withContext null
        }

        val keyFile: ByteArray = keyFile.readBytes()

        // Extract our IV from the file by taking the first 12 bytes.
        val ivSpec = GCMParameterSpec(128, keyFile.copyOfRange(0, 12))

        // Extract the encrypted content from the file by taking the remaining bytes.
        val encryptedMasterKeySize = ByteBuffer.wrap(keyFile.copyOfRange(12, 16)).getInt()
        val encryptedMasterKey: ByteArray = keyFile.copyOfRange(16, 16 + encryptedMasterKeySize)

        var hint: String = ""

        // We need to check if we aren't at the end already. The user could not have set a hint.
        if (encryptedMasterKeySize + 16 < keyFile.size) {
            hint = String(keyFile.copyOfRange(16 + encryptedMasterKeySize, keyFile.size))
        }

        val deviceSecret = keyStore.getKey(KEY_ALIAS, null) as SecretKey

        val cipher = Cipher.getInstance(CIPHER_MODE)
        cipher.init(Cipher.DECRYPT_MODE, deviceSecret, ivSpec)

        val authResult = withContext(Dispatchers.Main) {
            suspendCancellableCoroutine { continuation ->
                authenticate(activity, cipher,
                    onSuccess = {
                        continuation.resume(true)
                    },
                    onError = {
                        continuation.resume(false)
                    }
                )

                continuation.invokeOnCancellation {
                    logger.warning("Authentication dialogue cancelled.")
                    continuation.resume(false)
                }
            }
        }

        if (authResult) {
            try {
                val decryptedMasterKey = cipher.doFinal(encryptedMasterKey)

                val userKey = decryptedMasterKey.decodeToString()
                return@withContext listOf<String>(userKey, hint)
            } catch (e: Exception) {
                logger.severe("Master key file couldn't be read: ${e.message}")
                return@withContext null
            }
        }

        return@withContext null
    }
    /**
     * This opens the Android dialogue where the user has to authenticate.
     * @param cipher This must be the cipher instance that will encrypt or decrypt the master key
     * file right after this authentication.
     */
    private fun authenticate(activity: FragmentActivity, cipher: Cipher, onSuccess: (BiometricPrompt.AuthenticationResult) -> Unit, onError: () -> Unit) {
        val executor = ContextCompat.getMainExecutor(activity)

        val biometricPrompt = BiometricPrompt(activity, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    onError()
                }

                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    onSuccess(result)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    onError()
                }
            })


        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Master Key access")
            .setSubtitle("Authenticate to access your master password.")
            .setDescription("This will allow QRVault to securely access your master key.")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
            .build()

        biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
    }
}