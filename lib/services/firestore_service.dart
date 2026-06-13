import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  /// Fetch all event types from Firestore
  Future<List<EventTypeModel>> getEventTypes() async {
    final q = await _db
        .collection('eventTypes')
        .orderBy('order') // 👈 Added ordering by 'order' field
        .get();

    // 🔍 Debugging lines
    // print("Number of docs: ${q.docs.length}");
    // for (var doc in q.docs) {
    //   print("Doc ID: ${doc.id}, data: ${doc.data()}");
    // }

    // Now map into your model
    final eventTypes = q.docs.map(EventTypeModel.fromDoc).toList();
    // print("Mapped eventTypes: $eventTypes");

    return eventTypes;
  }

  /// Fetch all venues
  Future<List<Venue>> getVenues() async {
    final q = await _db.collection('venues').get();
    return q.docs.map(Venue.fromDoc).toList();
  }

  /// Add a venue to Firestore.
  Future<DocumentReference<Map<String, dynamic>>> addVenue(Venue venue) {
    return _db.collection('venues').add(venue.toMap());
  }

  /// Update an existing venue in Firestore.
  Future<void> updateVenue(Venue venue) {
    return _db.collection('venues').doc(venue.id).update(venue.toMap());
  }

  /// Fetch an event by its public reference / document ID.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getEventByReference(
    String eventReference,
  ) async {
    final d = await _db.collection('events').doc(eventReference).get();
    return d.exists ? d : null;
  }

  /// Create or update an event using the generated public reference as doc ID.
  Future<void> saveEvent({
    required String eventReference,
    required Map<String, dynamic> data,
  }) {
    return _db
        .collection('events')
        .doc(eventReference)
        .set(data, SetOptions(merge: true));
  }

  /// Fetch events by Firestore type ID and start date
  Future<List<EventItem>> getEvents({
    required String typeId, // 🔑 replaced EventType with string ID
    required DateTime from,
  }) async {
    final q = await _db
        .collection('events')
        .where('type', isEqualTo: typeId) // 🔑 use typeId
        .where(
          'start',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(from.year, from.month, from.day),
          ),
        )
        .orderBy('start')
        .limit(200)
        .get();

    return q.docs.map(EventItem.fromDoc).toList();
  }

  /// Fetch single venue by ID
  Future<Venue?> getVenue(String id) async {
    final d = await _db.collection('venues').doc(id).get();
    return d.exists ? Venue.fromDoc(d) : null;
  }
}
