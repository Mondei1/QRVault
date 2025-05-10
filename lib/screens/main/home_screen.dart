import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrvault/screens/main/unlock_screen.dart';
import 'package:qrvault/services/commons.dart';

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({super.key});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      print("handle barcode");
      final barcode = barcodes.barcodes.firstOrNull;
      print("barcode: ${barcode?.displayValue}");
      if (barcode?.displayValue != null && barcode!.displayValue!.isNotEmpty) {
        try {
          QrURI qrURI = QrURI.fromUriString(barcode.displayValue!);
          print(qrURI.toUriString());
          Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => UnlockScreen(qrURI: qrURI)),
          );
        } catch (e) {
          print(e.toString());
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
                MobileScanner(onDetect: _handleBarcode),
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
    );
  }
}
