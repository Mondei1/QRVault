import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BiometricsSetupStepView extends StatefulWidget {
  const BiometricsSetupStepView({super.key});

  @override
  State<BiometricsSetupStepView> createState() => _BiometricsSetupStepViewState();
}

class _BiometricsSetupStepViewState extends State<BiometricsSetupStepView> {

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 100),

          SizedBox(
              height: 200,
              width: 200,
              child: Icon(
                Icons.fingerprint,
                size: 150,
              )),

          SizedBox(height: 50),

          Text(
            AppLocalizations.of(context)!.biometrics,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          Text(
            AppLocalizations.of(context)!.biometricsSupport,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),

          Spacer(),
        ],
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
              onPressed: () {
                 //TODO: Implement Use Biometrics action
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.outline),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: textTheme.titleMedium,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(AppLocalizations.of(context)!.skip),
              onPressed: () {
                 //TODO: Implement Skip action
              },
            ),
          ],
        ),
      ),
    );
  }
}
