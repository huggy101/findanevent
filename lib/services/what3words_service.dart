// lib/services/what3words_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class What3WordsService {
  final String apiKey;
  What3WordsService(this.apiKey);

  /// three words -> coordinates
  Future<(double, double)> toCoords(String threeWords) async {
    final url = Uri.parse(
      'https://api.what3words.com/v3/convert-to-coordinates'
      '?words=${Uri.encodeComponent(threeWords)}&key=$apiKey',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('what3words request failed (${resp.statusCode})');
    }

    final data = json.decode(resp.body);
    final coords = data['coordinates'];
    if (coords == null) {
      final msg = data['error']?['message'] ?? 'Invalid what3words address';
      throw Exception(msg);
    }

    final lat = (coords['lat'] as num).toDouble();
    final lng = (coords['lng'] as num).toDouble();
    return (lat, lng);
    }

  /// coordinates -> three words
  Future<String> fromCoords(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.what3words.com/v3/convert-to-3wa'
      '?coordinates=$lat,$lng&key=$apiKey',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('what3words request failed (${resp.statusCode})');
    }

    final data = json.decode(resp.body);
    final words = data['words'] as String?;
    if (words == null) {
      final msg = data['error']?['message'] ?? 'Could not get three words';
      throw Exception(msg);
    }
    return words;
  }
}
