import 'package:intl/intl.dart';

enum LocationMode { current, specified }

enum SpecifiedLocationKind { postcode, plusCode, threeWords }

enum ProximityScope { miles, nationwide, worldwide }

class SpecifiedLocation {
  final SpecifiedLocationKind kind;
  final String value;

  const SpecifiedLocation(this.kind, this.value);

  Map<String, dynamic> toMap() => {'kind': kind.name, 'value': value};

  factory SpecifiedLocation.fromMap(Map<String, dynamic> m) {
    return SpecifiedLocation(
      SpecifiedLocationKind.values.firstWhere(
        (k) => k.name == m['kind'],
        orElse: () => SpecifiedLocationKind.postcode,
      ),
      m['value'] as String,
    );
  }
}

class SearchSettings {
  /// Firestore IDs of the event types (from `eventTypes` collection).
  final List<String> eventTypeIds;

  final LocationMode locationMode;
  final SpecifiedLocation? specifiedLocation;

  /// start and end dates (at midnight)
  final DateTime startDate;
  final DateTime endDate;

  // proximity
  final ProximityScope proximityScope;
  final int miles;

  const SearchSettings({
    required this.eventTypeIds,
    required this.locationMode,
    this.specifiedLocation,
    required this.startDate,
    required this.endDate,
    this.proximityScope = ProximityScope.miles,
    this.miles = 20,
  });

  /// Format a single date as: "Monday 1st Sep 2025"
  static String _formatWithOrdinal(DateTime d) {
    final day = d.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    final weekday = DateFormat('EEE').format(d); // e.g. Mon
    final monthShort = DateFormat('MMM').format(d); // e.g. Sep
    return '$weekday $day$suffix $monthShort ${d.year}';
  }

  /// Human friendly single-date label (start)
  String startLabel() => _formatWithOrdinal(startDate);

  /// Date range label, e.g. "Mon 1st Sep 2025 -> Mon 8th Sep 2025"
  String rangeLabel() =>
      '${_formatWithOrdinal(startDate)} -> ${_formatWithOrdinal(endDate)}';

  SearchSettings copyWith({
    List<String>? eventTypeIds,
    LocationMode? locationMode,
    SpecifiedLocation? specifiedLocation,
    DateTime? startDate,
    DateTime? endDate,
    ProximityScope? proximityScope,
    int? miles,
  }) => SearchSettings(
    eventTypeIds: eventTypeIds ?? this.eventTypeIds,
    locationMode: locationMode ?? this.locationMode,
    specifiedLocation: specifiedLocation ?? this.specifiedLocation,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    proximityScope: proximityScope ?? this.proximityScope,
    miles: miles ?? this.miles,
  );

  Map<String, dynamic> toMap() => {
    'eventTypeIds': eventTypeIds,
    // Keep the old key populated for saved settings/documents that still
    // read a single event type.
    'eventTypeId': eventTypeIds.isEmpty ? null : eventTypeIds.first,
    'locationMode': locationMode.name,
    'specifiedLocation': specifiedLocation?.toMap(),
    'startDate': DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toUtc().toIso8601String(),
    'endDate': DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).toUtc().toIso8601String(),
    'proximityScope': proximityScope.name,
    'miles': miles,
  };

  factory SearchSettings.fromMap(Map<String, dynamic> m) => SearchSettings(
    eventTypeIds: _eventTypeIdsFromMap(m),
    locationMode: LocationMode.values.firstWhere(
      (e) => e.name == m['locationMode'],
      orElse: () => LocationMode.current,
    ),
    specifiedLocation: m['specifiedLocation'] == null
        ? null
        : SpecifiedLocation.fromMap(
            Map<String, dynamic>.from(m['specifiedLocation']),
          ),
    startDate: DateTime.parse(m['startDate']).toLocal(),
    endDate: DateTime.parse(m['endDate']).toLocal(),
    proximityScope: ProximityScope.values.firstWhere(
      (p) => p.name == (m['proximityScope'] ?? 'miles'),
      orElse: () => ProximityScope.miles,
    ),
    miles: m['miles'] ?? 20,
  );

  static List<String> _eventTypeIdsFromMap(Map<String, dynamic> m) {
    final storedIds = m['eventTypeIds'];
    if (storedIds is Iterable) {
      final ids = storedIds.whereType<String>().toList(growable: false);
      if (ids.isNotEmpty) return ids;
    }

    final storedId = m['eventTypeId'];
    if (storedId is String && storedId.isNotEmpty) return [storedId];

    return const ['openMicJam'];
  }
}
