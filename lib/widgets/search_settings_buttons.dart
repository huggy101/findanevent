import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/event_models.dart';
import '../models/settings_models.dart';
import '../providers/event_type_providers.dart';
import '../providers/selection_providers.dart';

class SearchSettingsButtons extends ConsumerWidget {
  final double spacing;

  const SearchSettingsButtons({
    super.key,
    this.spacing = 12,
  });

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

    final locationLabel = settings.locationMode == LocationMode.current
        ? 'Current Location'
        : settings.specifiedLocation != null
            ? _locationLabel(settings.specifiedLocation!)
            : 'Location Specified';

    final proximityLabel = switch (settings.proximityScope) {
      ProximityScope.miles => 'Within ${settings.miles} miles',
      ProximityScope.nationwide => 'Nationwide',
      ProximityScope.worldwide => 'Worldwide',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => context.push('/select'),
          child: Text(eventTypesLabel),
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/where'),
                child: Text(locationLabel),
              ),
            ),
            SizedBox(width: spacing),
            OutlinedButton(
              onPressed: () => context.push('/proximity'),
              child: Text(proximityLabel),
            ),
          ],
        ),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/change-date'),
            child: Text(settings.rangeLabel()),
          ),
        ),
      ],
    );
  }

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
}
