import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeoService {
  /// Get current GPS position
  Future<Position> currentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied");
    }

    return Geolocator.getCurrentPosition();
  }

  /// Reverse geocode lat/lng to postcode
  Future<String> reverseGeocodePostcode(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) throw Exception("No placemark found");
    return placemarks.first.postalCode ?? "UNKNOWN";
  }

  /// Convert lat/lng into a Google Plus Code
  Future<String> reverseGeocodePlusCode(double lat, double lng) async {
    // For real: call Google Maps Geocoding API with plus_code=TRUE
    // For now: fake simple plus-code-ish string
    return "9C4W${lat.toStringAsFixed(2)}+${lng.toStringAsFixed(2)}";
  }

  /// Forward geocode: postcode → coordinates (lat, lng)
  Future<(double, double)> geocodePostcode(String postcode) async {
    final locations = await locationFromAddress(postcode);
    if (locations.isEmpty) throw Exception("No coordinates found for $postcode");
    final loc = locations.first;
    return (loc.latitude, loc.longitude);
  }

  /// Forward geocode: Plus Code → coordinates (lat, lng)
  Future<(double, double)> geocodePlusCode(String plusCode) async {
    final locations = await locationFromAddress(plusCode);
    if (locations.isEmpty) throw Exception("No coordinates found for $plusCode");
    final loc = locations.first;
    return (loc.latitude, loc.longitude);
  }
}
