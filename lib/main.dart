import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'barcode_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _locationMessage =
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });
    } else {
      setState(() {
        _locationMessage = "Unable to get location";
      });
    }
  }

  Future<void> _scanAndTrack() async {
    final code = await BarcodeService.scanBarcode(context);

    if (code != null) {
      setState(() {
        _locationMessage = "Scanned Value: $code";
      });
    } else {
      setState(() {
        _locationMessage = "Scan failed or cancelled";
      });
    }
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanAndTrack,
        tooltip: 'Scan Barcode & Track',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
