import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_models.dart';
import '../models/settings_models.dart';
import '../providers/selection_providers.dart';
import 'app_providers.dart'; // defines venueEventRepoProvider

/// FutureProvider for fetching events with their venues.
final eventsQueryProvider =
    FutureProvider.autoDispose<List<(EventItem, Venue)>>((ref) async {
      final settings = ref.watch(searchSettingsProvider);
      final repo = ref.read(venueEventRepoProvider);
      final origin = await _origin(ref, settings);

      final rows = await repo.eventsWithVenues(
        typeIds: settings.eventTypeIds,
        from: settings.startDate,
        to: settings.endDate,
        settings: settings,
        origin: origin,
        distanceService: ref.read(distanceServiceProvider),
      );

      return rows;
    });

Future<(double, double)?> _origin(Ref ref, SearchSettings settings) async {
  if (settings.proximityScope != ProximityScope.miles) return null;

  if (settings.locationMode == LocationMode.current) {
    final pos = await ref.read(geoServiceProvider).currentPosition();
    return (pos.latitude, pos.longitude);
  }

  final specified = settings.specifiedLocation;
  if (specified == null) return null;

  switch (specified.kind) {
    case SpecifiedLocationKind.postcode:
      return ref.read(geoServiceProvider).geocodePostcode(specified.value);
    case SpecifiedLocationKind.plusCode:
      return ref.read(geoServiceProvider).geocodePlusCode(specified.value);
    case SpecifiedLocationKind.threeWords:
      return ref.read(w3wServiceProvider).toCoords(specified.value);
  }
}
