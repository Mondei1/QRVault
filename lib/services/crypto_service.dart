import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:qrvault/services/commons.dart';
import 'dart:math';

class CryptoService {
  final QrURI? uri;
  final String? userPassword;

  // Values recommended by:
  // https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id
  final argon2 = Argon2id(
    parallelism: 4,
    memory: 47104,
    iterations: 8,
    hashLength: 32,
  );

  CryptoService.forDecryption({
    required this.uri,
    required this.userPassword,
  }) {
    if (uri == null || userPassword == null) {
      throw ArgumentError(
          'URI and userPassword must be provided for decryption.');
    }
  }

  CryptoService()
      : uri = null,
        userPassword = null;

  String _generateRandomAsciiString(int length) {
    final random = Random.secure();
    const asciiStart = 33;
    const asciiEnd = 126;
    return String.fromCharCodes(Iterable.generate(
        length, (_) => asciiStart + random.nextInt(asciiEnd - asciiStart + 1)));
  }

  Future<SecretKey> _generateArgon2idKey(
      {required String password, required List<int> saltBytes}) async {
    return argon2.deriveKeyFromPassword(password: password, nonce: saltBytes);
  }

  Future<QrURI> generateQrUri({
    required QrVaultPayload payload,
    required String title,
    required String masterPassword,
    String? hint,
    int version = 1,
  }) async {
    final saltString = _generateRandomAsciiString(16);
    final ivString = _generateRandomAsciiString(16);

    final saltBytesForArgon = utf8.encode(saltString);
    final ivBytesForAes = utf8.encode(ivString);

    // TODO: Remove irrelevant check?
    if (ivBytesForAes.length != 16) {
      throw StateError(
          'Generated IV has an incorrect length. Expected 16 bytes, got ${ivBytesForAes.length} bytes.');
    }

    final encryptionKey = await _generateArgon2idKey(
        password: masterPassword, saltBytes: saltBytesForArgon);

    final messagePackBytes = QrURI.payloadToMessagePack(payload.toMap());

    final aesCtr = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);
    final secretBox = await aesCtr.encrypt(
      messagePackBytes,
      secretKey: encryptionKey,
      nonce: ivBytesForAes,
    );

    final base64Ciphertext = base64.encode(secretBox.cipherText);
    final uriEncodedCiphertext = Uri.encodeComponent(base64Ciphertext);

    return QrURI(
      title: title,
      salt: saltString,
      iv: ivString,
      content: uriEncodedCiphertext,
      hint: hint,
      version: version,
    );
  }

  Future<SecretKey> _generateArgon2idKeyFromUri() async {
    if (uri == null || userPassword == null) {
      throw StateError(
          '_generateArgon2idKeyFromUri called in invalid context.');
    }

    final saltBytes = utf8.encode(uri!.salt);

    final derivedKey = await argon2.deriveKeyFromPassword(
      password: userPassword!,
      nonce: saltBytes,
    );
    return derivedKey;
  }

  Future<Uint8List> _decryptContent(SecretKey decryptionKey) async {
    if (uri == null) {
      throw StateError(
          '_decryptContent called in invalid context (uri is null).');
    }
    final uriDecodedContent = Uri.decodeComponent(uri!.content);
    final base64DecodedCiphertext = base64.decode(uriDecodedContent);

    final ivBytes = utf8.encode(uri!.iv);

    if (ivBytes.length != 16) {
      throw ArgumentError(
          'IV must be 16 bytes long. Current IV: "${uri!.iv}" is ${ivBytes.length} bytes after UTF-8 encoding.');
    }

    final algorithm = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);

    final secretBox = SecretBox(
      base64DecodedCiphertext,
      nonce: ivBytes,
      mac: Mac.empty,
    );

    final decryptedBytes = await algorithm.decrypt(
      secretBox,
      secretKey: decryptionKey,
    );

    return Uint8List.fromList(decryptedBytes);
  }

  Future<QrVaultPayload> getDecryptedPayload() async {
    if (uri == null || userPassword == null) {
      throw StateError('getDecryptedPayload called in invalid context.');
    }

    // TODO: Make version 1 configurable somewhere.
    if (uri!.version != 1) {
      throw UnsupportedError(
          'Unsupported QRVault protocol version: ${uri!.version}');
    }

    final decryptionKey = await _generateArgon2idKeyFromUri();
    final decryptedMessagePack = await _decryptContent(decryptionKey);
    final payloadMap = QrURI.payloadFromMessagePack(decryptedMessagePack);
    return QrVaultPayload.fromMap(payloadMap);
  }
}
