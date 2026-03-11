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
  final List<Device> _verifiedDevices = [];

  Future<List<Device>> _fetchDevices([String? query]) async {
    try {
      final url = (query == null || query.isEmpty)
          ? "http://202.60.10.144:7500/api/astra/get/devices"
          : "http://202.60.10.144:7500/api/astra/get/devices?query=$query";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['devices'] ?? [];
        final devices = data.map((e) => Device.fromJson(e)).toList();

        // Exclude already verified devices
        return devices
            .where((d) =>
                !_verifiedDevices.any((v) => v.serialNumber == d.serialNumber))
            .toList();
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownSearch<Device>(
            asyncItems: (String? filter) => _fetchDevices(filter),
            itemAsString: (Device d) => d.toString(),
            onChanged: (Device? selected) async {
              if (selected == null) return;

              final scannedValue = await BarcodeService.scanBarcode(context);

              if (scannedValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("No barcode scanned or permission denied")),
                );
                return;
              }

              final normalizedScan = scannedValue.trim();
              final parts = normalizedScan.split(RegExp(r'[,\s]+'));

              if (parts.contains(selected.serialNumber)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("✅ Verified: ${selected.serialNumber}")),
                );

                setState(() {
                  _verifiedDevices.add(selected);
                });

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
              showSearchBox: true,
            ),
          ),

          const SizedBox(height: 20),

          if (_verifiedDevices.isNotEmpty)
            const Text(
              "Verified Devices:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

          // ✅ Shrink-wrapped list inside scroll view
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _verifiedDevices.length,
            itemBuilder: (context, index) {
              final device = _verifiedDevices[index];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(device.productName),
                subtitle: Text("SN: ${device.serialNumber}"),
              );
            },
          ),
        ],
      ),
    );
  }
}
