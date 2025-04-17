import 'package:flutter/material.dart';

class WelcomeStepView extends StatelessWidget {
  const WelcomeStepView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        spacing: 32,
        children: [
          Padding(
              padding: EdgeInsets.only(top: 128),
              child: Icon(
                Icons.forum,
                color: Theme.of(context).colorScheme.onSurface,
                size: 142,
              ),
            ),
        ],
      ),
    );
  }
}