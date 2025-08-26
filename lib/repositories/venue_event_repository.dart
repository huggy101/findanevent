import '../models/event_models.dart';
import '../services/firestore_service.dart';

class VenueEventRepository {
  final FirestoreService _fs;
  VenueEventRepository(this._fs);

  Future<List<(EventItem e, Venue v)>> eventsWithVenues({required EventType type, required DateTime from}) async {
    final events = await _fs.getEvents(type: type, from: from);
    final venuesCache = <String, Venue>{};
    final out = <(EventItem, Venue)>[];
    for (final e in events) {
      venuesCache[e.venueId] ??= (await _fs.getVenue(e.venueId))!;
      out.add((e, venuesCache[e.venueId]!));
    }
    return out;
  }
}
