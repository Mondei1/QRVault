import 'package:flutter/material.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/screens/onboarding/onboarding_screen.dart';
import 'package:qrvault/screens/splash/splash_screen.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => SplashScreen(),
    '/onboarding': (context) => OnboardingScreen(),
    '/home': (context) => HomeScreenView(),
    // '/settings': (context) => SettingsScreen(),
  };
  
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String settings = '/settings';
}