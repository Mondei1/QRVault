import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/config/shared_preferences_helper.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/screens/main/password_generator_screen.dart';
import 'package:qrvault/services/native_calls.dart';

class MasterPasswordSetupView extends StatefulWidget {
  const MasterPasswordSetupView({super.key});

  @override
  State<MasterPasswordSetupView> createState() => _MasterPasswordSetupViewState();
}

class _MasterPasswordSetupViewState extends State<MasterPasswordSetupView> {
  final _passwordController = TextEditingController();
  final _hintController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  /// This will enroll a master key on the Android device.
  void enrollMasterPassword() async {
    var enrollResult = await NativeCalls.enrollMasterKey(_passwordController.text, _hintController.text);

    if (!enrollResult && mounted) {
      _showMasterPasswordError(context);
      return;
    }

    // Navigate the user to the home screen since this is the last optional step.
    await SharedPreferencesHelper.setFirstRunComplete();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => HomeScreenView()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Setup'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.masterpassword,
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.biometricsInfo,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.masterpassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      Tooltip(
                        message: AppLocalizations.of(context)!.generatePasswordTooltip,
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
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.passwordRequirements,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(height: 20),
              const Divider(indent: 20, endIndent: 20),
              const SizedBox(height: 20),
              TextField(
                controller: _hintController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.passwordHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _hintController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.storedUnencrypted,
                  style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                color: Theme.of(context).colorScheme.secondary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.info),
                    ),
                    Flexible(
                        child: Text(
                            AppLocalizations.of(context)!.reinstallationInfo))
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16.0,
          top: 8.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.fingerprint, color: colorScheme.onPrimary),
              label: Text(AppLocalizations.of(context)!.useBiometrics),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => enrollMasterPassword(),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showMasterPasswordError(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text(
            // TODO: Translate
            "There was an error setting your master password. Try again or continue without one.",
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text("Try again"),
              onPressed: () {
                // Close dialogue
                Navigator.of(context, rootNavigator: true).pop(null);
                enrollMasterPassword();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text("Skip"),
              onPressed: () {
                // Navigate the user to the home screen since this is the last optional step.
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => HomeScreenView()));
              },
            ),
          ],
        );
      },
    );
  }
}
