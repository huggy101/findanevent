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
            children: types.map((t) {
              final isSelected = settings.eventTypeId == t.id;

              return ListTile(
                title: Text(t.label),
                trailing: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                onTap: () {
                  ref
                      .read(searchSettingsProvider.notifier)
                      .setEventType(t.id);

                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error loading event types: $e'),
        ),
      ),
    );
  }
}