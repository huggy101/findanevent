import 'package:intl/intl.dart';
import 'event_models.dart';

enum LocationMode { current, specified }

/// ✅ changed "latlng" -> "plusCode"
enum SpecifiedLocationKind { postcode, plusCode, threeWords }

enum ProximityScope { miles, nationwide, worldwide }

class SpecifiedLocation {
  final SpecifiedLocationKind kind;
  final String value;

  SpecifiedLocation(this.kind, this.value);
}

class SearchSettings {
  final EventType eventType;
  final LocationMode locationMode;
  final SpecifiedLocation? specifiedLocation;

  /// start and end dates (at midnight)
  final DateTime startDate;
  final DateTime endDate;

  // proximity
  final ProximityScope proximityScope;
  final int miles;

  const SearchSettings({
    required this.eventType,
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
        : (() {
            switch (day % 10) {
              case 1:
                return 'st';
              case 2:
                return 'nd';
              case 3:
                return 'rd';
              default:
                return 'th';
            }
          })();
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
    EventType? eventType,
    LocationMode? locationMode,
    SpecifiedLocation? specifiedLocation,
    DateTime? startDate,
    DateTime? endDate,
    ProximityScope? proximityScope,
    int? miles,
  }) =>
      SearchSettings(
        eventType: eventType ?? this.eventType,
        locationMode: locationMode ?? this.locationMode,
        specifiedLocation: specifiedLocation ?? this.specifiedLocation,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        proximityScope: proximityScope ?? this.proximityScope,
        miles: miles ?? this.miles,
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
        eventType: EventType.values.firstWhere(
          (e) => e.name == m['eventType'],
          orElse: () => EventType.openMicJam,
        ),
        locationMode: LocationMode.values.firstWhere(
          (e) => e.name == m['locationMode'],
          orElse: () => LocationMode.current,
        ),
        specifiedLocation: m['specifiedLocation'] == null
            ? null
            : SpecifiedLocation(
                SpecifiedLocationKind.values.firstWhere(
                  (k) => k.name == m['specifiedLocation']['kind'],
                  orElse: () => SpecifiedLocationKind.postcode,
                ),
                m['specifiedLocation']['value'],
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
