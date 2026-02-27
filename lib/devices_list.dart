import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DevicesList extends StatefulWidget {
  final Function(String) onSelected; // callback to send value back to parent

  const DevicesList({super.key, required this.onSelected});

  @override
  State<DevicesList> createState() => _DevicesListState();
}

class _DevicesListState extends State<DevicesList> {
  String? _selectedDevice;
  List<String> devices = [];
  List<String> filteredDevices = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _callApi(); // fetch devices once at startup
  }

  Future<void> _callApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const url = "http://202.60.10.144:7500/api/astra/get/devices"; // dummy link
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<String> fetchedDevices = [];
        if (data is Map<String, dynamic> && data.containsKey("devices")) {
          fetchedDevices = (data["devices"] as List)
              .map((item) => "${item['serialNumber']} - ${item['productName']}")
              .toList();
        } else if (data is List) {
          fetchedDevices = data
              .map((item) => "${item['serialNumber']} - ${item['productName']}")
              .toList()
              .cast<String>();
        }

        setState(() {
          devices = fetchedDevices;
          filteredDevices = List.from(fetchedDevices);
        });
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
    }

    setState(() {
      _isLoading = false;
      _selectedDevice = null;
    });
  }

  void _filterDevices(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDevices = List.from(devices);
      } else {
        filteredDevices = devices
            .where((device) =>
                device.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterDevices("");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar + refresh
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by Serial or Product",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _filterDevices,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.deepPurple),
              tooltip: "Refresh Devices",
              onPressed: _callApi,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dropdown
        if (_isLoading)
          const CircularProgressIndicator()
        else
          DropdownButton<String>(
            hint: const Text("Select Device"),
            value: _selectedDevice,
            items: filteredDevices.map((device) {
              return DropdownMenuItem(
                value: device,
                child: Text(device),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDevice = value;
              });
              widget.onSelected(value!); // send value back to parent
              debugPrint("Selected Device: $value");
            },
          ),

        if (_selectedDevice != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Chosen: $_selectedDevice"),
          ),
      ],
    );
  }
}
