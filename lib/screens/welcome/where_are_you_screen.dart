import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Prefix imports to avoid conflicts
import '../../models/settings_models.dart' as models;
import '../../providers/selection_providers.dart' as prov;
import '../../core/validators.dart';

class WhereAreYouScreen extends ConsumerStatefulWidget {
  const WhereAreYouScreen({super.key});

  @override
  ConsumerState createState() => _WhereAreYouScreenState();
}

class _WhereAreYouScreenState extends ConsumerState<WhereAreYouScreen> {
  models.LocationMode mode = models.LocationMode.current;
  models.SpecifiedLocationKind kind = models.SpecifiedLocationKind.postcode;
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(prov.searchSettingsProvider);
    mode = settings.locationMode; // initialize from state

    return Scaffold(
      appBar: AppBar(title: const Text('Where are you?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<models.LocationMode>(
              title: const Text('Current Location'),
              value: models.LocationMode.current,
              groupValue: mode,
              onChanged: (v) => setState(() => mode = v!),
            ),
            RadioListTile<models.LocationMode>(
              title: const Text('Specify Location'),
              value: models.LocationMode.specified,
              groupValue: mode,
              onChanged: (v) => setState(() => mode = v!),
            ),
            if (mode == models.LocationMode.specified) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Postcode'),
                    selected: kind == models.SpecifiedLocationKind.postcode,
                    onSelected: (_) => setState(
                        () => kind = models.SpecifiedLocationKind.postcode),
                  ),
                  ChoiceChip(
                    label: const Text('Lat/Lng'),
                    selected: kind == models.SpecifiedLocationKind.latlng,
                    onSelected: (_) =>
                        setState(() => kind = models.SpecifiedLocationKind.latlng),
                  ),
                  ChoiceChip(
                    label: const Text('///three.words'),
                    selected: kind == models.SpecifiedLocationKind.threeWords,
                    onSelected: (_) => setState(
                        () => kind = models.SpecifiedLocationKind.threeWords),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: switch (kind) {
                    models.SpecifiedLocationKind.postcode =>
                      'Enter UK postcode',
                    models.SpecifiedLocationKind.latlng =>
                      'Enter lat,lng (e.g., 51.5072,-0.1276)',
                    models.SpecifiedLocationKind.threeWords =>
                      'Enter what3words (e.g., index.home.raft)',
                  },
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (mode == models.LocationMode.current) {
                  ref
                      .read(prov.searchSettingsProvider.notifier)
                      .setLocationMode(models.LocationMode.current);
                } else {
                  final value = ctrl.text.trim();

                  // Minimal validation
                  switch (kind) {
                    case models.SpecifiedLocationKind.postcode:
                      if (!Validators.isPostcode(value)) {
                        _show(context, 'Please enter a valid UK postcode');
                        return;
                      }
                      break;
                    case models.SpecifiedLocationKind.latlng:
                      if (!RegExp(r'^-?\d+(\.\d+)?,-?\d+(\.\d+)?$')
                          .hasMatch(value)) {
                        _show(context, 'Please enter lat,lng');
                        return;
                      }
                      break;
                    case models.SpecifiedLocationKind.threeWords:
                      if (!Validators.isThreeWords(value)) {
                        _show(context, 'Enter three.words.address');
                        return;
                      }
                      break;
                  }

                  // Call notifier with the correct specified parameter
                  // ref
                  //     .read(prov.searchSettingsProvider.notifier)
                  //     .setLocationMode(
                  //       models.LocationMode.specified,
                  //       specified: prov.SpecifiedLocation(kind, value),
                  //      );
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
}
