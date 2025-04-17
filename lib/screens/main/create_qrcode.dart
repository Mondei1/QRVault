import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:qrvault/routes.dart';


class CreateScreenView extends StatefulWidget {
  const CreateScreenView({super.key});

  @override
  State<CreateScreenView> createState() => _CreateScreenView();
}

class _CreateScreenView extends State<CreateScreenView> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          'Create QR-Code',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            //TODO: Implement onPressedSettings
          },
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
                padding: EdgeInsets.all(2),
            ),
          ),
        ],
      ),
      
    );
  }
}
