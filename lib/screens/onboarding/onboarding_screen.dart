import 'package:flutter/material.dart';
import 'package:qrvault/config/shared_preferences_helper.dart';
import 'package:qrvault/screens/main/home_screen.dart';
import 'package:qrvault/screens/onboarding/steps/biometrics_setup_step.dart';
import 'package:qrvault/screens/onboarding/steps/offline_storage_step.dart';
import 'package:qrvault/screens/onboarding/steps/security_step.dart';
import 'package:qrvault/screens/onboarding/steps/welcome_step.dart';
import 'package:qrvault/services/native_calls.dart';

//Screen for the onboarding process
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _steps = [
    WelcomeStepView(),
    OfflineStorageStepView(),
    SecurityStepView(),
    // CompletionStep()
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSecureStorage();
    });
  }

  Future<void> _checkSecureStorage() async {
    if (await NativeCalls.hasSecureStorage()) {
      // If this device supports secure storage, allow the user to set it up.
      _steps.add(BiometricsSetupStepView());
    }
  }

  void _completeOnboarding() async {
    await SharedPreferencesHelper.setFirstRunComplete();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreenView()));
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _steps,
              ),
            ),
            // Navigation dots
            if (_steps.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, top: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            // Navigation buttons
            if (_steps.length > 1)
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 20.0, left: 20.0, right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _previousPage,
                        child: Text("Zurück"),
                      )
                    else
                      const SizedBox(width: 80),
                      if (_currentPage == _steps.length - 1 && _currentPage == 3)
                      OutlinedButton(onPressed: _nextPage, child: Text("Überspringen"))
                      else
                    FilledButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage < _steps.length - 1
                          ? "Next"
                          : "Finish")
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
