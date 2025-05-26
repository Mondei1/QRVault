import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrvault/screens/main/unlock_screen.dart';
import 'package:qrvault/services/commons.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeScreenView extends StatefulWidget {
  final VoidCallback? onScreenCreated;

  const HomeScreenView({super.key, this.onScreenCreated});

  @override
  State<HomeScreenView> createState() => HomeScreenViewState();
}

class HomeScreenViewState extends State<HomeScreenView> {
  final MobileScannerController mobileScannerController =
      MobileScannerController(detectionTimeoutMs: 1000, autoZoom: false);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onScreenCreated?.call();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void controlScanner({required bool scanning}) {
    if (mounted) {
      try {
        if (!scanning) {
          mobileScannerController.stop();
        } else {
          mobileScannerController.start();
        }
      } on MobileScannerException catch (e) {
        // If the scanner is not ready yet, wait for a short amount of time and try again.
        // This could lead to an endless loop... ¯\_(ツ)_/¯
        Future.delayed(Durations.medium1, () => {
          controlScanner(scanning: scanning)
        });
      }
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      final barcode = barcodes.barcodes.firstOrNull;
      if (barcode?.displayValue != null && barcode!.displayValue!.isNotEmpty) {
        try {
          controlScanner(scanning: false);
          QrURI qrURI = QrURI.fromUriString(barcode.displayValue!);
          Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => UnlockScreen(qrURI: qrURI)),
          );
        } catch (e) {
          if (e.toString().contains('Invalid URI scheme')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!.invalidUri),
                backgroundColor: Colors.red,
              ));
            }
          }
          log(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key("home-screen"),
        // Ladies and gentlemen, this fu**ing change took 2,5h to troubleshoot.
        // Finally, we can stop and resume the camera properly on navigation. The router
        // didn't work for unforeseen reasons.
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0) {
            print("Widget is visible");
            controlScanner(scanning: true);
          } else {
            print("Widget is not visible");
            controlScanner(scanning: false);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            title: Text(
              AppLocalizations.of(context)!.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.language);
                },
              ),
            ],
            elevation: 1,
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    MobileScanner(
                        controller: mobileScannerController,
                        onDetect: _handleBarcode),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.create);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: Text(AppLocalizations.of(context)!.create),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ));
  }
}
