import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_models.dart';
// import '../models/location_models.dart';
import 'package:flutter/foundation.dart';
import '../../models/settings_models.dart';
// === Enums for location and event type ===
// enum LocationMode { current, specified }

// enum SpecifiedLocationKind { postcode, latlng, threeWords }

// === Specified location class ===
@immutable
class SpecifiedLocation {
  final SpecifiedLocationKind kind;
  final String value;

  const SpecifiedLocation({required this.kind, required this.value});
}

// === Search settings ===
@immutable
class SearchSettings {
  final EventType eventType;
  final DateTime startDate;
  final LocationMode locationMode;
  final SpecifiedLocation? specifiedLocation;

  const SearchSettings({
    this.eventType = EventType.gig,
    required this.startDate,
    this.locationMode = LocationMode.current,
    this.specifiedLocation,
  });

  SearchSettings copyWith({
    EventType? eventType,
    DateTime? startDate,
    LocationMode? locationMode,
    SpecifiedLocation? specifiedLocation,
  }) {
    return SearchSettings(
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate,
      locationMode: locationMode ?? this.locationMode,
      specifiedLocation: specifiedLocation ?? this.specifiedLocation,
    );
  }
}

// === StateNotifier to update settings ===
class SearchSettingsNotifier extends StateNotifier<SearchSettings> {
  SearchSettingsNotifier(SearchSettings initialState) : super(initialState);

  void setEventType(EventType type) {
    state = state.copyWith(eventType: type);
  }

  // other setters...

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void setLocationMode(LocationMode mode, {SpecifiedLocation? specified}) {
    state = state.copyWith(
      locationMode: mode,
      specifiedLocation: specified,
    );
  }

  void setSpecifiedLocation(SpecifiedLocation loc) {
    state = state.copyWith(specifiedLocation: loc);
  }
}

// === Provider ===
final searchSettingsProvider =
    StateNotifierProvider<SearchSettingsNotifier, SearchSettings>((ref) {
  return SearchSettingsNotifier(
    SearchSettings(
      eventType: EventType.openMicJam, // <-- default to Open Mic Jam
      locationMode: LocationMode.current,
      startDate: DateTime.now(),
    ),
  );
});
