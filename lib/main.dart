import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'barcode_service.dart';
import 'action_list.dart';
import 'devices_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // default to day mode

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asset Tracker',
      themeMode: _themeMode,

      // 🌞 Daytime Theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.pinkAccent,
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),

      // 🌙 Night Mode Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.pinkAccent,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),

      home: MyHomePage(
        title: 'Asset Tracker',
        onThemeToggle: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  final String title;
  final void Function(bool) onThemeToggle;
  final bool isDarkMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _locationMessage = "Fetching location...";
  String _scanMessage = "No scan yet";
  String? _selectedAction;
  Device? _selectedDevice;

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
      _scanMessage = code != null
          ? "☑ Verified: $code"
          : "❌ Scan failed or cancelled";
    });
  }

  Future<void> _refreshAll() async {
    setState(() {
      _locationMessage = "Fetching location...";
      _scanMessage = "No scan yet";
      _selectedAction = null;
      _selectedDevice = null;
      _dropdownKey++;
    });
    await _loadLocation();
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    Widget? trailing,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text("Refresh All"),
              onTap: _refreshAll,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.brightness_6),
              value: widget.isDarkMode,
              onChanged: widget.onThemeToggle,
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _dashboardCard(
              icon: Icons.location_on,
              title: "Current Location",
              subtitle: _locationMessage,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            _dashboardCard(
              icon: Icons.qr_code_scanner,
              title: "Scan Result",
              subtitle: _scanMessage,
              trailing: IconButton(
                icon: Icon(Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: _scanCode,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.playlist_add_check,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text("Select Action",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.devices,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text("Select Device",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DeviceDropdown(
                      key: ValueKey(_dropdownKey),
                      onSelected: (device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDevice == null
                          ? "No device selected"
                          : "Selected: ${_selectedDevice!.serialNumber} - ${_selectedDevice!.productName}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 👈 FloatingActionButton removed
    );
  }
}
