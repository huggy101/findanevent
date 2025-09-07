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

/// Geo service, requires Google Maps API key from Env
final geoServiceProvider = Provider(
  (_) => GeoService(),
);

final distanceServiceProvider = Provider((_) => DistanceService());

/// What3Words service, requires API key from Env
final w3wServiceProvider = Provider(
  (_) => What3WordsService(Env.what3WordsApiKey),
);

final settingsRepoProvider = Provider((_) => SettingsRepository());

final venueEventRepoProvider = Provider(
  (ref) => VenueEventRepository(ref.read(firestoreServiceProvider)),
);
