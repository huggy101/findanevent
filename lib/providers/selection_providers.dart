import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/event_models.dart';
import '../models/settings_models.dart'; // <-- contains LocationMode, SpecifiedLocation, ProximityScope, SearchSettings

// === StateNotifier to update settings ===
class SearchSettingsNotifier extends StateNotifier<SearchSettings> {
  SearchSettingsNotifier(SearchSettings initialState) : super(initialState);

  void setEventType(EventType type) {
    state = state.copyWith(eventType: type);
  }

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

  // === New setters for Proximity ===
  void setProximityScope(ProximityScope scope) {
    state = state.copyWith(proximityScope: scope);
  }

  void setMiles(int miles) {
    state = state.copyWith(
      miles: miles,
      proximityScope: ProximityScope.miles, // force miles mode
    );
  }
}

// === Provider ===
final searchSettingsProvider =
    StateNotifierProvider<SearchSettingsNotifier, SearchSettings>((ref) {
  return SearchSettingsNotifier(
    SearchSettings(
      eventType: EventType.openMicJam, // default event type
      locationMode: LocationMode.current,
      startDate: DateTime.now(),
      proximityScope: ProximityScope.miles, // default scope
      miles: 20, // default miles
    ),
  );
});
