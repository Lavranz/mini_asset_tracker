import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Call API to get site name based on coordinates
  static Future<String?> getSiteName(double latitude, double longitude) async {
    try {
      final url =
          "http://202.60.10.144:7500/api/astra/get/location-by-coordinates?longitude=124.66113367534089&latitude=8.476300675225362";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)[0];

        debugPrint("data: $data");
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