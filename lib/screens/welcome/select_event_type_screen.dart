import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_models.dart';
import '../../providers/selection_providers.dart';
import '../../widgets/custom_radio_group.dart';

class SelectEventTypeScreen extends ConsumerWidget {
  const SelectEventTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Event Type')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomRadioGroup<EventType>(
          groupValue: settings.eventType,
          items: const [
            RadioItem(value: EventType.openMic, label: 'Open mic'),
            RadioItem(value: EventType.jam, label: 'Jam'),
            RadioItem(value: EventType.gig, label: 'Gig'),
          ],
          onChanged: (v) =>
              ref.read(searchSettingsProvider.notifier).setEventType(v),
        ),
      ),
    );
  }
}
