import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_models.dart';
// import '../repositories/venue_event_repository.dart';
import 'selection_providers.dart';
import 'app_providers.dart'; // This should define venueEventRepoProvider

// FutureProvider for fetching events with their venues
final eventsQueryProvider = FutureProvider.autoDispose<List<(EventItem, Venue)>>((ref) async {
  final settings = ref.watch(searchSettingsProvider);
  final repo = ref.read(venueEventRepoProvider);

  // Fetch events based on selected type and start date
  final rows = await repo.eventsWithVenues(
    type: settings.eventType,
    from: settings.startDate,
  );
  return rows;
});
