import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/selection_providers.dart';
import '../../providers/event_type_providers.dart';

class SelectEventTypeScreen extends ConsumerWidget {
  const SelectEventTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Event Type')),
      body: eventTypesAsync.when(
        data: (types) {
          return ListView(
            children: [
              // ✅ In the future you can add a "Select All" checkbox here
              // CheckboxListTile(
              //   title: const Text("All Event Types"),
              //   value: settings.eventTypeIds.isEmpty,
              //   onChanged: (val) {
              //     ref.read(searchSettingsProvider.notifier).setEventTypes([]);
              //     Navigator.pop(context);
              //   },
              // ),
              ...types.map((t) {
                final isSelected = settings.eventTypeId == t.id;
                return RadioListTile<String>(
                  title: Text(t.label),
                  value: t.id,
                  groupValue: settings.eventTypeId,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(searchSettingsProvider.notifier).setEventType(v);
                      Navigator.of(context).pop();
                    }
                  },
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading event types: $e')),
      ),
    );
  }
}
