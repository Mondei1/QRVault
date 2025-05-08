import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';
import 'package:qrvault/screens/main/password_generator_screen.dart';

class CreateScreenView extends StatefulWidget {
  const CreateScreenView({super.key});

  @override
  State<CreateScreenView> createState() => _CreateScreenView();
}

class _CreateScreenView extends State<CreateScreenView> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
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
            Navigator.pushNamed(context, AppRoutes.home);
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: l10n.emailFieldHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _emailController.clear(),
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
                            final String? generatedPassword = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()),
                            );
                            if (generatedPassword != null && generatedPassword.isNotEmpty) {
                            setState(() {
                              _passwordController.text = generatedPassword;
                            });
                            }
                          }
                        ),
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
            top: 8.0),
        child: ElevatedButton.icon(
          icon: Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.onPrimary),
          label: Text(l10n.generateButtonLabel),
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
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.password);
          },
        ),
      ),
    );
  }
}
