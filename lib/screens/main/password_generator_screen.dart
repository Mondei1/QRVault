import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final _passwordController = TextEditingController();
  double _currentSliderValue = 12;
  final double _minPasswordLength = 8;

  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  final Random _random = Random();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    final length = _currentSliderValue.toInt();
    final uppercase = _includeUppercase ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' : '';
    final lowercase = _includeLowercase ? 'abcdefghijklmnopqrstuvwxyz' : '';
    final numbers = _includeNumbers ? '0123456789' : '';
    final symbols = _includeSymbols ? '!@#\$%^&*()_+-=[]{}|;:,.<>?' : '';

    final allChars = '$uppercase$lowercase$numbers$symbols';

    if(allChars.isEmpty) {
      return AppLocalizations.of(context)?.errorNoCharTypesSelected;
    }

    return List.generate(length, (_) => allChars[_random.nextInt(allChars.length)])
    .join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    _passwordController.text = _generatePassword();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.generator),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.password,
                style: textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.length, 
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _currentSliderValue,
                min: _minPasswordLength,
                max: _maxPasswordLength,
                divisions: (_maxPasswordLength - _minPasswordLength).toInt(),
                label: _currentSliderValue.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _currentSliderValue = value;
                    _passwordController.text = _generatePassword();
                  });
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _currentSliderValue.round().toString(),
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24), 
              Text(
                AppLocalizations.of(context)!.include, 
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.uppercaseLetters, 
                            style: textTheme.bodyLarge),
                          Switch(
                            value: _includeUppercase,
                            onChanged: (bool value) {
                              setState(() {
                                _includeUppercase = value;
                                _passwordController.text = _generatePassword();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.lowercaseLetters,
                            style: textTheme.bodyLarge),
                          Switch(
                            value: _includeLowercase,
                            onChanged: (bool value) {
                              setState(() {
                                _includeLowercase = value;
                                _passwordController.text = _generatePassword();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.numbers,
                            style: textTheme.bodyLarge),
                          Switch(
                            value: _includeNumbers,
                            onChanged: (bool value) {
                              setState(() {
                                _includeNumbers = value;
                                _passwordController.text = _generatePassword();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.symbols,
                            style: textTheme.bodyLarge),
                          Switch(
                            value: _includeSymbols,
                            onChanged: (bool value) {
                              setState(() {
                                _includeSymbols = value;
                                _passwordController.text = _generatePassword();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
        child: ElevatedButton.icon(
          icon: Icon(Icons.password, color: colorScheme.onPrimary),
          label: Text(AppLocalizations.of(context)!.useThis),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
             //TODO: Implement "Use this" action
          },
        ),
      ),
    );
  }
}
