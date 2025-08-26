import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<List<Venue>> getVenues() async {
    final q = await _db.collection('venues').get();
    return q.docs.map(Venue.fromDoc).toList();
  }

  Future<List<EventItem>> getEvents({required EventType type, required DateTime from}) async {
    final q = await _db
        .collection('events')
        .where('type', isEqualTo: type.name)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(from.year, from.month, from.day)))
        .orderBy('start')
        .limit(200)
        .get();
    return q.docs.map(EventItem.fromDoc).toList();
  }

  Future<Venue?> getVenue(String id) async {
    final d = await _db.collection('venues').doc(id).get();
    return d.exists ? Venue.fromDoc(d) : null;
  }
}
