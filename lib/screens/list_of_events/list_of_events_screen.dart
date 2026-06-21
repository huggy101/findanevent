import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event_models.dart';
import '../../models/settings_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/event_type_providers.dart';
import '../../providers/selection_providers.dart';
import '../../widgets/event_card.dart';
import '../../widgets/search_settings_buttons.dart';

class ListOfEventsScreen extends ConsumerStatefulWidget {
  const ListOfEventsScreen({super.key});

  @override
  ConsumerState<ListOfEventsScreen> createState() => _ListOfEventsScreenState();
}

class _ListOfEventsScreenState extends ConsumerState<ListOfEventsScreen> {
  bool _showSettings = false;

  String _distanceLabel(
    WidgetRef ref,
    (double, double) origin,
    (double, double) dest,
  ) {
    final miles = ref
        .read(distanceServiceProvider)
        .haversineMiles(origin.$1, origin.$2, dest.$1, dest.$2);
    return '${miles.toStringAsFixed(1)} straight line miles';
  }

  Future<(double, double)> _origin(WidgetRef ref) async {
    final settings = ref.read(searchSettingsProvider);

    if (settings.locationMode == LocationMode.current) {
      final pos = await ref.read(geoServiceProvider).currentPosition();
      return (pos.latitude, pos.longitude);
    }

    final specified = settings.specifiedLocation;
    if (specified == null) {
      final pos = await ref.read(geoServiceProvider).currentPosition();
      return (pos.latitude, pos.longitude);
    }

    switch (specified.kind) {
      case SpecifiedLocationKind.postcode:
        return ref.read(geoServiceProvider).geocodePostcode(specified.value);
      case SpecifiedLocationKind.plusCode:
        return ref.read(geoServiceProvider).geocodePlusCode(specified.value);
      case SpecifiedLocationKind.threeWords:
        return ref.read(w3wServiceProvider).toCoords(specified.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsQueryProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            onPressed: () => setState(
              () => _showSettings = !_showSettings,
            ),
            tooltip: _showSettings ? 'Hide Search Settings' : 'Search Settings',
            icon: Icon(
              _showSettings ? Icons.expand_less : Icons.settings,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSettings)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchSettingsButtons(spacing: 8),
            ),
          Expanded(
            child: eventsAsync.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(child: Text('No matching events found.'));
                }

                return FutureBuilder<(double, double)>(
                  future: _origin(ref),
                  builder: (context, originSnap) {
                    if (!originSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final origin = originSnap.data!;

                    return eventTypesAsync.when(
                      data: (types) {
                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final tuple = rows[index];
                            final event = tuple.$1;
                            final venue = tuple.$2;

                            final typeModel = types.firstWhere(
                              (t) => t.id == event.typeId,
                              orElse: () => EventTypeModel(
                                id: event.typeId,
                                label: event.typeId,
                                order: 999,
                              ),
                            );

                            return EventCard(
                              event: event,
                              venue: venue,
                              distanceLabel: _distanceLabel(
                                ref,
                                origin,
                                (venue.lat, venue.lng),
                              ),
                              eventTypeLabel: typeModel.label,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Center(child: Text('Error loading types: $err')),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading events: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
