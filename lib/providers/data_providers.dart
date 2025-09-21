import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_models.dart';
import '../providers/selection_providers.dart';
import 'app_providers.dart'; // defines venueEventRepoProvider

/// FutureProvider for fetching events with their venues
final eventsQueryProvider =
    FutureProvider.autoDispose<List<(EventItem, Venue)>>((ref) async {
  final settings = ref.watch(searchSettingsProvider);
  final repo = ref.read(venueEventRepoProvider);

  // ✅ Use eventTypeId (string) instead of enum
  final rows = await repo.eventsWithVenues(
    typeId: settings.eventTypeId,
    from: settings.startDate,
  );

  return rows;
});
