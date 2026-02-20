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
          body: Stack(
            children: [
              // Camera feed
              MobileScanner(
                onDetect: (barcodeCapture) {
                  final Barcode barcode = barcodeCapture.barcodes.first;
                  result = barcode.rawValue;

                  // Instead of closing immediately, show result live
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Scanned: $result")),
                  );
                },
              ),
              // Overlay square
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.redAccent,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Step 3: Return last scanned value (if any)
    return result;
  }
}