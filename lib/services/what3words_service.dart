import 'package:what3words/what3words.dart';

class What3WordsService {
  final What3WordsV3 _api;

  What3WordsService(String apiKey) : _api = What3WordsV3(apiKey);

  Future<(double lat, double lng)> toCoords(String threeWords) async {
    final res = await _api.convertToCoordinates(threeWords).execute();

    // explicitly check for success
    if (res.isSuccessful == true) {
      final data = res.data();
      final coord = data?.coordinates;
      if (coord != null) {
        return (coord.lat, coord.lng);
      }
    }

    // handle error
    final error = res.error();
    throw Exception('Invalid w3w: ${error?.code ?? 'unknown'}');
  }
}
