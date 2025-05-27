import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/config/language_service.dart';
import 'package:qrvault/routes.dart';

///Screen for the language settings
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  Locale? _selectedLocale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocale();
  }

  Future<void> _loadCurrentLocale() async {
    final locale = await LanguageService.getAppLocale();
    setState(() {
      _selectedLocale = locale;
      _isLoading = false;
    });
  }

  Future<void> _setLocale(Locale? locale) async {
    setState(() {
      _isLoading = true;
    });

    if (locale != null) {
      await LanguageService.setAppLocale(locale);
    }

    setState(() {
      _selectedLocale = locale;
      _isLoading = false;
    });

    // Show a snackbar to inform the user to restart the app
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.languageChanged,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.systemDefault),
                  subtitle: Text(AppLocalizations.of(context)!.useSystemLanguage),
                  leading: const Icon(Icons.language),
                  trailing: _selectedLocale == null
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => _setLocale(null),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.englishLanguage),
                  subtitle: Text('English'),
                  leading: const Icon(Icons.language),
                  trailing: _selectedLocale?.languageCode == 'en'
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => _setLocale(const Locale('en')),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.deutschLanguage),
                  subtitle: Text(AppLocalizations.of(context)!.germanLanguage),
                  leading: const Icon(Icons.language),
                  trailing: _selectedLocale?.languageCode == 'de'
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => _setLocale(const Locale('de')),
                ),
              ],
            ),
    );
  }
}
