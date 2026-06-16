import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How To Use The App')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _InstructionSection(
              title: 'Finding Events',
              body:
                  'On the welcome screen choose the event type or types you want to find. You can select one or several types, then return to the welcome screen.',
            ),
            _InstructionSection(
              title: 'Location',
              body:
                  'Use the location button to search from your current location or from a specified postcode, plus code, or what3words location.',
            ),
            _InstructionSection(
              title: 'Proximity',
              body:
                  'Use the proximity button to choose how far away events can be. If you choose a miles radius, the event list filters venues by distance from your selected location.',
            ),
            _InstructionSection(
              title: 'Date Range',
              body:
                  'Use the date range button to set the from and to dates. The event list then looks for matching random, weekly, fortnightly, and monthly event dates inside that range.',
            ),
            _InstructionSection(
              title: 'Adding A Venue',
              body:
                  'Use Add Venue before adding an event if the venue is not already in the database. Enter the venue postcode and name, then add the address, contacts, parking, website, and any other useful venue details.',
            ),
            _InstructionSection(
              title: 'Adding An Event',
              body:
                  'Use Add An Event to create an event. Search for the venue by postcode and name, then select the venue. After a venue is selected, complete the event type, host details, frequency, dates, provided equipment, and comments.',
            ),
            _InstructionSection(
              title: 'Event Frequency',
              body:
                  'Random events use individual dates and times. Weekly and fortnightly events use a day of the week and start time. Monthly events use 1st, 2nd, 3rd, 4th, or Last plus a day of the week and start time. Fortnightly events need a start date, while other recurring start dates and all end dates are optional. Exception dates can be added for dates when the event is not happening.',
            ),
            _InstructionSection(
              title: 'Unique Event ID',
              body:
                  'When a new event is created, the app generates a unique event ID. Keep this ID so the event can be loaded again later for amendments. Enter the event ID on the Add An Event screen and press Load to edit the saved event.',
            ),
            _InstructionSection(
              title: 'Searching',
              body:
                  'Press Find The Events on the welcome screen after setting event type, location, proximity, and date range. Matching events are shown in date order with the soonest first.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionSection extends StatelessWidget {
  final String title;
  final String body;

  const _InstructionSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
