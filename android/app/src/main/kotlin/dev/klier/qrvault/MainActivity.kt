package dev.klier.qrvault

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private val CHANNEL_LANGUAGE = "dev.klier.qrvault/language"
        private val CHANNEL_CRYPTO = "dev.klier.qrvault/crypto"
    }

    private val masterKey: MasterKey

    init {
        masterKey = MasterKey(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CRYPTO).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSecureStorage" -> {
                    result.success(masterKey.hasSecureStorage())
                }
                "hasMasterKey" -> {
                    result.success(masterKey.hasDeviceKey())
                }
                "encryptMasterKey" -> {

                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LANGUAGE).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppLocale" -> {
                    // Get the app-specific locale if available (Android 13+)
                    val locale = if (Build.VERSION.SDK_INT >= 33) {
                        context.resources.configuration.locales[0]
                    } else {
                        Locale.getDefault()
                    }
                    result.success(locale.toLanguageTag())
                }
                "setAppLocale" -> {
                    // This method would be used if we want to set the app-specific locale
                    // Note: This requires additional implementation for Android 13+
                    val localeTag = call.argument<String>("locale")
                    if (localeTag != null) {
                        // For now, we'll just acknowledge the request
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Locale tag is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
