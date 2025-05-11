import 'package:flutter/material.dart';
import 'package:qrvault/services/commons.dart';
import 'package:qrvault/services/decryption.dart';
import 'package:qrvault/screens/main/scanned_screen.dart';

//TODO: implment localization

class UnlockScreen extends StatefulWidget {
  final QrURI qrURI;

  const UnlockScreen({super.key, required this.qrURI});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlockAndNavigate() async {
    if (_passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final decryptionService = DecryptionService(
        uri: widget.qrURI,
        userPassword: _passwordController.text,
      );

      final QrVaultPayload decryptedPayload = await decryptionService.getDecryptedPayload();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedScreen(
            payload: decryptedPayload,
            title: widget.qrURI.title,
          ),
        ),
      );

    } catch (e) {
      print("Decryption error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Decryption failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 100),
              const SizedBox(height: 8),
              Text(
                'Unlock ${widget.qrURI.title}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _unlockAndNavigate();
                  }
                },
              ),
              const SizedBox(height: 8),
              if (widget.qrURI.hint != null && widget.qrURI.hint!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    "Hint: ${widget.qrURI.hint!}",
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: Icon(Icons.lock_open, color: colorScheme.onPrimary),
                      label: const Text('Unlock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _unlockAndNavigate,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: Divider(endIndent: 10)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR', style: textTheme.labelSmall),
                ),
                const Expanded(child: Divider(indent: 10)),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.outline),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: textTheme.titleMedium,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Use Biometrics'),
              onPressed: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Biometrics not implemented yet')),
                  );
                }
                // TODO: Implement biometrics
              },
            ),
          ],
        ),
      ),
    );
  }
}
