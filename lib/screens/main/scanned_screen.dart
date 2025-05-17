import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:totp/totp.dart';
import 'package:qrvault/services/commons.dart';
import 'package:qrvault/routes.dart';

class ScannedScreen extends StatefulWidget {
  final QrVaultPayload payload;
  final String title;

  const ScannedScreen({super.key, required this.payload, required this.title});

  @override
  State<ScannedScreen> createState() => _ScannedScreenState();
}

class _ScannedScreenState extends State<ScannedScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late final Totp _totpGenerator;
  String _currentOtp = "";
  String _previousOtp = "";
  String _nextOtp = "";
  double _otpProgress = 1.0;
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();  
    if (widget.payload.username != null) {
      _usernameController.text = widget.payload.username!;
    }
    if (widget.payload.website != null) {
      _emailController.text = widget.payload.website!;
    }
    if (widget.payload.password != null) {
      _passwordController.text = widget.payload.password!;
    }

    if (widget.payload.totpSecret != null && widget.payload.totpSecret!.isNotEmpty) {
      try {
        _totpGenerator = Totp(
          algorithm: Algorithm.sha1,
          secret: widget.payload.totpSecret!.codeUnits,
          digits: 6,
          period: 30,
        );
        _updateCodesAndProgress(); 
        _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateCodesAndProgress();
        });
      } catch (e) {
        developer.log("Error initializing TOTP: $e");
      }
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return "${code.substring(0, 3)} ${code.substring(3, 6)}";
    }
    return code;
  }

  void _updateCodesAndProgress() {
    if (!mounted || widget.payload.totpSecret == null || widget.payload.totpSecret!.isEmpty ) return;

    final now = DateTime.now();
    final current = _totpGenerator.generate(now);
    final prevTime = now.subtract(Duration(seconds: _totpGenerator.period));
    final prev = _totpGenerator.generate(prevTime);
    final nextTime = now.add(Duration(seconds: _totpGenerator.period));
    final next = _totpGenerator.generate(nextTime);

    final secondsIntoPeriod = (now.millisecondsSinceEpoch ~/ 1000) % _totpGenerator.period;
    final secondsRemaining = _totpGenerator.period - secondsIntoPeriod;
    final progress = secondsRemaining.toDouble() / _totpGenerator.period.toDouble();

    final clampedProgress = progress.clamp(0.0, 1.0);

    setState(() {
      _currentOtp = _formatCode(current);
      _previousOtp = _formatCode(prev);
      _nextOtp = _formatCode(next);
      _otpProgress = clampedProgress;
    });
  }

  void _copyToClipboard(String text, String fieldNameL10n) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
    appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             Navigator.pop(context);
          },
        ),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _usernameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.usernameLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.copyUsernameTooltip,
                    onPressed: () => _copyToClipboard(_usernameController.text, l10n.usernameLabel),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.copyEmailTooltip,
                    onPressed: () => _copyToClipboard(_emailController.text, l10n.emailLabel),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: l10n.copyPasswordTooltip,
                        onPressed: () => _copyToClipboard(_passwordController.text, l10n.password),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.payload.totpSecret != null && widget.payload.totpSecret!.isNotEmpty && _currentOtp.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.tfaTotpLabel, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${l10n.previousOtpLabelPrefix} $_previousOtp",
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _currentOtp,
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${l10n.nextOtpLabelPrefix} $_nextOtp",
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _otpProgress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),   
            ],
          ),
        ),
      ),
      bottomNavigationBar:Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16.0,
          top: 8.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.outline),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: textTheme.titleMedium,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(AppLocalizations.of(context)!.home),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
