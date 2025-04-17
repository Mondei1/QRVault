import 'package:flutter/material.dart';
import 'package:qrvault/routes.dart';

class WelcomeStepView extends StatelessWidget {
  const WelcomeStepView({super.key});

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
                Icons.qr_code,
                size: 200,
              )),

          SizedBox(height: 50),

          // Welcome text
          Text(
            "Welcome",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          // Description text
          Text(
            "QRVault allows you to store password on the\nsafest offline medium known: Paper 📃",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
