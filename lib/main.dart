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
      actions: [
        // Refresh button in the AppBar (right side)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
              backgroundColor: Colors.deepPurple.shade100,
              elevation: 0, // keep it flat to blend with AppBar
            ),
            onPressed: _refreshAll,
            child: const Icon(Icons.refresh,
                color: Colors.deepPurple, size: 24),
          ),
        ),
      ],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Box 1: Current Location
            SizedBox(
              width: double.infinity,
              height: 140,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current Location:",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_locationMessage,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Box 2: Scan Result with button on the right
            SizedBox(
              width: double.infinity,
              height: 140,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Scan Result Text
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Scan Result:",
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(_scanMessage,
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Scan Button on the right
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.deepPurple.shade100,
                        ),
                        onPressed: _scanCode,
                        child: const Icon(Icons.qr_code_scanner,
                            color: Colors.deepPurple, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Box 3: Select Action with adjusted height
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select Action:",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 200, // controlled width for dropdown
                        child: ActionList(
                          onSelected: (value) {
                            setState(() {
                              _selectedAction = value;
                            });
                          },
                        ),
                      ),
                      if (_selectedAction != null) ...[
                        const SizedBox(height: 8),
                        Text("Chosen: $_selectedAction",
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}