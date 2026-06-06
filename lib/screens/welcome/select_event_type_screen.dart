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
      appBar: AppBar(
        title: const Text('Select Event Types'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: eventTypesAsync.when(
        data: (types) {
          return ListView(
            children: types.map((t) {
              final isSelected = settings.eventTypeIds.contains(t.id);

              return CheckboxListTile(
                title: Text(t.label),
                value: isSelected,
                onChanged: (_) {
                  ref
                      .read(searchSettingsProvider.notifier)
                      .toggleEventType(t.id);
                },
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading event types: $e')),
      ),
    );
  }
}
