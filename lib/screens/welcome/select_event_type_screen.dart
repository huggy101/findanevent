import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../models/event_models.dart';
import '../../providers/selection_providers.dart';
import '../../widgets/custom_radio_group.dart';
import '../../providers/event_type_providers.dart';

class SelectEventTypeScreen extends ConsumerWidget {
  const SelectEventTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);

    // Fetch the list of EventTypeModels from a provider or repository
    final eventTypes = ref.watch(
      eventTypesProvider,
    ); // assume you have a FutureProvider<List<EventTypeModel>>

    return Scaffold(
      appBar: AppBar(title: const Text('Select Event Type')),
      body: eventTypes.when(
        data: (types) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: CustomRadioGroup<String>(
              groupValue: settings.eventTypeId, // use string ID now
              items: types
                  .map((t) => RadioItem(value: t.id, label: t.label))
                  .toList(),
              onChanged: (v) {
                // if (v != null) {
                ref.read(searchSettingsProvider.notifier).setEventType(v);
                Navigator.of(context).pop();
                // }
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading event types')),
      ),
    );
  }
}
