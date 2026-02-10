import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: const MyHomePage(title: 'Asset Tracker'),
    );
  }
}

Future<bool> handleLocationPermission() async {
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

Future<Position?> getCurrentLocation() async {
  bool hasPermission = await handleLocationPermission();
  if (!hasPermission) return null;

  try {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    debugPrint(position.toString());
    return position;
  } catch (e) {
    debugPrint("Error getting location: $e");
    return null;
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
  String? _scannedValue;

  @override
  void initState() {
    super.initState();
    _getLocation(); // Fetch location automatically when the widget loads
  }

  Future<void> _getLocation() async {
    Position? position = await getCurrentLocation();
    setState(() {
      _currentPosition = position;
    });

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied or unavailable')),
      );
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
                Navigator.pop(context); // Close scanner after detection
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.black45,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentPosition != null) ...[
                    const Icon(Icons.location_on,
                        size: 50, color: Colors.deepPurple),
                    const SizedBox(height: 15),
                    Text(
                      'Latitude: ${_currentPosition!.latitude}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Longitude: ${_currentPosition!.longitude}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Coordinates fetched successfully!',
                        style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.location_off,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 15),
                    const Text('Location not available'),
                  ],
                  const SizedBox(height: 20),
                  if (_scannedValue != null)
                    Column(
                      children: [
                        const Icon(Icons.qr_code,
                            size: 50, color: Colors.deepPurple),
                        const SizedBox(height: 10),
                        Text(
                          'Scanned Value: $_scannedValue',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _getLocation,
            label: const Text('Get Location'),
            icon: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _scanCode,
            label: const Text('Scan Code'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
    );
  }
}
