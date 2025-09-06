import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of events supported in the app
enum EventType { openMicJam, gig, karaoke }

/// Extension to return human-friendly labels
extension EventTypeLabel on EventType {
  String get label => switch (this) {
        EventType.openMicJam => 'Open Mic / Jam',
        EventType.gig => 'Gig',
        EventType.karaoke => 'Karaoke',
      };
}

/// A venue where events take place
class Venue {
  final String id;
  final String name;
  final String postcode; // canonical UK postcode
  final double lat;
  final double lng;
  final String what3words; // optional

  Venue({
    required this.id,
    required this.name,
    required this.postcode,
    required this.lat,
    required this.lng,
    required this.what3words,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'postcode': postcode,
        'lat': lat,
        'lng': lng,
        'what3words': what3words,
      };

  factory Venue.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Venue(
      id: doc.id,
      name: d['name'] ?? 'Venue',
      postcode: d['postcode'] ?? '',
      lat: (d['lat'] ?? 0).toDouble(),
      lng: (d['lng'] ?? 0).toDouble(),
      what3words: d['what3words'] ?? '',
    );
  }
}

/// An event linked to a venue
class EventItem {
  final String id;
  final String venueId;
  final EventType type;
  final DateTime start;
  final DateTime end;

  EventItem({
    required this.id,
    required this.venueId,
    required this.type,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() => {
        'venueId': venueId,
        'type': type.name,
        'start': Timestamp.fromDate(start.toUtc()), // ✅ Firestore Timestamp
        'end': Timestamp.fromDate(end.toUtc()),
      };

  factory EventItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventItem(
      id: doc.id,
      venueId: d['venueId'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => EventType.openMicJam,
      ),
      start: (d['start'] as Timestamp).toDate().toLocal(),
      end: (d['end'] as Timestamp).toDate().toLocal(),
    );
  }
}
