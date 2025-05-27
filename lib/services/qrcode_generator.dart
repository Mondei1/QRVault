import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

///Class for the QR code generator and opening the QR code in the print dialog
class QrCodeGenerator {

  ///Function to generate a QR code image data
  static Future<ByteData?> generateQrImageData(String uri, {double size = 200.0}) async {
    return await QrPainter(
      data: uri,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(size);
  }

  ///Function to print a QR code
  static Future<void> printQrCode(BuildContext context, String title, String uri, {String? hint}) async {
    final l10n = AppLocalizations.of(context)!;
    final doc = pw.Document();
    
    //Generate the QR code image
    final ByteData? qrImageData = await generateQrImageData(uri, size: 500);
    if (qrImageData == null) {
      log(l10n.qrCodePrintingError);
      return;
    }
    final Uint8List qrBytes = qrImageData.buffer.asUint8List();

    //create pdf document with QR Code image, title and hint
    doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 250,
                  height: 250,
                  child: pw.Image(pw.MemoryImage(qrBytes)),
                ),
                pw.SizedBox(height: 10),
                if (hint != null && hint.isNotEmpty)
                  pw.Text(l10n.qrCodeHint(hint), style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                pw.Spacer(),
                pw.Text(l10n.qrCodeGeneratedBy, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ]
            ),
          );
        }));
    //open pdf in print dialog
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}  

