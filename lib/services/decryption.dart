import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:qrvault/services/commons.dart';

class DecryptionService {
    final QrURI uri;
    final String userPassword;

    DecryptionService({
        required this.uri,
        required this.userPassword,
    });

    Future<SecretKey> _generateArgon2idKey() async {
        final argon2 = Argon2id(
            parallelism: 1,      
            memory: 16,          
            iterations: 2,       
            hashLength: 32,      
        );

        final saltBytes = utf8.encode(uri.salt);

        final derivedKey = await argon2.deriveKeyFromPassword(
            password: userPassword,
            nonce: saltBytes, 
        );
        return derivedKey;
    }

    Future<Uint8List> _decryptContent(SecretKey decryptionKey) async {
        final uriDecodedContent = Uri.decodeComponent(uri.content);
        final base64DecodedCiphertext = base64.decode(uriDecodedContent);
        print(
            "Ciphertext Bytes (Hex) from URI: ${base64DecodedCiphertext.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}");

        final ivBytes = utf8.encode(uri.iv);
        print(
            "IV Bytes (Hex) from URI: ${ivBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}");
        if (ivBytes.length != 16) {
            throw ArgumentError('IV must be 16 bytes long. Current IV: "${uri.iv}" is ${ivBytes.length} bytes after UTF-8 encoding.');
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
        /*
        // ---- START TEST CODE ----
        print("--- USING HARDCODED MESSAGEPACK FOR ScannedScreen TEST ---");
        final Uint8List hardcodedMessagePack = Uint8List.fromList([
            133, 161, 117, 173, 89, 111, 117, 114, 32, 85, 115, 101, 114, 110, 97, 109, 101,
            161, 112, 175, 83, 101, 99, 114, 101, 116, 32, 112, 97, 115, 115, 119, 111, 114, 100,
            161, 119, 185, 104, 116, 116, 112, 115, 58, 47, 47, 101, 120, 97, 109, 112, 108, 101,
            46, 99, 111, 109, 47, 108, 111, 103, 105, 110,
            161, 116, 171, 84, 79, 84, 80, 32, 115, 101, 99, 114, 101, 116,
            161, 110, 170, 89, 111, 117, 114, 32, 110, 111, 116, 101, 115
        ]);
        final payloadMapFromHardcoded = QrURI.payloadFromMessagePack(hardcodedMessagePack);
        print("Payload map from hardcoded MessagePack: $payloadMapFromHardcoded");
        return QrVaultPayload.fromMap(payloadMapFromHardcoded);
        // ---- END TEST CODE ----
        */

        if (uri.version != '1') {
            throw UnsupportedError('Unsupported QRVault protocol version: ${uri.version}');
        }

        print("Decrypting payload");
        print("Version: ${uri.version}");
        print("Salt: ${uri.salt}");
        print("IV: ${uri.iv}");
        print("Content: ${uri.content}");
        print("User Password: $userPassword");
        if (uri.hint != null) print("Hint: ${uri.hint}");

        final decryptionKey = await _generateArgon2idKey();
        print("Decryption key generated");
        final keyBytes = await decryptionKey.extractBytes();
        print(
            "Key Bytes (Hex): ${keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}");
        
        final decryptedMessagePack = await _decryptContent(decryptionKey);
        print("Decrypted message pack (first 10 bytes): ${decryptedMessagePack.take(10).toList()}");
        
        final payloadMap = QrURI.payloadFromMessagePack(decryptedMessagePack);
        print("Payload map from decrypted: $payloadMap");
        return QrVaultPayload.fromMap(payloadMap);

    }

}
