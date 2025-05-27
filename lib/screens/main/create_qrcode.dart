import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/screens/main/loading_screen.dart';
import 'package:qrvault/screens/main/password_generator_screen.dart';
import 'package:qrvault/services/commons.dart';
import 'package:qrvault/screens/main/set_password.dart';
import 'package:qrvault/routes.dart';
import 'package:qrvault/services/native_calls.dart';

///Screen for creating a new QR code
class CreateScreenView extends StatefulWidget {
  const CreateScreenView({super.key});

  @override
  State<CreateScreenView> createState() => _CreateScreenView();
}

class _CreateScreenView extends State<CreateScreenView> {
  final _formKey = GlobalKey<FormState>();

  bool _isMasterPasswordAvailable = false;

  //Controllers for the form fields
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  final _notesController = TextEditingController();

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

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _websiteController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.providePassword),
          backgroundColor: Colors.red,
        ));

      }
      return false;
    }

    return true;
  }

  void _useManualPassword() {
    if (!_validateForm()) {
      return;
    }

    //Create a new QR code payload based on the form fields
    final payload = QrVaultPayload(
      username: _usernameController.text,
      password: _passwordController.text,
      website: _websiteController.text,
      totpSecret: _totpController.text,
      notes: _notesController.text,
    );

    //Navigate to the set password screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetPasswordView(
          payload: payload,
          title: _titleController.text,
        ),
      ),
    );
  }

  void _useBiometric() async {
    if (!_isMasterPasswordAvailable || !_validateForm()) {
      return;
    }

    (String, String)? masterKeyWithHint = await NativeCalls.retrieveMasterKey();
    
    if (masterKeyWithHint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.biometricError),
          backgroundColor: Colors.red,
        ));
      }

      return;
    }

    //Create a new QR code payload based on the form fields
    final payload = QrVaultPayload(
      username: _usernameController.text,
      password: _passwordController.text,
      website: _websiteController.text,
      totpSecret: _totpController.text,
      notes: _notesController.text,
    );

    var loadingView = LoadingView(
      encryption: EncryptionMode(
        payload: payload,
        header: QrVaultEncryptionModel(
            version: QrVaultEncryptionModel.currentVersion,
            password: masterKeyWithHint.$1,
            hint: masterKeyWithHint.$2,
            title: _titleController.text),
      ),
    );

    //Navigate to the loading screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => loadingView),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          l10n.createQrCodeAppBarTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            }
          },
        ),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                //Form fields
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.titleFieldLabel,
                    hintText: l10n.titleFieldHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _titleController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.titleFieldDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.usernameLabel,
                    hintText: l10n.usernameFieldHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _usernameController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: "Website",
                    hintText: "Enter website URL",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _websiteController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.passwordFieldLabel,
                    hintText: l10n.passwordFieldHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: l10n.generatePasswordTooltip,
                          child: IconButton(
                              icon: const Icon(Icons.casino),
                              onPressed: () async {
                                final String? generatedPassword =
                                //await because the password generator screen will return a string when popped
                                    await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PasswordGeneratorScreen()),
                                );
                                if (generatedPassword != null &&
                                    generatedPassword.isNotEmpty) {
                                  setState(() {
                                    _passwordController.text =
                                        generatedPassword;
                                  });
                                }
                              }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _totpController,
                  decoration: InputDecoration(
                    labelText: l10n.totpSecretFieldLabel,
                    hintText: l10n.totpSecretFieldHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () {
                        // TODO: Implement Scan TOTP secret
                        log('Scan TOTP pressed');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.notesFieldLabel,
                    hintText: l10n.notesFieldHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // This is where the two buttons for the encryption scheme are located.
      bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
              top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0,
            children: [
              // This button is basically the same as the most bottom one, except its
              // outlined and has a different text.
              if (!_isMasterPasswordAvailable)
                ElevatedButton.icon(
                  icon: Icon(Icons.qr_code_scanner,
                      color: Theme.of(context).colorScheme.onPrimary),
                  label: Text(l10n.generateButtonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _useManualPassword,
                ),
              
              // Show the button to use biometric if available.
              if (_isMasterPasswordAvailable)
                ElevatedButton.icon(
                  icon: Icon(Icons.fingerprint,
                      color: Theme.of(context).colorScheme.onPrimary),
                  label: Text(l10n.generateBiometricButtonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _useBiometric,
                ),
              
              // Same button as the top most (see explanation above)
              if (_isMasterPasswordAvailable)
                OutlinedButton.icon(
                  icon: Icon(Icons.password,
                      color: Theme.of(context).colorScheme.primary),
                  label: Text(l10n.generateManualButtonLabel,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _useManualPassword,
                ),
            ],
          )),
    );
  }
}
