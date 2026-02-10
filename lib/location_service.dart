// lib/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

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
          accuracy: LocationAccuracy.best, // 👈 use best accuracy
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
}
