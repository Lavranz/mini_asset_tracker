// lib/barcode_service.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeService {
  static Future<String?> scanBarcode(BuildContext context) async {
    // Step 1: Check camera permission
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted) {
      return null; // Exit if camera not allowed
    }

    // Step 2: Open scanner page
    String? result;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scan Barcode/QR Code")),
          body: MobileScanner(
            onDetect: (barcodeCapture) {
              final Barcode barcode = barcodeCapture.barcodes.first;
              result = barcode.rawValue;
              Navigator.of(context)
                  .pop(result); // close scanner and return value
            },
          ),
        ),
      ),
    );

    // Step 3: Return scanned value
    return result;
  }
}
