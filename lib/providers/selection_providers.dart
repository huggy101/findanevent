import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_models.dart';
import '../models/settings_models.dart';

// === StateNotifier to update settings ===
class SearchSettingsNotifier extends StateNotifier<SearchSettings> {
  SearchSettingsNotifier(SearchSettings initialState) : super(initialState);

  void setEventType(EventType type) {
    state = state.copyWith(eventType: type);
  }

  void setStartDate(DateTime date) {
    // ensure midnight
    final d = DateTime(date.year, date.month, date.day);
    state = state.copyWith(startDate: d);
  }

  void setEndDate(DateTime date) {
    // ensure midnight
    final d = DateTime(date.year, date.month, date.day);
    state = state.copyWith(endDate: d);
  }

  /// Convenience to set both together
  void setDateRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    state = state.copyWith(startDate: s, endDate: e);
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
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 7)); // default to a week ahead

  return SearchSettingsNotifier(
    SearchSettings(
      eventType: EventType.openMicJam,
      locationMode: LocationMode.current,
      startDate: start,
      endDate: end,
      proximityScope: ProximityScope.miles,
      miles: 20,
    ),
  );
});
