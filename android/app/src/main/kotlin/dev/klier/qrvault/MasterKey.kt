package dev.klier.qrvault

import android.R.attr.data
import android.R.attr.key
import android.app.KeyguardManager
import android.content.Context
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricManager.Authenticators
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import java.util.logging.Logger
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey


/**
 * This is our Android-specific crypto implementation to securely seal and unseal the master key.
 *
 * The master key is unsealed using these steps:
 * 1. Take the user entered master password and hash it (done by Flutter)
 * 2. If not existing, generate a new random AES key in hardware (if available). This random AES key
 *    can be retrieved after the user provided their PIN or biometrics.
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
    private val biometricManager = context.getSystemService(Context.BIOMETRIC_SERVICE) as BiometricManager
    private val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE)
    private val logger = Logger.getLogger(MasterKey::class.simpleName.toString())

    init {
        keyStore.load(null)
    }

    /**
     * This file contains the hash (therefore actual encryption key) used to protect our QR codes.
     */
    private val keyFile = File(context.filesDir, "masterkey.bin")

    /**
     * Returns `true` if the Android device has a lock-screen. This is required to use the KeyStore.
     */
    fun hasSecureStorage(): Boolean {
        return keyguardManager.isDeviceSecure
                && biometricManager.canAuthenticate(
            Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL
                ) == BiometricManager.BIOMETRIC_SUCCESS
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
    fun enrollDeviceKey(): Boolean {
        if (hasDeviceKey()) {
            // This shouldn't happen. The user must explicitly delete the current one.
            logger.warning("Tried to enroll new master key while a master key already exists.")
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
                // TODO: Is `false` okay here? Theoretically, we want control over the IV but we could
                //       enforce Android to create one for us.
                .setRandomizedEncryptionRequired(false)
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
    fun encryptMasterKey(userSecret: ByteArray): Boolean {
        if (!hasSecureStorage() || !hasDeviceKey()) {
            logger.severe("Cannot encrypt master key without enrolled device secret.")
            return false
        }

        if (!keyFile.createNewFile()) {
            logger.warning("A master key is already set. The old one will be overridden!")
        }

        if (!keyFile.canWrite()) {
            logger.severe("Cannot write into master key file due to missing write permissions.")
            return false
        }

        if (userSecret.size != 32) {
            logger.severe("Tried to store a ${userSecret.size} byte value but 32 bytes were expected.")
            return false
        }

        val deviceSecret = keyStore.getKey(KEY_ALIAS, null) as SecretKey

        val cipher = Cipher.getInstance(CIPHER_MODE)
        cipher.init(Cipher.ENCRYPT_MODE, deviceSecret)

        val encryptedData = cipher.doFinal(userSecret)

        keyFile.outputStream().use {
            it.write(encryptedData)
        }

        return true
    }
}