import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../repositories/venue_event_repository.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/geo_service.dart';
import '../services/distance_service.dart';
import '../services/what3words_service.dart';
import '../repositories/settings_repository.dart';
import '../repositories/venue_event_repository.dart';
// import '../repositories/venue_event_repository.dart';
import '../core/env.dart';

final authServiceProvider = Provider((_) => AuthService());
final firestoreServiceProvider = Provider((_) => FirestoreService());
final geoServiceProvider = Provider(
  (_) => GeoService(apiKey: Env.googleMapsApiKey),
);

final distanceServiceProvider = Provider((_) => DistanceService());
// final w3wServiceProvider = Provider((_) => What3WordsService());
final w3wServiceProvider = Provider(
  (_) => What3WordsService(Env.what3WordsApiKey),
);

final settingsRepoProvider = Provider((_) => SettingsRepository());
final venueEventRepoProvider = Provider(
  (ref) => VenueEventRepository(ref.read(firestoreServiceProvider)),
);
