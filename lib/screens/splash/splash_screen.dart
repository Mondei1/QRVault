import 'package:flutter/material.dart';
import 'package:qrvault/config/shared_preferences_helper.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/screens/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {    
    final isFirstRun = await SharedPreferencesHelper.isFirstRun();
    
    if (isFirstRun) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => OnboardingScreen())
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreenView())
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}