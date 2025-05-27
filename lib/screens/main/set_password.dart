import 'package:flutter/material.dart';
import 'package:qrvault/screens/main/password_generator_screen.dart';
import 'package:qrvault/screens/main/loading_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/services/commons.dart';

class SetPasswordView extends StatefulWidget {
  final QrVaultPayload payload;
  final String title;

  const SetPasswordView(
      {super.key, required this.payload, required this.title});

  @override
  State<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<SetPasswordView> {
  final _passwordController = TextEditingController();
  final _hintController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(l10n.setPasswordAppBarTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.setPasswordHeadline,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.setPasswordDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.passwordFieldLabel,
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
                                  await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PasswordGeneratorScreen()),
                              );
                              if (generatedPassword != null &&
                                  generatedPassword.isNotEmpty) {
                                setState(() {
                                  _passwordController.text = generatedPassword;
                                });
                              }
                            }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.passwordRequirements,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              const Divider(indent: 20, endIndent: 20),
              const SizedBox(height: 20),
              TextField(
                controller: _hintController,
                decoration: InputDecoration(
                  labelText: l10n.hintFieldLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _hintController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.passwordHint,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 16.0,
          top: 8.0,
        ),
        child: ElevatedButton.icon(
          icon: Icon(Icons.password,
              color: Theme.of(context).colorScheme.onPrimary),
          label: Text(l10n.usePasswordButton),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () async {
            final String masterPassword = _passwordController.text;
            final String? hint =
                _hintController.text.isNotEmpty ? _hintController.text : null;

            if (masterPassword.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password cannot be empty'),
                      backgroundColor: Colors.red),
                );
              }
              return;
            }

            //Create a new loading view with encryption mode
            var loadingView = LoadingView(
              encryption: EncryptionMode(
                payload: widget.payload,
                header: QrVaultEncryptionModel(
                    version: QrVaultEncryptionModel.currentVersion,
                    password: masterPassword,
                    hint: hint,
                    title: widget.title),
              ),
            );

            //Navigate to the loading view
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => loadingView),
            );
          },
        ),
      ),
    );
  }
}
