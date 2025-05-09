import 'package:messagepack/messagepack.dart';
import 'dart:core';
import 'dart:typed_data';
import 'dart:convert';
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

    final List<String> segments = parsedUri.pathSegments;
    if (segments.length != 4) {
      throw ArgumentError(
          'Invalid URI path: Expected 4 segments (title/salt/iv/content), got ${segments.length}');
    }

    final String title = segments[0];
    final String salt = segments[1];
    final String iv = segments[2];
    final String encryptedContentFromUri = segments[3]; 

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
      content: encryptedContentFromUri,
      hint: hint,
      version: versionParam,
    );
  }

  String toUriString() {
    final String encodedTitle = Uri.encodeComponent(title);
    final String encodedSalt = Uri.encodeComponent(salt);
    final String encodedIv = Uri.encodeComponent(iv);
    final String encodedEncryptedContentForUri = Uri.encodeComponent(content);

    final Map<String, String> queryParamsMap = {'v': version};
    if (hint != null && hint!.isNotEmpty) {
      queryParamsMap['h'] = hint!;
    }

    String queryString = Uri(queryParameters: queryParamsMap).query;
    if (queryString.isNotEmpty) {
      queryString = "?$queryString";
    }

    return "qrv://$encodedTitle/$encodedSalt/$encodedIv/$encodedEncryptedContentForUri$queryString";
  }


  static Uint8List payloadToMessagePack(Map<String, dynamic> payload) {
    return msgpack.serialize(payload);
  }

  static Map<String, dynamic> payloadFromMessagePack(Uint8List messagePackBytes) {
    final dynamic deserialized = msgpack.deserialize(messagePackBytes);
    if (deserialized is Map<String, dynamic>) {
      return deserialized;
    } else if (deserialized is Map) { 
        return Map<String, dynamic>.from(deserialized);
    }
    throw FormatException('Deserialized MessagePack is not a Map<String, dynamic>. Type: ${deserialized.runtimeType}');
  }

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
    if (username != null) map['u'] = username;
    if (password != null) map['p'] = password;
    if (website != null) map['w'] = website;
    if (totpSecret != null) map['t'] = totpSecret;
    if (notes != null) map['n'] = notes;
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

   @override
  String toString() {
    return 'QrVaultPayload(username: $username, password: $password, website: $website, totpSecret: $totpSecret, notes: $notes)';
  }
}

class credentials {
    final String? username;
    final String? password;
    final String? website;
    final String? totp;
    final String? notes;

    credentials({this.username, this.password, this.website, this.totp, this.notes});
}
