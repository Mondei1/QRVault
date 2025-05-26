import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:qrvault/config/language_service.dart';
import 'package:qrvault/config/shared_preferences_helper.dart';
import 'package:qrvault/routes.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/theme/theme_aware_status_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesHelper.init();

  // Set up the status bar to be transparent and adapt to theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Define a default brand color
    const Color fallbackColor = Colors.deepPurple;

    // Create default ColorSchemes
    final ColorScheme defaultLightColorScheme = ColorScheme.fromSeed(
        seedColor: fallbackColor, brightness: Brightness.light);
    final ColorScheme defaultDarkColorScheme = ColorScheme.fromSeed(
        seedColor: fallbackColor, brightness: Brightness.dark);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Use dynamic color scheme if available, otherwise use default
        ColorScheme lightColorScheme = lightDynamic ?? defaultLightColorScheme;
        ColorScheme darkColorScheme = darkDynamic ?? defaultDarkColorScheme;

        // Get the app-specific locale if available
        return FutureBuilder<Locale?>(
            future: LanguageService.getAppLocale(),
            builder: (context, snapshot) {
              // Default to null (system locale) if not available
              final appLocale = snapshot.data;

              return ThemeAwareStatusBar(
                child: MaterialApp(
                  title: 'QRVault',
                  debugShowCheckedModeBanner: false,
                  routes: AppRoutes.routes,

                  // Localization setup
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,

                  // Use app-specific locale if available, otherwise use device locale
                  locale: appLocale,

                  theme: ThemeData(
                    colorScheme: lightColorScheme,
                    useMaterial3: true,
                    appBarTheme: AppBarTheme(
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark,
                        statusBarBrightness: Brightness.light,
                      ),
                    ),
                  ),
                  darkTheme: ThemeData(
                    colorScheme: darkColorScheme,
                    useMaterial3: true,
                    appBarTheme: AppBarTheme(
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.dark,
                      ),
                    ),
                  ),
                  // Use system theme mode
                  themeMode: ThemeMode.system,
                ),
              );
            });
      },
    );
  }
}
