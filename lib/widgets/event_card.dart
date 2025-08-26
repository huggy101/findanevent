import 'package:flutter/material.dart';
import '../models/event_models.dart';

class EventCard extends StatelessWidget {
  final EventItem event;
  final Venue venue;
  final String distanceLabel;

  const EventCard({
    super.key,
    required this.event,
    required this.venue,
    required this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(venue.name),
        subtitle: Text(
          '${event.type.label} • ${event.start.toLocal()} • $distanceLabel away',
        ),
        leading: const Icon(Icons.location_on),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
