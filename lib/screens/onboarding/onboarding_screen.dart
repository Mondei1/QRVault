import 'package:flutter/material.dart';
import 'package:qrvault/config/shared_preferences_helper.dart';
import 'package:qrvault/routes.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/screens/onboarding/steps/welcome_step.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Widget> _steps = [
    WelcomeStepView(),
    // UserInfoStep(),
    // PreferencesStep(),
    // CompletionStep()
  ];
  
  void _completeOnboarding() async {
    await SharedPreferencesHelper.setFirstRunComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreenView())
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [              
              const SizedBox(height: 100),
              
              // Lock icon with corners
              SizedBox(
                height: 200,
                width: 200,
                child: Icon(Icons.qr_code, size: 200,)
              ),
              
              const SizedBox(height: 50),
              
              // Welcome text
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Description text
              const Text(
                "QRVault allows you to store password on the\nsafest offline medium known: Paper 📃",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              
              const Spacer(),
              
              // Continue button
              FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.home);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
