import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that updates the status bar appearance based on the current theme.
class ThemeAwareStatusBar extends StatefulWidget {
  final Widget child;

  const ThemeAwareStatusBar({
    super.key,
    required this.child,
  });

  @override
  State<ThemeAwareStatusBar> createState() => _ThemeAwareStatusBarState();
}

class _ThemeAwareStatusBarState extends State<ThemeAwareStatusBar> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatusBarAppearance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _updateStatusBarAppearance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBarAppearance();
  }

  void _updateStatusBarAppearance() {
    // Only proceed if context is mounted and available
    if (!mounted) return;
    
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // On Android, statusBarIconBrightness controls the status bar icon color
    // On iOS, statusBarBrightness controls the status bar style
    // For dark theme: we want light icons on Android and dark status bar on iOS
    // For light theme: we want dark icons on Android and light status bar on iOS
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // We don't need to call _updateStatusBarAppearance() here
    // as it's already called in didChangeDependencies and didChangePlatformBrightness
    return widget.child;
  }
}
