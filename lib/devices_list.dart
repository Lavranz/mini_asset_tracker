import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          serialNumber == other.serialNumber &&
          productName == other.productName;

  @override
  int get hashCode => serialNumber.hashCode ^ productName.hashCode;
}

// Dropdown widget
class DeviceDropdown extends StatefulWidget {
  final Function(Device?) onSelected;

  const DeviceDropdown({super.key, required this.onSelected});

  @override
  State<DeviceDropdown> createState() => _DeviceDropdownState();
}

class _DeviceDropdownState extends State<DeviceDropdown> {
  List<Device> _devices = [];
  Device? _selectedDevice;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDevices(); // load all devices initially
  }

  Future<void> _fetchDevices() async {
    try {
      const url = "http://202.60.10.144:7500/api/astra/get/devices";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['devices'] ?? [];

        setState(() {
          _devices = data.map((e) => Device.fromJson(e)).toList();
        });

        debugPrint("Available Devices from API: $_devices");
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
    }
  }

  Future<void> _searchDevices() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final url =
          "http://202.60.10.144:7500/api/astra/get/devices?query=$query";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['devices'] ?? [];

        setState(() {
          _devices = data.map((e) => Device.fromJson(e)).toList();
          if (_selectedDevice != null && !_devices.contains(_selectedDevice)) {
            _selectedDevice = null;
          }
        });

        debugPrint("Search results: $_devices");
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error searching devices: $e");
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _fetchDevices(); // reload all devices
    setState(() {
      _selectedDevice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: "Search by Serial or Product",
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.deepPurple),
              onPressed: _searchDevices, // ✅ server-side search
            ),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: _clearSearch,
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButton<Device>(
          isExpanded: true,
          value: _selectedDevice,
          hint: const Text("Select Device"),
          items: _devices.isEmpty
              ? [
                  const DropdownMenuItem<Device>(
                    value: null,
                    child: Text("No devices found"),
                  )
                ]
              : _devices.map((device) {
                  return DropdownMenuItem<Device>(
                    value: device,
                    child:
                        Text("${device.serialNumber} - ${device.productName}"),
                  );
                }).toList(),
          onChanged: (Device? newValue) {
            setState(() {
              _selectedDevice = newValue;
            });
            widget.onSelected(newValue);
          },
        ),
      ],
    );
  }
}
