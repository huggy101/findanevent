import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GeoService {
  final String apiKey; // Google Maps API Key

  GeoService({required this.apiKey});

  // Get current device position
  Future<Position> currentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Existing method: geocode a UK postcode
  Future<(double, double)> geocodePostcode(String postcode) async {
    // Replace with your existing postcode geocoding logic
    throw UnimplementedError();
  }

  // New method: geocode a Google Plus Code
  Future<(double, double)> geocodePlusCode(String plusCode) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$plusCode&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch coordinates for Plus Code');
    }

    final jsonData = json.decode(response.body);

    if (jsonData['status'] != 'OK' || jsonData['results'].isEmpty) {
      throw Exception('Plus Code not found');
    }

    final location = jsonData['results'][0]['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;

    return (lat, lng);
  }
}
