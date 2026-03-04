import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'barcode_service.dart';
import 'action_list.dart';
import 'devices_list.dart'; // contains Device model + DeviceDropdown widget

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asset Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 218, 59, 59),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Asset Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _locationMessage = "Fetching location...";
  String _scanMessage = "No scan yet";
  String? _selectedAction;
  Device? _selectedDevice;

  // 👇 Add this counter to force rebuild of DeviceDropdown
  int _dropdownKey = 0;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      String? siteName = await LocationService.getSiteName(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _locationMessage = siteName ?? "Unknown Location";
      });
    } else {
      setState(() {
        _locationMessage = "Unable to get location";
      });
    }
  }

  Future<void> _scanCode() async {
    final code = await BarcodeService.scanBarcode(context);
    setState(() {
      _scanMessage =
          code != null ? "☑ Verified: $code" : "❌ Scan failed or cancelled";
    });
  }

  Future<void> _refreshAll() async {
    setState(() {
      _locationMessage = "Fetching location...";
      _scanMessage = "No scan yet";
      _selectedAction = null;
      _selectedDevice = null;
      _dropdownKey++; // 👈 force rebuild of DeviceDropdown
    });

    await _loadLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Location Card
            Card(
              elevation: 4,
              child: ListTile(
                leading:
                    const Icon(Icons.location_on, color: Colors.deepPurple),
                title: const Text("Current Location"),
                subtitle: Text(_locationMessage),
              ),
            ),
            const SizedBox(height: 12),

            // Barcode Card
            Card(
              elevation: 4,
              child: ListTile(
                leading:
                    const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
                title: const Text("Scan Result"),
                subtitle: Text(_scanMessage),
                trailing: ElevatedButton(
                  onPressed: _scanCode,
                  child: const Text("Scan"),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Dropdown Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Action",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ActionList(
                      selected: _selectedAction,
                      onSelected: (value) {
                        setState(() {
                          _selectedAction = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Devices Dropdown Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Device",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DeviceDropdown(
                      key: ValueKey(_dropdownKey), // 👈 forces rebuild
                      onSelected: (device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedDevice == null
                        ? "No device selected"
                        : "Selected: ${_selectedDevice!.serialNumber} - ${_selectedDevice!.productName}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Refresh Button
            ElevatedButton.icon(
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh All"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanCode,
        tooltip: 'Scan Barcode/QR Code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
