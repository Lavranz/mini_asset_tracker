import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
      // Permission is permanently denied
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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    print(position);
    return position;
  } catch (e) {
    debugPrint("Error getting location: $e");
    return null;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _locationMessage = "Fetching location...";
  String _currentLocationLabel = "Current Location:"; // 👈 new label

  @override
  void initState() {
    super.initState();
    _loadLocation(); // fetch location immediately when widget starts
  }

  Future<void> _loadLocation() async {
    Position? position = await getCurrentLocation();
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

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _loadLocation(); // optional refresh
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
            //Text("You have pushed the button this many times:"),
            //Text("$_counter",
            //    style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),

            // 👇 Current location label at the top
            Text("Current Location:",
                style: Theme.of(context).textTheme.titleMedium),

            // 👇 Latitude and longitude below
            Text(_locationMessage,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment & Refresh Location',
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
