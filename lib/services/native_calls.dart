import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeCalls {
  static const _platform = MethodChannel('dev.klier.qrvault/crypto');

  static Future<bool> hasSecureStorage() async {
    if (kIsWeb || kIsWasm) {
      // Secure storage is not available in web :(
      return false;
    }

    try {
      return await _platform.invokeMethod<bool>("hasSecureStorage") ?? false;
    } on PlatformException catch (e) {
      log("Cannot check if a secure storage is available. Assume false. Error: $e");
      return false;
    }
  }
}