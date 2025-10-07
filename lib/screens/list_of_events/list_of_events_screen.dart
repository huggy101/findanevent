import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/selection_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/app_providers.dart';
import '../../widgets/event_card.dart';
import '../../models/settings_models.dart';
import '../../providers/event_type_providers.dart';
import '../../models/event_models.dart';

class ListOfEventsScreen extends ConsumerWidget {
  const ListOfEventsScreen({super.key});

  // Compute a distance label for an event
  Future<String> _distanceLabel(
    WidgetRef ref,
    (double, double) origin,
    (double, double) dest,
  ) async {
    final distance = await ref
        .read(distanceServiceProvider)
        .drivingDistanceMeters(origin, dest);
    if (distance != null) return '${(distance / 1000).toStringAsFixed(1)} km';

    // fallback to haversine if driving distance fails
    final km = ref
        .read(distanceServiceProvider)
        .haversineKm(origin.$1, origin.$2, dest.$1, dest.$2);
    return '${km.toStringAsFixed(1)} km';
  }

  // Determine origin coordinates based on user settings
  Future<(double, double)> _origin(WidgetRef ref) async {
    final settings = ref.read(searchSettingsProvider);

    if (settings.locationMode == LocationMode.current) {
      final pos = await ref.read(geoServiceProvider).currentPosition();
      return (pos.latitude, pos.longitude);
    } else {
      final s = settings.specifiedLocation!;
      switch (s.kind) {
        case SpecifiedLocationKind.postcode:
          return await ref.read(geoServiceProvider).geocodePostcode(s.value);
        case SpecifiedLocationKind.plusCode:
          return await ref.read(geoServiceProvider).geocodePlusCode(s.value);
        case SpecifiedLocationKind.threeWords:
          return await ref.read(w3wServiceProvider).toCoords(s.value);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsQueryProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: eventsAsync.when(
        data: (rows) => FutureBuilder<(double, double)>(
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
                        order: 999, // 👈 fallback order so code compiles
                      ),
                    );

                    return FutureBuilder<String>(
                      future: _distanceLabel(ref, origin, (venue.lat, venue.lng)),
                      builder: (context, distSnap) {
                        final distance = distSnap.data ?? '';
                        return EventCard(
                          event: event,
                          venue: venue,
                          distanceLabel: distance,
                          eventTypeLabel: typeModel.label,
                        );
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading types: $err')),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading events: $err')),
      ),
    );
  }
}
