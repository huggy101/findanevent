import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators.dart';
import '../../models/event_models.dart';
import '../../providers/app_providers.dart';

class AddVenueScreen extends ConsumerStatefulWidget {
  const AddVenueScreen({super.key});

  @override
  ConsumerState<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends ConsumerState<AddVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _venueContactCtrl = TextEditingController();
  final _venuePhoneCtrl = TextEditingController();
  final _eventContactCtrl = TextEditingController();
  final _eventPhoneCtrl = TextEditingController();
  final _plusCodeCtrl = TextEditingController();
  // what3words disabled for venue entry.
  // final _what3WordsCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  final _parkingOptions = const [
    'Own car park',
    'Free on-street',
    'Charged on-street',
    'Charged car park',
  ];

  final Set<String> _selectedParking = {};
  List<Venue> _existingVenues = const [];
  bool _loadingExisting = true;
  bool _loadingLocation = false;
  bool _saving = false;
  bool _fillingFromVenue = false;
  Venue? _matchedVenue;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _postcodeCtrl.addListener(_syncMatchedVenue);
    _nameCtrl.addListener(_syncMatchedVenue);
    _loadExistingVenues();
  }

  @override
  void dispose() {
    _postcodeCtrl.removeListener(_syncMatchedVenue);
    _nameCtrl.removeListener(_syncMatchedVenue);
    _postcodeCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _venueContactCtrl.dispose();
    _venuePhoneCtrl.dispose();
    _eventContactCtrl.dispose();
    _eventPhoneCtrl.dispose();
    _plusCodeCtrl.dispose();
    // _what3WordsCtrl.dispose();
    _socialCtrl.dispose();
    _photoCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingVenues() async {
    try {
      final venues = await ref.read(firestoreServiceProvider).getVenues();
      if (!mounted) return;
      setState(() => _existingVenues = venues);
    } catch (e) {
      if (!mounted) return;
      _show('Could not load existing venues: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingExisting = false);
        _syncMatchedVenue();
      }
    }
  }

  Future<void> _fillPostcodeFromCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final geo = ref.read(geoServiceProvider);
      final pos = await geo.currentPosition();
      final lat = pos.latitude;
      final lng = pos.longitude;
      final postcode = await geo.reverseGeocodePostcode(lat, lng);
      // what3words disabled for venue entry.
      // final what3Words = await ref
      //     .read(w3wServiceProvider)
      //     .fromCoords(lat, lng);

      if (!mounted) return;
      _fillingFromVenue = true;
      setState(() {
        _lat = lat;
        _lng = lng;
        _postcodeCtrl.text = postcode;
        // _what3WordsCtrl.text = what3Words;
      });
      _fillingFromVenue = false;
      _syncMatchedVenue();
    } catch (e) {
      if (!mounted) return;
      _show('Could not fill current position defaults: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _loadingExisting) return;
    if (!_formKey.currentState!.validate()) return;

    final postcode = _normalise(_postcodeCtrl.text);
    final name = _nameCtrl.text.trim();

    final duplicate = _existingVenues.any(
      (v) =>
          v.id != _matchedVenue?.id &&
          _normalise(v.postcode) == postcode &&
          _normalise(v.name) == _normalise(name),
    );
    if (duplicate) {
      _show('A venue with this postcode and name already exists.');
      return;
    }

    setState(() => _saving = true);
    try {
      var lat = _lat;
      var lng = _lng;
      if (lat == null || lng == null) {
        final coords = await ref
            .read(geoServiceProvider)
            .geocodePostcode(postcode);
        lat = coords.$1;
        lng = coords.$2;
      }

      final venue = Venue(
        id: _matchedVenue?.id ?? '',
        name: name,
        postcode: postcode,
        lat: lat,
        lng: lng,
        // what3words disabled for venue entry.
        what3words: _matchedVenue?.what3words ?? '',
        description: _descriptionCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        venueContactName: _venueContactCtrl.text.trim(),
        venuePhoneNumber: _venuePhoneCtrl.text.trim(),
        eventContactName: _eventContactCtrl.text.trim(),
        eventContactNumber: _eventPhoneCtrl.text.trim(),
        plusCode: _plusCodeCtrl.text.trim(),
        parkingDetails: _selectedParking.toList(growable: false),
        socialMediaDetails: _socialCtrl.text.trim(),
        photoUrl: _photoCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
      );

      final firestore = ref.read(firestoreServiceProvider);
      if (_matchedVenue == null) {
        final docRef = await firestore.addVenue(venue);

        if (!mounted) return;
        await _showDialogMessage(
          title: 'Venue added',
          message: 'Saved to venues/${docRef.id}.',
        );
      } else {
        await firestore.updateVenue(venue);

        if (!mounted) return;
        await _showDialogMessage(
          title: 'Venue updated',
          message: 'Updated venues/${venue.id}.',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await _showDialogMessage(
        title: _matchedVenue == null
            ? 'Could not add venue'
            : 'Could not update venue',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();

  String _firstSixLetters(String value) {
    final letters = value.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return letters.length <= 6 ? letters : letters.substring(0, 6);
  }

  void _syncMatchedVenue() {
    if (_fillingFromVenue || _loadingExisting) return;

    final postcode = _normalise(_postcodeCtrl.text);
    final namePrefix = _firstSixLetters(_nameCtrl.text);
    Venue? match;

    if (postcode.isNotEmpty && namePrefix.length >= 6) {
      for (final venue in _existingVenues) {
        if (_normalise(venue.postcode) == postcode &&
            _firstSixLetters(venue.name) == namePrefix) {
          match = venue;
          break;
        }
      }
    }

    if (match?.id == _matchedVenue?.id) return;

    if (match == null) {
      setState(() => _matchedVenue = null);
      return;
    }

    _fillFromVenue(match);
  }

  void _fillFromVenue(Venue venue) {
    _fillingFromVenue = true;
    setState(() {
      _matchedVenue = venue;
      _lat = venue.lat;
      _lng = venue.lng;
      _postcodeCtrl.text = venue.postcode;
      _nameCtrl.text = venue.name;
      _descriptionCtrl.text = venue.description;
      _addressCtrl.text = venue.address;
      _venueContactCtrl.text = venue.venueContactName;
      _venuePhoneCtrl.text = venue.venuePhoneNumber;
      _eventContactCtrl.text = venue.eventContactName;
      _eventPhoneCtrl.text = venue.eventContactNumber;
      _plusCodeCtrl.text = venue.plusCode;
      // _what3WordsCtrl.text = venue.what3words;
      _socialCtrl.text = venue.socialMediaDetails;
      _photoCtrl.text = venue.photoUrl;
      _websiteCtrl.text = venue.website;
      _selectedParking
        ..clear()
        ..addAll(venue.parkingDetails);
    });
    _fillingFromVenue = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Venue')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loadingExisting || _loadingLocation)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _textField(
                      controller: _postcodeCtrl,
                      label: 'Postcode',
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter a postcode';
                        if (!Validators.isPostcode(text)) {
                          return 'Enter a valid UK postcode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IconButton.filled(
                      onPressed: _loadingLocation
                          ? null
                          : _fillPostcodeFromCurrentLocation,
                      tooltip: 'Use Current Location',
                      icon: _loadingLocation
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
              _textField(
                controller: _nameCtrl,
                label: 'Name',
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Enter a venue name';
                  return null;
                },
              ),
              if (_matchedVenue != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Existing venue matched. Editing saved details.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _textField(
                controller: _descriptionCtrl,
                label: 'Description',
                maxLines: 3,
              ),
              _textField(
                controller: _addressCtrl,
                label: 'Address',
                maxLines: 3,
              ),
              _textField(
                controller: _venueContactCtrl,
                label: 'Contact for venue',
              ),
              _textField(
                controller: _venuePhoneCtrl,
                label: 'Phone number venue',
                keyboardType: TextInputType.phone,
              ),
              _textField(
                controller: _eventContactCtrl,
                label: 'Contact for event',
              ),
              _textField(
                controller: _eventPhoneCtrl,
                label: 'Contact number for events',
                keyboardType: TextInputType.phone,
              ),
              _textField(controller: _plusCodeCtrl, label: 'Plus Code'),
              // what3words disabled for venue entry.
              // _textField(
              //   controller: _what3WordsCtrl,
              //   label: 'what3words',
              //   validator: (value) {
              //     final text = value?.trim() ?? '';
              //     if (text.isEmpty) return null;
              //     if (!Validators.isThreeWords(text)) {
              //       return 'Enter three.words.address';
              //     }
              //     return null;
              //   },
              // ),
              const SizedBox(height: 4),
              Text(
                'Parking details',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _parkingOptions.map((option) {
                  final selected = _selectedParking.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedParking.add(option);
                        } else {
                          _selectedParking.remove(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _socialCtrl,
                label: 'Social media details',
                maxLines: 3,
              ),
              _textField(
                controller: _photoCtrl,
                label: 'Photo',
                keyboardType: TextInputType.url,
              ),
              _textField(
                controller: _websiteCtrl,
                label: 'Website',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: (_saving || _loadingExisting) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_business),
                label: Text(
                  _saving
                      ? (_matchedVenue == null
                            ? 'Adding Venue'
                            : 'Updating Venue')
                      : (_matchedVenue == null ? 'Add Venue' : 'Update Venue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        validator: validator,
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDialogMessage({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
