import '../models/event_models.dart';
import '../services/firestore_service.dart';

class VenueEventRepository {
  final FirestoreService _fs;
  VenueEventRepository(this._fs);

  Future<List<(EventItem e, Venue v)>> eventsWithVenues({
    required List<String> typeIds,
    required DateTime from,
  }) async {
    final eventsById = <String, EventItem>{};
    for (final typeId in typeIds) {
      final events = await _fs.getEvents(typeId: typeId, from: from);
      for (final event in events) {
        eventsById[event.id] = event;
      }
    }

    final events = eventsById.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final venuesCache = <String, Venue>{};
    final out = <(EventItem, Venue)>[];

    for (final e in events) {
      final v = venuesCache[e.venueId] ??=
          await _fs.getVenue(e.venueId) ??
          (throw StateError('Venue not found for id ${e.venueId}'));
      out.add((e, v));
    }

    return out;
  }
}
