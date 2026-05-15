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
          if (types.isEmpty) {
            return const Center(child: Text('No event types available.'));
          }

          return ListView.separated(
            itemCount: types.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = types[index];
              return RadioListTile<String>(
                key: ValueKey(t.id),
                title: Text(t.label),
                value: t.id,
                groupValue: settings.eventTypeId,
                selected: settings.eventTypeId == t.id,
                onChanged: (v) {
                  if (v == null) return;
                  debugPrint('SelectEventType: tapped value=$v available=${types.map((e) => e.id).toList()}');
                  try {
                    ref.read(searchSettingsProvider.notifier).setEventType(v);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (err, st) {
                    debugPrint('setEventType error: $err\n$st');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to set event type'))
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Error loading event types'),
              const SizedBox(height: 8),
              Text(e.toString()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(eventTypesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
