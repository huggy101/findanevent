import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;

class GeoService {
  Future<Position> currentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    // ✅ Use LocationSettings instead of deprecated desiredAccuracy
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<(double lat, double lng)> geocodePostcode(String postcode) async {
    final locs = await gc.locationFromAddress(postcode);
    final l = locs.first;
    return (l.latitude, l.longitude);
  }
}
