import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'barcode_service.dart'; // import your scanner service

// Data model
class Device {
  final String serialNumber;
  final String productName;

  Device({required this.serialNumber, required this.productName});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      serialNumber: json['serialNumber'] ?? '',
      productName: json['productName'] ?? '',
    );
  }

  @override
  String toString() => "$serialNumber - $productName";
}

// Searchable Dropdown widget
class DeviceDropdown extends StatefulWidget {
  final Function(Device?) onSelected;

  const DeviceDropdown({super.key, required this.onSelected});

  @override
  State<DeviceDropdown> createState() => _DeviceDropdownState();
}

class _DeviceDropdownState extends State<DeviceDropdown> {
  Future<List<Device>> _fetchDevices([String? query]) async {
    try {
      final url = (query == null || query.isEmpty)
          ? "http://202.60.10.144:7500/api/astra/get/devices"
          : "http://202.60.10.144:7500/api/astra/get/devices?query=$query";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['devices'] ?? [];
        return data.map((e) => Device.fromJson(e)).toList();
      } else {
        debugPrint("API error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Device>(
      asyncItems: (String? filter) => _fetchDevices(filter),
      itemAsString: (Device d) => d.toString(),
      onChanged: (Device? selected) async {
        if (selected == null) return;

        // Step 1: Launch scanner
        final scannedValue = await BarcodeService.scanBarcode(context);

        // Step 2: Handle no scan or denied permission
        if (scannedValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("No barcode scanned or permission denied")),
          );
          return;
        }

        // Step 3: Normalize and split scanned string
        final normalizedScan = scannedValue.trim();
        final parts = normalizedScan
            .split(RegExp(r'[,\s]+')); // split by comma or whitespace

        // Step 4: Verify match
        if (parts.contains(selected.serialNumber)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Verified: ${selected.serialNumber}")),
          );
          widget.onSelected(selected);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ Mismatch! Expected ${selected.serialNumber}, got $scannedValue",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Search & Select Device",
          border: OutlineInputBorder(),
        ),
      ),
      popupProps: const PopupProps.menu(
        showSearchBox: true, // ✅ keeps the search box inside dropdown
      ),
    );
  }
}
