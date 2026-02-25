import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'barcode_service.dart';
import 'action_list.dart'; // new import

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
    });

    await _loadLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(255, 193, 164, 245),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Current Location:",
                style: Theme.of(context).textTheme.titleMedium),
            Text(_locationMessage,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Text("Scan Result:",
                style: Theme.of(context).textTheme.titleMedium),
            Text(_scanMessage, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
            const SizedBox(height: 30),

            // Use ActionList widget
            ActionList(
              onSelected: (value) {
                setState(() {
                  _selectedAction = value;
                });
              },
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
