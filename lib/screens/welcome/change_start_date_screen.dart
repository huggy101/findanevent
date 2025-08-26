import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/selection_providers.dart';

class ChangeStartDateScreen extends ConsumerWidget {
  const ChangeStartDateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Change start date')),
      body: Center(
        child: ElevatedButton(
          child: Text('Pick date (currently ${settings.startDate.toLocal().toString().split(' ').first})'),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              initialDate: settings.startDate,
            );
            if (picked != null) {
              ref.read(searchSettingsProvider.notifier).setStartDate(DateTime(picked.year, picked.month, picked.day));
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
