import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrvault/screens/main/unlock_screen.dart';
import 'package:qrvault/services/commons.dart';

class HomeScreenView extends StatefulWidget {
  final VoidCallback? onScreenCreated;

  const HomeScreenView({super.key, this.onScreenCreated});

  @override
  State<HomeScreenView> createState() => HomeScreenViewState();
}

class HomeScreenViewState extends State<HomeScreenView> {
  final MobileScannerController mobilescannercontroller = MobileScannerController(detectionTimeoutMs: 1000, autoZoom: false);
  

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
      if (!scanning) {
        mobilescannercontroller.stop();
      } else {
        mobilescannercontroller.start();
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
          if(e.toString().contains('Invalid URI scheme')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.invalidUri),
                backgroundColor: Colors.red,                )
              );
            }
          }
          log(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              controlScanner(scanning: false);
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
                  controller: mobilescannercontroller,
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
          controlScanner(scanning: false);
           Navigator.pushNamed(context, AppRoutes.create);
          },
          icon: const Icon(Icons.add_circle_outline),
          label: Text(AppLocalizations.of(context)!.create),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
    );
  }
}
