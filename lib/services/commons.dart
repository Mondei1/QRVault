import 'dart:core';
import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;

///Class for the QR code URI when seperated
class QrURI {
  final String title;
  final String salt;
  final String iv;
  final String content;
  final String? hint;
  final int version;

  QrURI({
    required this.title,
    required this.salt,
    required this.iv,
    required this.content,
    this.hint,
    required this.version,
  });

  ///Function to parse the URI string to a QrURI object
  static QrURI fromUriString(String uriString) {
    final Uri parsedUri = Uri.parse(uriString);

    if (parsedUri.scheme != 'qrv') {
      throw ArgumentError('Invalid URI scheme');
    }

    //Decode the title because parsedUri.host dont encode by default
    final String title = Uri.decodeComponent(parsedUri.host);

    if (title.isEmpty && !uriString.startsWith("qrv:/")) {
      throw ArgumentError('Title (host part of URI) is missing or empty. URI format should be: qrv://title/salt/iv/content');
    }

    //Get the path segments
    final List<String> pathSegments = parsedUri.pathSegments;

    if (pathSegments.length != 3) {
      throw ArgumentError(
          'Invalid URI path: Expected 3 segments after title (salt/iv/content), got ${pathSegments.length}. Segments found: $pathSegments');
    }

    final String salt = pathSegments[0];
    final String iv = pathSegments[1];
    final String contentFromUri = pathSegments[2];

    final Map<String, String> queryParams = parsedUri.queryParameters;

    final String? hint = queryParams['h'];
    final String? versionParam = queryParams['v'];

    if (versionParam == null || versionParam.isEmpty) {
      throw ArgumentError('Missing or empty required query parameter: "v" (version)');
    }

    return QrURI(
      title: title,
      salt: salt,
      iv: iv,
      content: contentFromUri,
      hint: hint,
      version: int.parse(versionParam),
    );
  }

  ///Function to convert the QrURI object to a URI string
  String toUriString() {
    final String encodedTitle = Uri.encodeComponent(title);
    final String encodedSalt = Uri.encodeComponent(salt);
    final String encodedIv = Uri.encodeComponent(iv);
    final String encodedContentForUri = Uri.encodeComponent(content);

    final Map<String, String> queryParamsMap = {'v': version.toString()};
    if (hint != null && hint!.isNotEmpty) {
      queryParamsMap['h'] = hint!;
    }

    String queryString = "";
    //build the query string and add a ?, hint is optional but version is required
    if (queryParamsMap.isNotEmpty) {
        queryString = Uri(queryParameters: queryParamsMap).query;
        if (queryString.isNotEmpty) {
            queryString = "?$queryString";
        }
    }

    return "qrv://$encodedTitle/$encodedSalt/$encodedIv/$encodedContentForUri$queryString";
  }

  static Uint8List payloadToMessagePack(Map<String, dynamic> payload) {
    return msgpack.serialize(payload);
  }

  static Map<String, dynamic> payloadFromMessagePack(Uint8List messagePackBytes) {
    final dynamic deserialized = msgpack.deserialize(messagePackBytes);

    if (deserialized is Map<String, dynamic>) {
      return deserialized;
    } else if (deserialized is Map) {
      try {
        return Map<String, dynamic>.from(deserialized.map(
                (key, value) => MapEntry(key.toString(), value)
        ));
      } catch (e) {
        throw FormatException(
            'Deserialized MessagePack is a Map, but could not be converted to Map<String, dynamic>. Error: $e. Type: ${deserialized.runtimeType}');
      }
    }
    throw FormatException(
        'Deserialized MessagePack is not a Map. Type: ${deserialized.runtimeType}');
  }

  @override
  String toString() {
    return 'QrURI(title: $title, salt: $salt, iv: $iv, content (Base64): $content, hint: $hint, version: $version)';
  }
}

/// Some metadata about the QR code.
class QrVaultEncryptionModel {
  /// This is the current/latest URI protocol version.
  static const currentVersion = 1;

  final String title;
  /// Clear text password used to (un)seal the content.
  final String password;
  final String? hint;
  int version = currentVersion;

  QrVaultEncryptionModel({
    required this.title,
    required this.password,
    required this.version,
    this.hint,
  });

}

/// This model stores all data we can store on a QR code encrypted.
class QrVaultPayload {
  final String? username;
  final String? password;
  final String? website;
  final String? totpSecret;
  final String? notes;

  QrVaultPayload({
    this.username,
    this.password,
    this.website,
    this.totpSecret,
    this.notes,
  });

  /// Get a map containing all the properties and their shortened key names.
  /// The keys are short to save storage space.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (username != null && username!.isNotEmpty) map['u'] = username;
    if (password != null && password!.isNotEmpty) map['p'] = password;
    if (website != null && website!.isNotEmpty) map['w'] = website;
    if (totpSecret != null && totpSecret!.isNotEmpty) map['t'] = totpSecret;
    if (notes != null && notes!.isNotEmpty) map['n'] = notes;
    return map;
  }

  // Convert a map back into a model. Used after scanning and decrypting.
  factory QrVaultPayload.fromMap(Map<String, dynamic> map) {
    return QrVaultPayload(
      username: map['u'] as String?,
      password: map['p'] as String?,
      website: map['w'] as String?,
      totpSecret: map['t'] as String?,
      notes: map['n'] as String?,
    );
  }
}
