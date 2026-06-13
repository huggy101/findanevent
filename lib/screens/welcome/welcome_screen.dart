import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/event_models.dart';
import '../../models/settings_models.dart';
import '../../providers/event_type_providers.dart';
import '../../providers/selection_providers.dart';
import '../../providers/terms_provider.dart';

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

  String _eventTypesLabel(
    List<EventTypeModel> selectedTypes,
    List<String> selectedIds,
  ) {
    if (selectedTypes.isEmpty && selectedIds.isEmpty) {
      return 'Select Event Types';
    }

    final labels = selectedTypes.isNotEmpty
        ? selectedTypes.map((t) => t.label).toList()
        : selectedIds;

    if (labels.length <= 2) return labels.join(', ');
    return '${labels.take(2).join(', ')} +${labels.length - 2} more';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(searchSettingsProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);
    final selectedEventTypes = ref.watch(selectedEventTypesProvider);
    final eventTypesLabel = eventTypesAsync.maybeWhen(
      loading: () => 'Loading Event Types',
      error: (_, _) => _eventTypesLabel(
        selectedEventTypes,
        settings.eventTypeIds,
      ),
      orElse: () => _eventTypesLabel(
        selectedEventTypes,
        settings.eventTypeIds,
      ),
    );

    final proximityLabel = switch (settings.proximityScope) {
      ProximityScope.miles => 'Within ${settings.miles} miles',
      ProximityScope.nationwide => 'Nationwide',
      ProximityScope.worldwide => 'Worldwide',
    };

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _MainActions(
                              eventTypesLabel: eventTypesLabel,
                              locationLabel:
                                  settings.locationMode == LocationMode.current
                                      ? 'Current Location'
                                      : settings.specifiedLocation != null
                                      ? _locationLabel(
                                          settings.specifiedLocation!,
                                        )
                                      : 'Location Specified',
                              proximityLabel: proximityLabel,
                              dateLabel: settings.rangeLabel(),
                            ),
                            const Spacer(),
                            _BottomActions(ref: ref),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: SystemNavigator.pop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  final String eventTypesLabel;
  final String locationLabel;
  final String proximityLabel;
  final String dateLabel;

  const _MainActions({
    required this.eventTypesLabel,
    required this.locationLabel,
    required this.proximityLabel,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Text(
            'FIND A ...',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.push('/select'),
          child: Text(eventTypesLabel),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/where'),
                child: Text(locationLabel),
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
            child: Text(dateLabel),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/add-venue'),
                icon: const Icon(Icons.add_business),
                label: const Text('Add Venue'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/add-event'),
                icon: const Icon(Icons.event),
                label: const Text('Add An Event'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => context.push('/events'),
          child: const Text('Find The Events'),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final WidgetRef ref;

  const _BottomActions({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/instructions'),
          icon: const Icon(Icons.help_outline),
          label: const Text('How To Use The App'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            ref.read(termsAcceptedProvider.notifier).resetForTesting();
            context.push('/terms');
          },
          child: const Text('Force Terms Again (Testing)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/login'),
          child: const Text('Login/Register - Needed For Updating Events'),
        ),
      ],
    );
  }
}
