import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_models.dart';
import '../services/firestore_service.dart';
import 'selection_providers.dart';

/// Provide the FirestoreService instance
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Fetch all event types from Firestore
final eventTypesProvider = FutureProvider<List<EventTypeModel>>((ref) async {
  final fs = ref.read(firestoreServiceProvider);
  return fs.getEventTypes();
});

/// Get the currently selected EventTypeModel based on search settings
final selectedEventTypeProvider = Provider<EventTypeModel?>((ref) {
  final eventTypesAsync = ref.watch(eventTypesProvider);
  final settings = ref.watch(searchSettingsProvider);

  final selectedId = settings.eventTypeId;
  if (selectedId == null) return null;

  return eventTypesAsync.maybeWhen(
    data: (types) {
      final sId = selectedId.toString();
      for (final t in types) {
        if (t.id.toString() == sId) return t;
      }
      return null;
    },
    orElse: () => null,
  );
});

