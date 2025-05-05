import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// A service to handle language-related operations, including
/// communication with the native platform for app-specific language settings.
class LanguageService {
  static const MethodChannel _channel = MethodChannel('dev.klier.qrvault/language');
  
  /// Get the current app-specific locale from the platform.
  /// On Android 13+, this will use the app-specific language setting.
  /// On other platforms, it will fall back to the system locale.
  static Future<Locale?> getAppLocale() async {
    try {
      final String localeTag = await _channel.invokeMethod('getAppLocale');
      return _localeFromTag(localeTag);
    } on PlatformException catch (e) {
      debugPrint('Failed to get app locale: ${e.message}');
      return null;
    }
  }
  
  /// Set the app-specific locale.
  /// This is primarily for Android 13+ which supports app-specific language settings.
  static Future<bool> setAppLocale(Locale locale) async {
    try {
      final bool result = await _channel.invokeMethod(
        'setAppLocale',
        {'locale': locale.toLanguageTag()},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to set app locale: ${e.message}');
      return false;
    }
  }
  
  /// Convert a BCP 47 language tag to a Locale object.
  static Locale? _localeFromTag(String localeTag) {
    final parts = localeTag.split('-');
    if (parts.isEmpty) return null;
    
    final languageCode = parts[0];
    String? countryCode;
    
    if (parts.length > 1) {
      countryCode = parts[1];
    }
    
    return Locale(languageCode, countryCode);
  }
}

/// Extension to convert a Locale to a BCP 47 language tag.
extension LocaleExtension on Locale {
  String toLanguageTag() {
    if (countryCode?.isNotEmpty == true) {
      return '$languageCode-$countryCode';
    }
    return languageCode;
  }
}
