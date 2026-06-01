import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/settings_models.dart';
import '../../providers/selection_providers.dart';
import '../../providers/terms_provider.dart';
import '../../providers/event_type_providers.dart';

import 'package:flutter/services.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  String _locationLabel(SpecifiedLocation loc) {
    switch (loc.kind) {
      case SpecifiedLocationKind.postcode:
        return 'Postcode: ${loc.value}';
      case SpecifiedLocationKind.plusCode:
        return 'Plus Code: ${loc.value}';
      case SpecifiedLocationKind.threeWords:
        return 'W3W: ///${loc.value}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);
    final selectedEventType = ref.watch(selectedEventTypeProvider);

    String proximityLabel;
    switch (settings.proximityScope) {
      case ProximityScope.miles:
        proximityLabel = "Within ${settings.miles} miles";
        break;
      case ProximityScope.nationwide:
        proximityLabel = "Nationwide";
        break;
      case ProximityScope.worldwide:
        proximityLabel = "Worldwide";
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🌿 MAIN CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      Center(
                        child: Text(
                          'FIND A …',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      OutlinedButton(
                        onPressed: () => context.push('/select'),
                        child: Text(
                          selectedEventType?.label ?? settings.eventTypeId,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/where'),
                              child: Text(
                                settings.locationMode == LocationMode.current
                                    ? 'Current Location'
                                    : settings.specifiedLocation != null
                                    ? _locationLabel(
                                        settings.specifiedLocation!,
                                      )
                                    : 'Location Specified',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => context.push('/proximity'),
                            child: Text(proximityLabel),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/change-date'),
                          child: Text(settings.rangeLabel()),
                        ),
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: () => context.push('/events'),
                        child: const Text('Find The Events'),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          ref
                              .read(termsAcceptedProvider.notifier)
                              .resetForTesting();
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
                ],
              ),
            ),

            // 🌙 CLOSE BUTTON (top-right)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
