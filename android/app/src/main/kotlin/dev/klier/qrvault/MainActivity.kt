package dev.klier.qrvault

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private val CHANNEL_LANGUAGE = "dev.klier.qrvault/language"
        private val CHANNEL_CRYPTO = "dev.klier.qrvault/crypto"
    }

    private lateinit var masterKey: MasterKey

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        this.masterKey = MasterKey(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CRYPTO).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSecureStorage" -> {
                    result.success(masterKey.hasSecureStorage())
                }
                "hasMasterKey" -> {
                    result.success(masterKey.hasKeyFile())
                }
                "enrollMasterKey" -> {
                    call.argument<String>("userSecret")?.let { userSecret ->
                        call.argument<String>("userHint")?.let { userHint ->
                            // We must call a coroutine in order to use suspend (aka async) functions. Weird.
                            CoroutineScope(Dispatchers.Main.immediate).launch {
                                val re = masterKey.enrollMasterKey(
                                    this@MainActivity,
                                    userSecret,
                                    userHint
                                )
                                result.success(re)
                            }
                        }
                    }
                }
                "retrieveMasterKey" -> {
                    CoroutineScope(Dispatchers.Main.immediate).launch {
                        var re: List<String>? = masterKey.retrieveMasterKey(this@MainActivity)
                        if (re == null) {
                            result.success(null)
                            return@launch
                        }
                        re = re.toList()

                        result.success(re.toList())
                    }
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
                    val locale =
                        this.resources.configuration.locales[0]
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
