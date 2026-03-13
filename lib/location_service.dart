import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  /// Handle location permission safely
  static Future<bool> handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission permanently denied.");
        return false;
      }
    }

    return permission != LocationPermission.denied &&
           permission != LocationPermission.deniedForever;
  }

  /// Get current device position
  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      debugPrint("No location permission granted.");
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
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

  /// Call API to get site name based on coordinates
  static Future<String?> getSiteName(double latitude, double longitude) async {
    try {
      // 👇 Construct URL properly with query parameters
      final url =
          "http://202.60.10.144:7500/api/astra/get/location-by-coordinates?longitude=124.66113367534089&latitude=8.476300675225362";

      debugPrint("Calling site API: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Ensure response is a list or map
        if (decoded is List && decoded.isNotEmpty) {
          final data = decoded[0];
          debugPrint("Site data: $data");
          return data['siteName'] as String?;
        } else if (decoded is Map) {
          debugPrint("Site data: $decoded");
          return decoded['siteName'] as String?;
        } else {
          debugPrint("Unexpected API format: $decoded");
          return null;
        }
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
