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
  String _scanMessage = "No scan yet";

  // Dropdown selected value
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  // Load location and site name
  Future<void> _loadLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      String? siteName = await LocationService.getSiteName(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _locationMessage = siteName ?? "APOLLO OJT OFFICE";
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
            const SizedBox(height: 30),

            // Dropdown list
            DropdownButton<String>(
              hint: const Text("Select Action"),
              value: _selectedAction,
              items: const [
                DropdownMenuItem(value: "RECEIVE", child: Text("RECEIVE")),
                DropdownMenuItem(value: "SEND", child: Text("SEND")),
                DropdownMenuItem(value: "DEPLOY", child: Text("DEPLOY")),
                DropdownMenuItem(value: "PULL-OUT", child: Text("PULL-OUT")),
                DropdownMenuItem(value: "DEFECTIVE", child: Text("DEFECTIVE")),
                DropdownMenuItem(value: "FIXED", child: Text("FIXED")),
                DropdownMenuItem(
                    value: "DECOMMISSION", child: Text("DECOMMISSION")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAction = value;
                });
                // Print to console
                debugPrint("Selected Action: $value");
              },
            ),

            if (_selectedAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "$_selectedAction",
                  style: Theme.of(context).textTheme.bodyLarge,
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
