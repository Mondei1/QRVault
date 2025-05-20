import 'package:flutter/material.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/screens/main/create_qrcode.dart';
import 'package:qrvault/screens/main/language_settings_screen.dart';
import 'package:qrvault/screens/main/set_password.dart';
import 'package:qrvault/screens/onboarding/onboarding_screen.dart';
import 'package:qrvault/screens/splash/splash_screen.dart';
import 'package:qrvault/services/commons.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => SplashScreen(),
    '/onboarding': (context) => OnboardingScreen(),
    '/home': (context) => HomeScreenView(onScreenCreated: () {
      final state = context.findAncestorStateOfType<HomeScreenViewState>();
      state?.controlScanner(scanning: true);
    }),
    '/create': (context) => CreateScreenView(),
    '/setPassword' : (context) => SetPasswordView(
      payload: QrVaultPayload(),
      title: '',
    ),
    '/language': (context) => LanguageSettingsScreen(),
  };
  
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String language = '/language';
  static const String create = '/create';
  static const String password = '/setPassword';
}
