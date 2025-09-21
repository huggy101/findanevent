import '../models/event_models.dart';
import '../services/firestore_service.dart';

class VenueEventRepository {
  final FirestoreService _fs;
  VenueEventRepository(this._fs);

  Future<List<(EventItem e, Venue v)>> eventsWithVenues({
    required String typeId,
    required DateTime from,
  }) async {
    // ✅ Call the actual FirestoreService method
    final events = await _fs.getEvents(typeId: typeId, from: from);

    final venuesCache = <String, Venue>{};
    final out = <(EventItem, Venue)>[];

    for (final e in events) {
      // fetch & cache venue; throw helpful error if absent
      final v = venuesCache[e.venueId] ??= await _fs.getVenue(e.venueId)
          ?? (throw StateError('Venue not found for id ${e.venueId}'));
      out.add((e, v));
    }

    return out;
  }
}
