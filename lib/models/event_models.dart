import 'package:cloud_firestore/cloud_firestore.dart';

/// Event type model (dynamic from Firestore)
class EventTypeModel {
  final String id;
  final String label;
  final int order;

  EventTypeModel({required this.id, required this.label, required this.order});

  factory EventTypeModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventTypeModel(
      id: doc.id,
      label: d['label'] ?? doc.id,
      order: d['order'] ?? 999, // fallback if missing
    );
  }

  @override
  String toString() => 'EventTypeModel(id: $id, label: $label, order: $order)';
}

/// A venue where events take place
class Venue {
  final String id;
  final String name;
  final String postcode; // canonical UK postcode
  final double lat;
  final double lng;
  final String what3words; // optional
  final String description;
  final String address;
  final String venueContactName;
  final String venuePhoneNumber;
  final String eventContactName;
  final String eventContactNumber;
  final String plusCode;
  final List<String> parkingDetails;
  final String socialMediaDetails;
  final String photoUrl;
  final String website;

  Venue({
    required this.id,
    required this.name,
    required this.postcode,
    required this.lat,
    required this.lng,
    required this.what3words,
    this.description = '',
    this.address = '',
    this.venueContactName = '',
    this.venuePhoneNumber = '',
    this.eventContactName = '',
    this.eventContactNumber = '',
    this.plusCode = '',
    this.parkingDetails = const [],
    this.socialMediaDetails = '',
    this.photoUrl = '',
    this.website = '',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'postcode': postcode,
    'lat': lat,
    'lng': lng,
    'what3words': what3words,
    'description': description,
    'address': address,
    'venueContactName': venueContactName,
    'venuePhoneNumber': venuePhoneNumber,
    'eventContactName': eventContactName,
    'eventContactNumber': eventContactNumber,
    'plusCode': plusCode,
    'parkingDetails': parkingDetails,
    'socialMediaDetails': socialMediaDetails,
    'photoUrl': photoUrl,
    'website': website,
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
      description: d['description'] ?? '',
      address: d['address'] ?? '',
      venueContactName: d['venueContactName'] ?? '',
      venuePhoneNumber: d['venuePhoneNumber'] ?? '',
      eventContactName: d['eventContactName'] ?? '',
      eventContactNumber: d['eventContactNumber'] ?? '',
      plusCode: d['plusCode'] ?? '',
      parkingDetails: (d['parkingDetails'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      socialMediaDetails: d['socialMediaDetails'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
      website: d['website'] ?? '',
    );
  }
}

/// An event linked to a venue
class EventItem {
  final String id;
  final String venueId;
  final String typeId; // Firestore eventTypes/<id>
  final DateTime start;
  final DateTime end;

  EventItem({
    required this.id,
    required this.venueId,
    required this.typeId,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() => {
    'venueId': venueId,
    'type': typeId,
    'start': Timestamp.fromDate(start.toUtc()), // ✅ Firestore Timestamp
    'end': Timestamp.fromDate(end.toUtc()),
  };

  factory EventItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventItem(
      id: doc.id,
      venueId: d['venueId'] ?? '',
      typeId: d['type'] ?? '',
      start: (d['start'] as Timestamp).toDate().toLocal(),
      end: (d['end'] as Timestamp).toDate().toLocal(),
    );
  }
}
