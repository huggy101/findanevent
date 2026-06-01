import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/settings_models.dart' as models;
import '../../providers/selection_providers.dart' as prov;
import '../../providers/app_providers.dart';
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
  bool _loadingLocation = false;

  // 🌿 NEW: controls Save visibility
  bool _hasCurrentLocation = false;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(prov.searchSettingsProvider);
    _mode = settings.locationMode;

    if (settings.specifiedLocation != null) {
      _kind = settings.specifiedLocation!.kind;
      _ctrl.text = settings.specifiedLocation!.value;
    }

    if (_mode == models.LocationMode.current) {
      _hasCurrentLocation = true;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fillFromCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final geo = ref.read(geoServiceProvider);
      final pos = await geo.currentPosition();
      final lat = pos.latitude;
      final lng = pos.longitude;

      String value;

      switch (_kind) {
        case models.SpecifiedLocationKind.postcode:
          value = await geo.reverseGeocodePostcode(lat, lng);
          break;
        case models.SpecifiedLocationKind.plusCode:
          value = await geo.reverseGeocodePlusCode(lat, lng);
          break;
        case models.SpecifiedLocationKind.threeWords:
          final w3w = ref.read(w3wServiceProvider);
          value = await w3w.fromCoords(lat, lng);
          break;
      }

      if (!mounted) return;

      setState(() {
        _ctrl.text = value;
        _hasCurrentLocation = true; // 🌿 unlock Save
      });
    } catch (e) {
      if (!mounted) return;
      _show(context, 'Could not fetch location: $e');
      // } finally {
      //   if (!mounted) return;
      //   setState(() => _loadingLocation = false);
      // }
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
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
            _buildModeTile(
              title: 'Current Location',
              value: models.LocationMode.current,
            ),
            _buildModeTile(
              title: 'Specify Location',
              value: models.LocationMode.specified,
            ),

            if (_mode == models.LocationMode.specified) ...[
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Postcode'),
                    selected: _kind == models.SpecifiedLocationKind.postcode,
                    onSelected: (_) => setState(() {
                      _kind = models.SpecifiedLocationKind.postcode;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Plus Code'),
                    selected: _kind == models.SpecifiedLocationKind.plusCode,
                    onSelected: (_) => setState(() {
                      _kind = models.SpecifiedLocationKind.plusCode;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('///three.words'),
                    selected: _kind == models.SpecifiedLocationKind.threeWords,
                    onSelected: (_) => setState(() {
                      _kind = models.SpecifiedLocationKind.threeWords;
                    }),
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

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _loadingLocation ? null : _fillFromCurrentLocation,
                  icon: _loadingLocation
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text("Use Current Location"),
                ),
              ),
            ],

            const Spacer(),

            // 🌿 SAVE BUTTON (conditional)
            if (_mode == models.LocationMode.current || _hasCurrentLocation)
              ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(
                    prov.searchSettingsProvider.notifier,
                  );

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

  Widget _buildModeTile({
    required String title,
    required models.LocationMode value,
  }) {
    final selected = _mode == value;

    return ListTile(
      title: Text(title),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      onTap: () {
        setState(() {
          _mode = value;

          if (_mode == models.LocationMode.specified) {
            _hasCurrentLocation = false;
          }
        });
      },
    );
  }

  void _show(BuildContext c, String message) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(message)));
  }
}
