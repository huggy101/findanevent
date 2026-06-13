import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_models.dart';

class EventCard extends StatelessWidget {
  final EventItem event;
  final Venue venue;
  final String distanceLabel;
  final String eventTypeLabel;

  const EventCard({
    super.key,
    required this.event,
    required this.venue,
    required this.distanceLabel,
    required this.eventTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE d MMM yyyy, HH:mm').format(event.start);
    final distanceText = distanceLabel.isEmpty ? '' : ' - $distanceLabel away';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(venue.name),
        subtitle: Text(
          'ID ${event.id} - $eventTypeLabel - $dateLabel$distanceText',
        ),
        leading: const Icon(Icons.location_on),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
