import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_models.dart';

/// === StateNotifier to manage search settings ===
class SearchSettingsNotifier extends StateNotifier<SearchSettings> {
  SearchSettingsNotifier(super.initialState);

  void setEventTypes(List<String> typeIds) {
    state = state.copyWith(eventTypeIds: List.unmodifiable(typeIds));
  }

  void toggleEventType(String typeId) {
    final next = [...state.eventTypeIds];
    if (next.contains(typeId)) {
      next.remove(typeId);
    } else {
      next.add(typeId);
    }
    state = state.copyWith(eventTypeIds: List.unmodifiable(next));
  }

  void setStartDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    state = state.copyWith(startDate: d);
  }

  void setEndDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    state = state.copyWith(endDate: d);
  }

  void setDateRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    state = state.copyWith(startDate: s, endDate: e);
  }

  void setLocationMode(LocationMode mode, {SpecifiedLocation? specified}) {
    state = state.copyWith(locationMode: mode, specifiedLocation: specified);
  }

  void setSpecifiedLocation(SpecifiedLocation loc) {
    state = state.copyWith(specifiedLocation: loc);
  }

  void setProximityScope(ProximityScope scope) {
    state = state.copyWith(proximityScope: scope);
  }

  void setMiles(int miles) {
    state = state.copyWith(miles: miles, proximityScope: ProximityScope.miles);
  }
}

/// === Provider ===
final searchSettingsProvider =
    StateNotifierProvider<SearchSettingsNotifier, SearchSettings>((ref) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 7));

      final initialState = SearchSettings(
        eventTypeIds: const ['openMicJam'], // default Firestore ID
        locationMode: LocationMode.current,
        startDate: start,
        endDate: end,
        proximityScope: ProximityScope.miles,
        miles: 20,
      );

      return SearchSettingsNotifier(initialState);
    });
