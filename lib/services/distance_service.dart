import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/env.dart';

class DistanceService {
  double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    double dLat = _deg2rad(lat2 - lat1), dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat/2)*sin(dLat/2) + cos(_deg2rad(lat1))*cos(_deg2rad(lat2))*sin(dLon/2)*sin(dLon/2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }
  double _deg2rad(double deg) => deg * pi / 180.0;

  Future<int?> drivingDistanceMeters((double lat, double lng) origin, (double lat, double lng) dest) async {
    final key = Env.googleMapsApiKey;
    if (key.isEmpty) return null;
    final url = Uri.parse('https://maps.googleapis.com/maps/api/distancematrix/json?units=metric'
        '&origins=${origin.$1},${origin.$2}&destinations=${dest.$1},${dest.$2}&key=$key');
    final r = await http.get(url);
    if (r.statusCode != 200) return null;
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    try {
      final el = json['rows'][0]['elements'][0];
      if (el['status'] == 'OK') return el['distance']['value'] as int;
    } catch (_) {}
    return null;
  }
}
