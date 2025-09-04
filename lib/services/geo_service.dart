import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GeoService {
  final String apiKey; // Google Maps API Key

  GeoService({required this.apiKey});

  /// Get current device location
  Future<Position> currentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, cannot request.');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Geocode a UK postcode -> (lat, lng)
  Future<(double, double)> geocodePostcode(String postcode) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$postcode&region=uk&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch coordinates for postcode');
    }

    final jsonData = json.decode(response.body);

    if (jsonData['status'] != 'OK' || jsonData['results'].isEmpty) {
      throw Exception('Postcode not found');
    }

    final location = jsonData['results'][0]['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;

    return (lat, lng);
  }

  /// Geocode a Plus Code -> (lat, lng)
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

  /// Reverse-geocode lat/lng -> UK Postcode
  Future<String> reverseGeocodePostcode(double lat, double lng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to reverse-geocode postcode');
    }

    final jsonData = json.decode(response.body);
    if (jsonData['status'] != 'OK' || jsonData['results'].isEmpty) {
      throw Exception('No address found for location');
    }

    // Look for postal_code component
    for (var result in jsonData['results']) {
      for (var comp in result['address_components']) {
        if ((comp['types'] as List).contains('postal_code')) {
          return comp['long_name'];
        }
      }
    }

    throw Exception('No postcode found at this location');
  }

  /// Reverse-geocode lat/lng -> Plus Code
  Future<String> reverseGeocodePlusCode(double lat, double lng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to reverse-geocode Plus Code');
    }

    final jsonData = json.decode(response.body);
    if (jsonData['status'] != 'OK' || jsonData['plus_code'] == null) {
      throw Exception('No Plus Code found for location');
    }

    return jsonData['plus_code']['global_code'];
  }
}
