package dev.klier.qrvault

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "dev.klier.qrvault/language"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel to communicate with Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppLocale" -> {
                    // Get the app-specific locale if available (Android 13+)
                    val locale = if (Build.VERSION.SDK_INT >= 33) { // API 33 is Android 13 (Tiramisu)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                            context.resources.configuration.locales[0]
                        } else {
                            context.resources.configuration.locale
                        }
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
