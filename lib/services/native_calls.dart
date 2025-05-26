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

  static Future<bool> hasMasterKey() async {
    if (kIsWeb || kIsWasm) {
      // Secure storage is not available in web :(
      return false;
    }

    try {
      return await _platform.invokeMethod<bool>("hasMasterKey") ?? false;
    } on PlatformException catch (e) {
      log("Cannot check if a master key is already enrolled. Assume false. Error: $e");
      return false;
    }
  }

  static Future<bool> enrollMasterKey(String userSecret, String userHint) async {
    if (kIsWeb || kIsWasm) {
      // Secure storage is not available in web :(
      return false;
    }
    try {
      return await _platform.invokeMethod<bool>("enrollMasterKey", { "userSecret": userSecret, "userHint": userHint }) ?? false;
    } on PlatformException catch (e) {
      log("Cannot check if a master key is already enrolled. Assume false. Error: $e");
      return false;
    }
  }

  /// Returns a tuple where the **first item** is the **master key** and the **second item** is the **the hint**.
  static Future<(String, String)?> retrieveMasterKey() async {
    if (kIsWeb || kIsWasm) {
      // Secure storage is not available in web :(
      return null;
    }

    if (!await hasMasterKey()) {
      log("Cannot retrieve master key as it has not been enrolled yet.");
      return null;
    }

    try {
      List<String?>? result = (await _platform.invokeMethod<List<Object?>?>(
              "retrieveMasterKey"))?.cast<String?>();

      if (result != null && result.length == 2) {
        return (result[0]!, result[1]!);
      }

      return null;
    } on PlatformException catch (e) {
      log("Cannot retrieve master key as secure storage is not available. Assume false. Error: $e");
      return null;
    }
  }
}