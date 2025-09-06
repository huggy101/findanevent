import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/selection_providers.dart';

class ChangeStartDateScreen extends ConsumerStatefulWidget {
  const ChangeStartDateScreen({super.key});

  @override
  ConsumerState<ChangeStartDateScreen> createState() =>
      _ChangeStartDateScreenState();
}

class _ChangeStartDateScreenState extends ConsumerState<ChangeStartDateScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDateRangePicker());
  }

  Future<void> _openDateRangePicker() async {
    final settings = ref.read(searchSettingsProvider);
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: settings.startDate,
        end: settings.endDate,
      ),
    );

    if (picked != null) {
      ref.read(searchSettingsProvider.notifier)
        ..setStartDate(DateTime(picked.start.year, picked.start.month, picked.start.day))
        ..setEndDate(DateTime(picked.end.year, picked.end.month, picked.end.day));
    }

    if (!mounted) return;

    // Fade out before popping
    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 200),
      child: const Scaffold(
        backgroundColor: Colors.white, // smooth fade background
      ),
    );
  }
}
