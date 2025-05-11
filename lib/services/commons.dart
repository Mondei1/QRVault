import 'dart:core';
import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;

class QrURI {
  final String title;
  final String salt;
  final String iv;
  final String content;
  final String? hint;
  final String version;

  QrURI({
    required this.title,
    required this.salt,
    required this.iv,
    required this.content,
    this.hint,
    required this.version,
  });

  static QrURI fromUriString(String uriString) {
    final Uri parsedUri = Uri.parse(uriString);

    if (parsedUri.scheme != 'qrv') {
      throw ArgumentError('Invalid URI scheme: Expected "qrv", got "${parsedUri.scheme}"');
    }

    final String title = parsedUri.host.replaceAll("%20", " ");

    if (title.isEmpty && !uriString.startsWith("qrv:/")) {
      throw ArgumentError('Title (host part of URI) is missing or empty. URI format should be: qrv://title/salt/iv/content');
    }

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
      version: versionParam,
    );
  }

  String toUriString() {
    final String encodedTitle = Uri.encodeComponent(title);
    final String encodedSalt = Uri.encodeComponent(salt);
    final String encodedIv = Uri.encodeComponent(iv);
    final String encodedContentForUri = Uri.encodeComponent(content);

    final Map<String, String> queryParamsMap = {'v': version};
    if (hint != null && hint!.isNotEmpty) {
      queryParamsMap['h'] = hint!;
    }

    String queryString = "";
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

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (username != null && username!.isNotEmpty) map['u'] = username;
    if (password != null && password!.isNotEmpty) map['p'] = password;
    if (website != null && website!.isNotEmpty) map['w'] = website;
    if (totpSecret != null && totpSecret!.isNotEmpty) map['t'] = totpSecret;
    if (notes != null && notes!.isNotEmpty) map['n'] = notes;
    return map;
  }

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
