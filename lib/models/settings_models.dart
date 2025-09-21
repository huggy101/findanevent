import 'package:intl/intl.dart';

enum LocationMode { current, specified }

/// ✅ changed "latlng" -> "plusCode"
enum SpecifiedLocationKind { postcode, plusCode, threeWords }

enum ProximityScope { miles, nationwide, worldwide }

class SpecifiedLocation {
  final SpecifiedLocationKind kind;
  final String value;

  const SpecifiedLocation(this.kind, this.value);

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'value': value,
      };

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
  /// 🔑 Firestore ID of the event type (from `eventTypes` collection)
  final String eventTypeId;

  final LocationMode locationMode;
  final SpecifiedLocation? specifiedLocation;

  /// start and end dates (at midnight)
  final DateTime startDate;
  final DateTime endDate;

  // proximity
  final ProximityScope proximityScope;
  final int miles;

  const SearchSettings({
    required this.eventTypeId,
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
    final weekday = DateFormat('EEEE').format(d); // e.g. Monday
    final monthShort = DateFormat('MMM').format(d); // e.g. Sep
    return '$weekday ${day}$suffix $monthShort ${d.year}';
  }

  /// Human friendly single-date label (start)
  String startLabel() => _formatWithOrdinal(startDate);

  /// Date range label, e.g. "Mon 1st Sep 2025 → Mon 8th Sep 2025"
  String rangeLabel() =>
      '${_formatWithOrdinal(startDate)} → ${_formatWithOrdinal(endDate)}';

  SearchSettings copyWith({
    String? eventTypeId,
    LocationMode? locationMode,
    SpecifiedLocation? specifiedLocation,
    DateTime? startDate,
    DateTime? endDate,
    ProximityScope? proximityScope,
    int? miles,
  }) =>
      SearchSettings(
        eventTypeId: eventTypeId ?? this.eventTypeId,
        locationMode: locationMode ?? this.locationMode,
        specifiedLocation: specifiedLocation ?? this.specifiedLocation,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        proximityScope: proximityScope ?? this.proximityScope,
        miles: miles ?? this.miles,
      );

  Map<String, dynamic> toMap() => {
        'eventTypeId': eventTypeId,
        'locationMode': locationMode.name,
        'specifiedLocation': specifiedLocation?.toMap(),
        'startDate': DateTime(startDate.year, startDate.month, startDate.day)
            .toUtc()
            .toIso8601String(),
        'endDate': DateTime(endDate.year, endDate.month, endDate.day)
            .toUtc()
            .toIso8601String(),
        'proximityScope': proximityScope.name,
        'miles': miles,
      };

  factory SearchSettings.fromMap(Map<String, dynamic> m) => SearchSettings(
        eventTypeId: m['eventTypeId'] as String? ??
            'openMicJam', // fallback if not set
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
}
