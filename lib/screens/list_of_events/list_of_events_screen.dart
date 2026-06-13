import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event_models.dart';
import '../../models/settings_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/event_type_providers.dart';
import '../../providers/selection_providers.dart';
import '../../widgets/event_card.dart';

class ListOfEventsScreen extends ConsumerWidget {
  const ListOfEventsScreen({super.key});

  Future<String> _distanceLabel(
    WidgetRef ref,
    (double, double) origin,
    (double, double) dest,
  ) async {
    final distance = await ref
        .read(distanceServiceProvider)
        .drivingDistanceMeters(origin, dest);
    if (distance != null) return '${(distance / 1000).toStringAsFixed(1)} km';

    final km = ref
        .read(distanceServiceProvider)
        .haversineKm(origin.$1, origin.$2, dest.$1, dest.$2);
    return '${km.toStringAsFixed(1)} km';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsQueryProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: eventsAsync.when(
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

                      return FutureBuilder<String>(
                        future: _distanceLabel(
                          ref,
                          origin,
                          (venue.lat, venue.lng),
                        ),
                        builder: (context, distSnap) {
                          return EventCard(
                            event: event,
                            venue: venue,
                            distanceLabel: distSnap.data ?? '',
                            eventTypeLabel: typeModel.label,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading types: $err')),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading events: $err')),
      ),
    );
  }
}
