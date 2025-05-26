import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/services/commons.dart';
import 'package:qrvault/services/crypto_service.dart';
import 'package:qrvault/screens/main/scanned_screen.dart';
import 'package:qrvault/screens/main/loading_screen.dart';
import 'package:qrvault/services/native_calls.dart';

class UnlockScreen extends StatefulWidget {
  final QrURI qrURI;

  const UnlockScreen({super.key, required this.qrURI});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isMasterPasswordAvailable = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _checkMasterPasswordAvailability();
    super.initState();
  }

  Future<void> _checkMasterPasswordAvailability() async {
    bool result = await NativeCalls.hasMasterKey();

    setState(() {
      _isMasterPasswordAvailable = result;
    });
  }

  Future<void> _unlockAndNavigate({bool useBiometrics = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty && !useBiometrics) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterPasswordMessage)),
      );
      return;
    }

    String decryptionPassword = _passwordController.text;

    if (useBiometrics) {
      (String, String)? result = (await NativeCalls.retrieveMasterKey());

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricError)),
          );
        }

        return;
      }

      decryptionPassword = result.$1;
    }

    var loadingView = LoadingView(
        decryption: DecryptionMode(
            payload: widget.qrURI, password: decryptionPassword));

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => loadingView));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 100),
              const SizedBox(height: 8),
              Text(
                l10n.unlockScreenTitle(widget.qrURI.title),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.qrURI.hint != null && widget.qrURI.hint!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    l10n.passwordHintText(widget.qrURI.hint!),
                    style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.lock_open, color: colorScheme.onPrimary),
                label: Text(l10n.unlockButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onPrimary),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _unlockAndNavigate,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
          visible: _isMasterPasswordAvailable,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
              top: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: Divider(endIndent: 10)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child:
                          Text(l10n.orDividerText, style: textTheme.labelSmall),
                    ),
                    const Expanded(child: Divider(indent: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: textTheme.titleMedium,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(l10n.useBiometricsButton),
                  onPressed: () {
                    _unlockAndNavigate(useBiometrics: true);
                  },
                ),
              ],
            ),
          )),
    );
  }
}
