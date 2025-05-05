import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OfflineStorageStepView extends StatelessWidget {
  const OfflineStorageStepView({super.key});

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
              child: Image(
                image: AssetImage("assets/printer.png"),
                height: 200,
                width: 200,
              )),

          SizedBox(height: 50),

          // Welcome text
          Text(
            AppLocalizations.of(context)!.offlineStorage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          // Description text
          Text(
            AppLocalizations.of(context)!.offlineStorageDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),

          Spacer(),

          // // Continue button
          // Padding(
          //   padding: EdgeInsets.only(bottom: 32),
          //   child: FilledButton(
          //     onPressed: () {
          //       Navigator.pushNamed(context, AppRoutes.home);
          //     },
          //     style: FilledButton.styleFrom(
          //       backgroundColor: Theme.of(context).colorScheme.onSurface,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(30),
          //       ),
          //       minimumSize: const Size(double.infinity, 56),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           "Continue",
          //           style: TextStyle(
          //             fontSize: 16,
          //             color: Theme.of(context).colorScheme.surface,
          //           ),
          //         ),
          //         SizedBox(width: 8),
          //         Icon(
          //           Icons.arrow_forward,
          //           size: 18,
          //           color: Theme.of(context).colorScheme.surface,
          //         ),
          //       ],
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}
