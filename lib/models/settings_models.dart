import 'package:intl/intl.dart';
import 'event_models.dart';

enum LocationMode { current, specified }

enum SpecifiedLocationKind { postcode, latlng, threeWords }

class SpecifiedLocation {
  final SpecifiedLocationKind kind;
  final String value;

  SpecifiedLocation(this.kind, this.value);
}


class SearchSettings {
  final EventType eventType;
  final LocationMode locationMode;
  final SpecifiedLocation? specifiedLocation;
  final DateTime startDate; // at midnight

  const SearchSettings({
    required this.eventType,
    required this.locationMode,
    this.specifiedLocation,
    required this.startDate,
  });

  String dateLabel() => DateFormat('EEEE d MMMM yyyy').format(startDate);

  SearchSettings copyWith({
    EventType? eventType,
    LocationMode? locationMode,
    SpecifiedLocation? specifiedLocation,
    DateTime? startDate,
  }) => SearchSettings(
        eventType: eventType ?? this.eventType,
        locationMode: locationMode ?? this.locationMode,
        specifiedLocation: specifiedLocation ?? this.specifiedLocation,
        startDate: startDate ?? this.startDate,
      );

  Map<String, dynamic> toMap() => {
        'eventType': eventType.name,
        'locationMode': locationMode.name,
        'specifiedLocation': specifiedLocation == null
            ? null
            : {
                'kind': specifiedLocation!.kind.name,
                'value': specifiedLocation!.value,
              },
        'startDate': DateTime(startDate.year, startDate.month, startDate.day).toUtc().toIso8601String(),
      };

  factory SearchSettings.fromMap(Map<String, dynamic> m) => SearchSettings(
        eventType: EventType.values.firstWhere((e) => e.name == m['eventType'], orElse: () => EventType.openMic),
        locationMode: LocationMode.values.firstWhere((e) => e.name == m['locationMode'], orElse: () => LocationMode.current),
        specifiedLocation: m['specifiedLocation'] == null
            ? null
            : SpecifiedLocation(
                SpecifiedLocationKind.values.firstWhere((k) => k.name == m['specifiedLocation']['kind'], orElse: () => SpecifiedLocationKind.postcode),
                m['specifiedLocation']['value'],
              ),
        startDate: DateTime.parse(m['startDate']).toLocal(),
      );
}