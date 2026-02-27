import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'barcode_service.dart';
import 'action_list.dart';
import 'devices_list.dart'; // <-- new import

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  String? _selectedAction; // receives value from ActionList
  String? _selectedDevice; // receives value from DevicesList

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

    if (code != null) {
      setState(() {
        _scanMessage = "Scanned Value: $code";
      });
    } else {
      setState(() {
        _scanMessage = "Scan failed or cancelled";
      });
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _locationMessage = "Fetching location...";
      _scanMessage = "No scan yet";
      _selectedAction = null;
      _selectedDevice = null;
    });

    await _loadLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(255, 193, 164, 245),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                backgroundColor: Colors.deepPurple.shade100,
                elevation: 0,
              ),
              onPressed: _refreshAll,
              child: const Icon(Icons.refresh,
                  color: Colors.deepPurple, size: 24),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Box 1: Current Location
            _buildCard(
              context,
              icon: Icons.location_on,
              title: "Current Location",
              content: _locationMessage,
            ),
            const SizedBox(height: 16),

            // Box 2: Scan Result
            _buildCard(
              context,
              icon: Icons.qr_code_scanner,
              title: "Scan Result",
              content: _scanMessage,
              trailingButton: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.deepPurple.shade100,
                ),
                onPressed: _scanCode,
                child: const Icon(Icons.qr_code_scanner,
                    color: Colors.deepPurple, size: 28),
              ),
            ),
            const SizedBox(height: 16),

            // Box 3: Select Action
            _buildCard(
              context,
              icon: Icons.playlist_add_check,
              title: "Select Action",
              contentWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: ActionList(
                      onSelected: (value) {
                        setState(() {
                          _selectedAction = value;
                        });
                      },
                    ),
                  ),
                  if (_selectedAction != null) ...[
                    const SizedBox(height: 12),
                    Text("Chosen: $_selectedAction",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Box 4: Devices Dropdown
            _buildCard(
              context,
              icon: Icons.devices,
              title: "Select Device",
              contentWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DevicesList(
                    onSelected: (device) {
                      setState(() {
                        _selectedDevice = device;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Selected: ${device.toString()}")),
                      );
                    },
                  ),
                  if (_selectedDevice != null) ...[
                    const SizedBox(height: 12),
                    Text("Chosen: ${_selectedDevice.toString()}",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String title,
      String? content,
      Widget? contentWidget,
      Widget? trailingButton}) {
    return Card(
      color: const Color(0xFFFFF1CB),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (trailingButton != null) trailingButton,
              ],
            ),
            const SizedBox(height: 12),
            if (content != null)
              Text(content, style: Theme.of(context).textTheme.bodyLarge),
            if (contentWidget != null) contentWidget,
          ],
        ),
      ),
    );
  }
}
