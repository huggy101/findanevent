import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/selection_providers.dart';
import '../../models/settings_models.dart';

class ProximityScreen extends ConsumerStatefulWidget {
  const ProximityScreen({super.key});

  @override
  ConsumerState<ProximityScreen> createState() => _ProximityScreenState();
}

class _ProximityScreenState extends ConsumerState<ProximityScreen> {
  late ProximityScope _selected;
  late TextEditingController _milesController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(searchSettingsProvider);
    _selected = settings.proximityScope;
    _milesController =
        TextEditingController(text: settings.miles.toString());
  }

  @override
  void dispose() {
    _milesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Proximity Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Miles option
            RadioListTile<ProximityScope>(
              value: ProximityScope.miles,
              groupValue: _selected,
              onChanged: (value) => setState(() => _selected = value!),
              title: Row(
                children: [
                  const Text("Within"),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _milesController,
                      enabled: _selected == ProximityScope.miles,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onTap: () {
                        // auto-select "Miles" if they start typing
                        if (_selected != ProximityScope.miles) {
                          setState(() => _selected = ProximityScope.miles);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text("miles"), // literal suffix outside field
                ],
              ),
            ),

            // Nationwide option
            RadioListTile<ProximityScope>(
              value: ProximityScope.nationwide,
              groupValue: _selected,
              onChanged: (value) => setState(() => _selected = value!),
              title: const Text("Nationwide"),
            ),

            // Worldwide option
            RadioListTile<ProximityScope>(
              value: ProximityScope.worldwide,
              groupValue: _selected,
              onChanged: (value) => setState(() => _selected = value!),
              title: const Text("Worldwide"),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                final notifier = ref.read(searchSettingsProvider.notifier);

                if (_selected == ProximityScope.miles) {
                  final miles = int.tryParse(_milesController.text) ?? 20;
                  notifier.setMiles(miles);
                }

                notifier.setProximityScope(_selected);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
