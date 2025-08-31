import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/event_models.dart';
import '../../providers/selection_providers.dart';
import '../../widgets/date_label.dart';
import '../../models/settings_models.dart';
import '../../providers/terms_provider.dart'; // 👈 add this

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'FIND A …',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.push('/select'),
              child: Text(settings.eventType.label),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/where'),
                    child: Text(settings.locationMode == LocationMode.current
                        ? 'Current Location'
                        : 'Location Specified'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/change-date'),
                    child: DateLabel(date: settings.startDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/events'),
              child: const Text('Find The Events'),
            ),
            const Spacer(),

            // 👇 Step 4: testing button for Terms & Conditions
            OutlinedButton(
              onPressed: () {
                ref.read(termsAcceptedProvider.notifier).resetForTesting();
                context.push('/terms');
              },
              child: const Text("Force Terms Again (Testing)"),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => context.push('/login'),
              child: const Text(
                'Login/Register – Needed For Updating Events',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
