import 'package:flutter/material.dart';
import 'package:qrvault/routes.dart';
//TODO: Implement localization


class SetPasswordView extends StatefulWidget {
  const SetPasswordView({super.key});

  @override
  State<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<SetPasswordView> {
  final _passwordController = TextEditingController();
  final _hintController = TextEditingController();
  final bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Password'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.create)
        ),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Set password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Set the encryption password manually to protect this QR code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.casino_outlined), // mimicking dice icon
                    onPressed: () {
                      // TODO: Add password generator
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'QRVault does not enforce password requirements – it is your responsibility.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.purple),
              ),
              const SizedBox(height: 20),
              Divider(indent: 20, endIndent: 20),
              const SizedBox(height: 20),
              TextField(
                controller: _hintController,
                decoration: InputDecoration(
                  labelText: 'Hint',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _hintController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Stored unencrypted!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          icon: Icon(Icons.password, color: Theme.of(context).colorScheme.onPrimary),
          label: const Text('Use password'),
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
            //TODO: Implement onPressedGenerate
          },
        ),
      ),
    );
  }
}
