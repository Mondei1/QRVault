import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';

class SecurityStepView extends StatelessWidget {
  const SecurityStepView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 100),

          // QR code icon
          SizedBox(
              height: 200,
              width: 200,
              child: Icon(
                Icons.lock,
                size: 150,
              )),

          SizedBox(height: 50),

          // Welcome text
          Text(
            AppLocalizations.of(context)!.security,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          // Description text
          Text(
            AppLocalizations.of(context)!.securityDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),

          SizedBox(height: 20),

          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.title)),
                    Text(AppLocalizations.of(context)!.titleUnencrypted)
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.lightbulb)),
                    Text(AppLocalizations.of(context)!.passwordHintUnencrypted)
                  ],
                )
              ],
            ),
          ),

          Spacer(),

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
                            AppLocalizations.of(context)!.encryptionInfo))
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
