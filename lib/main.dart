import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// -------------------- 🌐 LOCATION SERVICE --------------------
class LocationService {
  static Future<bool> handleLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requestResult = await Geolocator.requestPermission();
      if (requestResult == LocationPermission.deniedForever) {
        return false;
      }
      return requestResult != LocationPermission.denied;
    }
    return permission != LocationPermission.denied;
  }

  static Future<Position?> getCurrentLocation() async {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint("Position: $position");
      return position;
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  // Dummy API call to get site name based on coordinates
  static Future<String?> getSiteName(double latitude, double longitude) async {
    try {
      final url = "http://202.60.10.144:7500/api/poc/get/location-by-coordinates?longitude=124.66114625675772&latitude=8.47629726307542"; // 🔗 Replace with real API
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)[0];
        return data['siteName'];
      } else {
        debugPrint("API error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
      return null;
    }
  }
}
// -------------------------------------------------------------

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
  Position? _currentPosition;
  String? _siteName;
  String? _scannedValue;
  String? _selectedAction;

  final List<String> _actions = [
    "RECEIVE",
    "SEND",
    "DEPLOY",
    "PULL-OUT",
    "DEFECTIVE",
    "FIXED",
    "DECOMMISSION",
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    setState(() {
      _currentPosition = position;
    });

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied or unavailable')),
      );
    } else {
      String? site = await LocationService.getSiteName(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _siteName = site;
      });
    }
  }

  Future<void> _scanCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scan Barcode/QR")),
          body: MobileScanner(
            onDetect: (barcodeCapture) {
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                setState(() {
                  _scannedValue = barcodes.first.rawValue ?? "Unknown";
                });
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildCard(
      icon: _currentPosition != null ? Icons.location_on : Icons.location_off,
      iconColor: _currentPosition != null ? Colors.deepPurple : Colors.grey,
      title: "Site",
      subtitle: _currentPosition != null
          ? Column(
              children: [
                Text(
                  _siteName ?? "Fetching site name...",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: const Text(
                    "Coordinates fetched",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              ],
            )
          : const Text("Location not available"),
    );
  }

  Widget _buildScannerCard() {
    return _buildCard(
      icon: Icons.qr_code_scanner,
      iconColor: Colors.deepPurple,
      title: "Scanner",
      subtitle: Column(
        children: [
          _scannedValue != null
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurple, width: 1.2),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _scannedValue!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                )
              : const Text("No code scanned yet"),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _scanCode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Scan Code"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return _buildCard(
      icon: Icons.list_alt,
      iconColor: Colors.deepPurple,
      title: "Action",
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            hint: const Text("Select Action"),
            value: _selectedAction,
            items: _actions.map((String action) {
              return DropdownMenuItem<String>(
                value: action,
                child: Text(action),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _selectedAction = newValue);
              debugPrint("Selected: $newValue");
              // You can also call your API here with siteName + action if needed
            },
          ),
          if (_selectedAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Chip(
                label: Text(
                  "Selected: $_selectedAction",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                labelStyle: const TextStyle(color: Colors.deepPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? subtitle,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 340,
          minHeight: 260,
          maxWidth: 420,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: iconColor),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 14),
              subtitle,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLocationCard(),
              const SizedBox(width: 24),
              _buildScannerCard(),
              const SizedBox(width: 24),
              _buildActionCard(),
            ],
          ),
        ),
      ),
    );
  }
}
