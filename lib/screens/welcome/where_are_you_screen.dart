import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/settings_models.dart' as models;
import '../../providers/selection_providers.dart' as prov;
import '../../core/validators.dart';

class WhereAreYouScreen extends ConsumerStatefulWidget {
  const WhereAreYouScreen({super.key});

  @override
  ConsumerState<WhereAreYouScreen> createState() => _WhereAreYouScreenState();
}

class _WhereAreYouScreenState extends ConsumerState<WhereAreYouScreen> {
  late models.LocationMode _mode;
  models.SpecifiedLocationKind _kind = models.SpecifiedLocationKind.postcode;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(prov.searchSettingsProvider);
    _mode = settings.locationMode;
    if (settings.specifiedLocation != null) {
      _kind = settings.specifiedLocation!.kind;
      _ctrl.text = settings.specifiedLocation!.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
            ),
            RadioListTile<models.LocationMode>(
              title: const Text('Specify Location'),
              value: models.LocationMode.specified,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
            ),
            if (_mode == models.LocationMode.specified) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Postcode'),
                    selected: _kind == models.SpecifiedLocationKind.postcode,
                    onSelected: (_) => setState(
                        () => _kind = models.SpecifiedLocationKind.postcode),
                  ),
                  ChoiceChip(
                    label: const Text('Plus Code'),
                    selected: _kind == models.SpecifiedLocationKind.plusCode,
                    onSelected: (_) => setState(
                        () => _kind = models.SpecifiedLocationKind.plusCode),
                  ),
                  ChoiceChip(
                    label: const Text('///three.words'),
                    selected: _kind == models.SpecifiedLocationKind.threeWords,
                    onSelected: (_) => setState(
                        () => _kind = models.SpecifiedLocationKind.threeWords),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  labelText: switch (_kind) {
                    models.SpecifiedLocationKind.postcode =>
                      'Enter UK postcode',
                    models.SpecifiedLocationKind.plusCode =>
                      'Enter Google Plus Code (e.g., 9C4WQ9MQ+77)',
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
                final notifier = ref.read(prov.searchSettingsProvider.notifier);

                if (_mode == models.LocationMode.current) {
                  notifier.setLocationMode(models.LocationMode.current);
                } else {
                  final value = _ctrl.text.trim();

                  switch (_kind) {
                    case models.SpecifiedLocationKind.postcode:
                      if (!Validators.isPostcode(value)) {
                        _show(context, 'Please enter a valid UK postcode');
                        return;
                      }
                      break;
                    case models.SpecifiedLocationKind.plusCode:
                      if (!Validators.isPlusCode(value)) {
                        _show(context, 'Please enter a valid Plus Code');
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

                  notifier.setLocationMode(
                    models.LocationMode.specified,
                    specified: models.SpecifiedLocation(_kind, value),
                  );
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

  void _show(BuildContext c, String message) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(message)));
}
