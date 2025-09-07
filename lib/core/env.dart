// class Env {
//   // Populate these with your real keys or load via --dart-define
//   static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
//   static const what3WordsApiKey = String.fromEnvironment("UGKBSJD7");
// }
// class Env {
//   static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
//   static const what3WordsApiKey = String.fromEnvironment('WHAT3WORDS_API_KEY');
// }
class Env {
  /// Google Maps API key, loaded via --dart-define
  static const googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// What3Words API key, loaded via --dart-define, falls back to dev key if not defined
  static const what3WordsApiKey =
      String.fromEnvironment('WHAT3WORDS_API_KEY', defaultValue: 'UGKBSJD7');
}
