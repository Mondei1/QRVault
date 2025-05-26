import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';
import 'package:qrvault/screens/main/scanned_screen.dart';
import 'package:qrvault/services/commons.dart';
import 'package:qrvault/services/crypto_service.dart';
import 'package:qrvault/services/qrcode_generator.dart';

class EncryptionMode {
  final QrVaultPayload? payload;
  final QrVaultEncryptionModel header;

  EncryptionMode({required this.payload, required this.header});
}

class DecryptionMode {
  final QrURI? payload;
  final String password;

  DecryptionMode({required this.payload, required this.password});
}

class LoadingView extends StatefulWidget {
  final EncryptionMode? encryption;
  final DecryptionMode? decryption;

  const LoadingView({super.key, this.decryption, this.encryption});

  @override
  State<StatefulWidget> createState() => _LoadingView();
}

class _LoadingView extends State<LoadingView> {

  @override
  void initState() {
    super.initState();

    if (widget.decryption != null && widget.encryption != null) {
      throw Exception("You cannot set both encryption and decryption details.");
    }

    if (widget.decryption != null) {
      decrypt();
    } else if (widget.encryption != null) {
      encrypt();
    } else {
      throw Exception("You cannot call the loading view without setting encryption nor decryption details.");
    }
  }

  void encrypt() async {
    final cryptoService = CryptoService();

    try {
      final QrURI generatedQrUri = await cryptoService.generateQrUri(
        payload: widget.encryption!.payload!,
        title: widget.encryption!.header.title,
        masterPassword: widget.encryption!.header.password,
        hint: widget.encryption!.header.hint,
      );
      
      await QrCodeGenerator.printQrCode(context, generatedQrUri.title, generatedQrUri.toUriString(), hint: generatedQrUri.hint);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      log("Error generating QR URI in SetPasswordView: $e");

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating QR URI: $e"),
          backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  void decrypt() async {
    try {
      final decryptionService = CryptoService.forDecryption(
        uri: widget.decryption!.payload,
        userPassword: widget.decryption!.password
      );

      final QrVaultPayload decryptedPayload =
          await decryptionService.getDecryptedPayload();

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedScreen(
            payload: decryptedPayload,
            title: widget.decryption!.payload!.title,
          ),
        ),
      );

      // if (mounted) {
      //   Navigator.pushNamedAndRemoveUntil(
      //     context,
      //     AppRoutes.home,
      //     (route) => false,
      //   );
      // }
    } catch (e) {
      log("Decryption error: $e");
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.decryptionFailedMessage),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)!.holdUp,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                widget.encryption != null
                  ? AppLocalizations.of(context)!.loadingEncryption
                  : AppLocalizations.of(context)!.loadingDecryption,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
