import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/validators.dart';
import '../../models/event_models.dart';
import '../../providers/app_providers.dart';

class AddAnEventScreen extends ConsumerStatefulWidget {
  const AddAnEventScreen({super.key});

  @override
  ConsumerState<AddAnEventScreen> createState() => _AddAnEventScreenState();
}

class _AddAnEventScreenState extends ConsumerState<AddAnEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventIdCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _venueNameCtrl = TextEditingController();
  final _hostDetailsCtrl = TextEditingController();
  final _providedOtherCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _random = Random.secure();
  final _eventIdChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _eventIdLength = 5;
  final _weekDays = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final _monthWeeks = const ['1st', '2nd', '3rd', '4th', 'Last'];
  final _providedOptions = const ['PA', 'Guitar', 'Bass', 'Keyboard', 'Drum'];

  List<Venue> _venues = const [];
  List<EventTypeModel> _eventTypes = const [];
  List<_EventDate> _randomDates = [];
  List<DateTime> _exceptionDates = [];
  Set<String> _provided = {};

  Venue? _selectedVenue;
  String? _selectedEventTypeId;
  String _frequency = 'random';
  String _monthlyWeek = '1st';
  String _monthlyDay = 'Monday';
  String _weeklyDay = 'Monday';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = true;
  bool _saving = false;
  bool _loadingEvent = false;
  bool _editingExisting = false;

  @override
  void initState() {
    super.initState();
    _generateEventReference();
    _loadLookups();
  }

  @override
  void dispose() {
    _eventIdCtrl.dispose();
    _postcodeCtrl.dispose();
    _venueNameCtrl.dispose();
    _hostDetailsCtrl.dispose();
    _providedOtherCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final fs = ref.read(firestoreServiceProvider);
      final venues = await fs.getVenues();
      final eventTypes = await fs.getEventTypes();
      if (!mounted) return;
      setState(() {
        _venues = venues;
        _eventTypes = eventTypes;
        _selectedEventTypeId = _eventTypes.isEmpty ? null : _eventTypes.first.id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _show('Could not load event form data: $e');
    }
  }

  Future<void> _generateEventReference() async {
    final fs = ref.read(firestoreServiceProvider);
    for (var attempt = 0; attempt < 6; attempt++) {
      final candidate = List.generate(
        _eventIdLength,
        (_) => _eventIdChars[_random.nextInt(_eventIdChars.length)],
      ).join();
      try {
        final existing = await fs.getEventByReference(candidate);
        if (existing == null) {
          if (mounted) _eventIdCtrl.text = candidate;
          return;
        }
      } catch (_) {
        if (mounted) _eventIdCtrl.text = candidate;
        return;
      }
    }
  }

  Future<void> _loadEventForEditing() async {
    final eventReference = _normaliseReference(_eventIdCtrl.text);
    if (eventReference.length != _eventIdLength) {
      _show('Enter a $_eventIdLength character event reference.');
      return;
    }

    setState(() => _loadingEvent = true);
    try {
      final doc = await ref
          .read(firestoreServiceProvider)
          .getEventByReference(eventReference);
      if (!mounted) return;
      if (doc == null) {
        _show('No event found for $eventReference.');
        return;
      }
      _fillFromEvent(doc.data() ?? const {});
      setState(() => _editingExisting = true);
    } catch (e) {
      if (!mounted) return;
      _show('Could not load event: $e');
    } finally {
      if (mounted) setState(() => _loadingEvent = false);
    }
  }

  void _fillFromEvent(Map<String, dynamic> data) {
    final venueId = (data['venueId'] ?? '').toString();
    Venue? matchedVenue;
    for (final venue in _venues) {
      if (venue.id == venueId) {
        matchedVenue = venue;
        break;
      }
    }
    final randomDates = (data['randomDates'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) {
          final timestamp = item['dateTime'];
          final date = timestamp is Timestamp
              ? timestamp.toDate().toLocal()
              : DateTime.now();
          return _EventDate(date: date, time: TimeOfDay.fromDateTime(date));
        })
        .toList();
    final exceptions = (data['exceptionDates'] as List<dynamic>? ?? const [])
        .whereType<Timestamp>()
        .map((t) => DateUtils.dateOnly(t.toDate().toLocal()))
        .toList();

    final loadedTypeId = (data['type'] ?? _selectedEventTypeId)?.toString();
    final eventTypeExists = _eventTypes.any((type) => type.id == loadedTypeId);

    setState(() {
      _selectedVenue = matchedVenue;
      _postcodeCtrl.text = matchedVenue?.postcode ?? '';
      _venueNameCtrl.text = matchedVenue?.name ?? '';
      _selectedEventTypeId = eventTypeExists
          ? loadedTypeId
          : (_eventTypes.isEmpty ? null : _eventTypes.first.id);
      _hostDetailsCtrl.text = (data['hostDetails'] ?? '').toString();
      _frequency = (data['frequency'] ?? 'random').toString();
      _randomDates = randomDates;
      _monthlyWeek = (data['monthlyWeek'] ?? _monthlyWeek).toString();
      _monthlyDay = (data['monthlyDay'] ?? _monthlyDay).toString();
      _weeklyDay = (data['weeklyDay'] ?? _weeklyDay).toString();
      _startDate = _timestampToDate(data['scheduleStartDate']);
      _endDate = _timestampToDate(data['scheduleEndDate']);
      _exceptionDates = exceptions;
      _provided = (data['provided'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((item) => _providedOptions.contains(item))
          .toSet();
      _providedOtherCtrl.text = (data['providedOther'] ?? '').toString();
      _commentsCtrl.text = (data['comments'] ?? '').toString();
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_selectedVenue == null) {
      _show('Select a venue before saving.');
      return;
    }
    if (_selectedEventTypeId == null) {
      _show('Select an event type before saving.');
      return;
    }
    if (!_scheduleIsValid()) return;

    setState(() => _saving = true);
    try {
      final eventReference = _normaliseReference(_eventIdCtrl.text);
      if (!_editingExisting) {
        final existing = await ref
            .read(firestoreServiceProvider)
            .getEventByReference(eventReference);
        if (existing != null) {
          if (!mounted) return;
          _show('That event ID already exists. Press Load to edit it.');
          return;
        }
      }
      final primaryStart = _primaryStart();
      final primaryEnd = _primaryEnd(primaryStart);
      final provided = _provided.toList()..sort();

      final data = {
        'eventReference': eventReference,
        'venueId': _selectedVenue!.id,
        'venueName': _selectedVenue!.name,
        'venueAddress': _selectedVenue!.address,
        'venuePostcode': _selectedVenue!.postcode,
        'type': _selectedEventTypeId,
        'hostDetails': _hostDetailsCtrl.text.trim(),
        'frequency': _frequency,
        'randomDates': _randomDates
            .map((d) => {'dateTime': Timestamp.fromDate(d.dateTime.toUtc())})
            .toList(growable: false),
        'monthlyWeek': _frequency == 'monthly' ? _monthlyWeek : null,
        'monthlyDay': _frequency == 'monthly' ? _monthlyDay : null,
        'weeklyDay': _frequency == 'weekly' ? _weeklyDay : null,
        'scheduleStartDate': _startDate == null
            ? null
            : Timestamp.fromDate(DateUtils.dateOnly(_startDate!).toUtc()),
        'scheduleEndDate': _endDate == null
            ? null
            : Timestamp.fromDate(DateUtils.dateOnly(_endDate!).toUtc()),
        'exceptionDates': _exceptionDates
            .map((d) => Timestamp.fromDate(DateUtils.dateOnly(d).toUtc()))
            .toList(growable: false),
        'provided': provided,
        'providedOther': _providedOtherCtrl.text.trim(),
        'comments': _commentsCtrl.text.trim(),
        'notification': {
          'emailTo': 'hugh_prosser@hotmail.com',
          'smsTo': '+447492183619',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        },
        'start': Timestamp.fromDate(primaryStart.toUtc()),
        'end': Timestamp.fromDate(primaryEnd.toUtc()),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!_editingExisting) 'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.read(firestoreServiceProvider).saveEvent(
            eventReference: eventReference,
            data: data,
          );

      if (!mounted) return;
      await _showDialogMessage(
        title: _editingExisting ? 'Event updated' : 'Event created',
        message: 'Saved event reference $eventReference.',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await _showDialogMessage(title: 'Could not save event', message: '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _scheduleIsValid() {
    if (_frequency == 'random') {
      if (_randomDates.isEmpty) {
        _show('Add at least one date and time.');
        return false;
      }
      return true;
    }
    if (_startDate == null || _endDate == null) {
      _show('Select start and end dates.');
      return false;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _show('End date must be after the start date.');
      return false;
    }
    return true;
  }

  DateTime _primaryStart() {
    if (_frequency == 'random') {
      final sorted = [..._randomDates]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return sorted.first.dateTime;
    }
    return DateUtils.dateOnly(_startDate!);
  }

  DateTime _primaryEnd(DateTime start) {
    if (_frequency == 'random') {
      return start.add(const Duration(hours: 2));
    }
    return DateUtils.dateOnly(_endDate!).add(
      const Duration(hours: 23, minutes: 59),
    );
  }

  List<Venue> get _venueMatches {
    final postcode = _normalisePostcode(_postcodeCtrl.text);
    final name = _venueNameCtrl.text.trim().toLowerCase();
    if (postcode.isEmpty && name.isEmpty) return const [];

    return _venues.where((venue) {
      final postcodeMatch = postcode.isEmpty ||
          _normalisePostcode(venue.postcode).contains(postcode);
      final nameMatch =
          name.isEmpty || venue.name.toLowerCase().contains(name);
      return postcodeMatch && nameMatch;
    }).take(12).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final venueMatches = _venueMatches;

    return Scaffold(
      appBar: AppBar(title: const Text('Add An Event')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading || _loadingEvent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              _eventReferenceRow(),
              const SizedBox(height: 8),
              Text(
                'Venue',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _textField(
                      controller: _postcodeCtrl,
                      label: 'Postcode',
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() => _selectedVenue = null),
                      validator: (value) {
                        if (_selectedVenue != null) return null;
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
                  Expanded(
                    child: _textField(
                      controller: _venueNameCtrl,
                      label: 'Venue name',
                      onChanged: (_) => setState(() => _selectedVenue = null),
                      validator: (value) {
                        if (_selectedVenue != null) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter a venue name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await context.push('/add-venue');
                    if (mounted) _loadLookups();
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text('New Venue'),
                ),
              ),
              if (venueMatches.isNotEmpty && _selectedVenue == null)
                ...venueMatches.map(_venueMatchTile),
              if (_selectedVenue != null) _selectedVenueCard(),
              if (_selectedVenue != null) ...[
                const SizedBox(height: 16),
                _eventDetails(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventReferenceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _textField(
            controller: _eventIdCtrl,
            label: 'Event ID',
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              final text = _normaliseReference(value ?? '');
              if (text.length != _eventIdLength) {
                return 'Enter $_eventIdLength letters or numbers';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton.icon(
            onPressed: _loadingEvent ? null : _loadEventForEditing,
            icon: _loadingEvent
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: const Text('Load'),
          ),
        ),
      ],
    );
  }

  Widget _venueMatchTile(Venue venue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(venue.name),
        subtitle: Text(
          [venue.address, venue.postcode].where((v) => v.isNotEmpty).join('\n'),
        ),
        isThreeLine: venue.address.isNotEmpty,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() {
            _selectedVenue = venue;
            _postcodeCtrl.text = venue.postcode;
            _venueNameCtrl.text = venue.name;
          });
        },
      ),
    );
  }

  Widget _selectedVenueCard() {
    final venue = _selectedVenue!;
    final details = [venue.address, venue.postcode]
        .where((value) => value.trim().isNotEmpty)
        .join('\n');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.place),
        title: Text(venue.name),
        subtitle: details.isEmpty ? null : Text(details),
        trailing: TextButton(
          onPressed: () => setState(() => _selectedVenue = null),
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _eventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedEventTypeId,
          decoration: const InputDecoration(
            labelText: 'Event type',
            border: OutlineInputBorder(),
          ),
          items: _eventTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type.id,
                  child: Text(type.label),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedEventTypeId = value),
          validator: (value) => value == null ? 'Select an event type' : null,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _hostDetailsCtrl,
          label: 'Host details',
          maxLines: 3,
        ),
        Text('Frequency', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _frequencyOption('Random', 'random'),
            _frequencyOption('Weekly', 'weekly'),
            _frequencyOption('Monthly', 'monthly'),
          ],
        ),
        if (_frequency == 'random') _randomSchedule(),
        if (_frequency == 'weekly') _weeklySchedule(),
        if (_frequency == 'monthly') _monthlySchedule(),
        if (_frequency != 'random') _recurringCommonDates(),
        const SizedBox(height: 12),
        Text('Provided', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: _providedOptions.map(_providedOption).toList(),
        ),
        _textField(controller: _providedOtherCtrl, label: 'Other'),
        _textField(controller: _commentsCtrl, label: 'Comments', maxLines: 5),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: (_saving || _loading) ? null : _save,
          icon: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving Event' : 'Save Event'),
        ),
      ],
    );
  }

  Widget _frequencyOption(String label, String value) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => setState(() => _frequency = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _frequency,
            visualDensity: VisualDensity.compact,
            onChanged: (selected) => setState(() => _frequency = selected!),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _providedOption(String option) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _toggleProvided(option, !_provided.contains(option)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _provided.contains(option),
            visualDensity: VisualDensity.compact,
            onChanged: (selected) => _toggleProvided(option, selected ?? false),
          ),
          Text(option),
        ],
      ),
    );
  }

  void _toggleProvided(String option, bool selected) {
    setState(() {
      if (selected) {
        _provided.add(option);
      } else {
        _provided.remove(option);
      }
    });
  }

  Widget _randomSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _addRandomDate,
          icon: const Icon(Icons.event),
          label: const Text('Add Date And Time'),
        ),
        const SizedBox(height: 8),
        if (_randomDates.isEmpty)
          Text(
            'No dates added yet.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ..._randomDates.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_dateFormat.format(item.date)),
            subtitle: Text(item.time.format(context)),
            trailing: IconButton(
              tooltip: 'Remove date',
              icon: const Icon(Icons.delete),
              onPressed: () => setState(() => _randomDates.removeAt(index)),
            ),
          );
        }),
      ],
    );
  }

  Widget _weeklySchedule() {
    return DropdownButtonFormField<String>(
      value: _weeklyDay,
      decoration: const InputDecoration(
        labelText: 'Day of week',
        border: OutlineInputBorder(),
      ),
      items: _weekDays
          .map((day) => DropdownMenuItem(value: day, child: Text(day)))
          .toList(),
      onChanged: (value) => setState(() => _weeklyDay = value!),
    );
  }

  Widget _monthlySchedule() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _monthlyWeek,
            decoration: const InputDecoration(
              labelText: 'Week',
              border: OutlineInputBorder(),
            ),
            items: _monthWeeks
                .map((week) => DropdownMenuItem(value: week, child: Text(week)))
                .toList(),
            onChanged: (value) => setState(() => _monthlyWeek = value!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _monthlyDay,
            decoration: const InputDecoration(
              labelText: 'Day',
              border: OutlineInputBorder(),
            ),
            items: _weekDays
                .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                .toList(),
            onChanged: (value) => setState(() => _monthlyDay = value!),
          ),
        ),
      ],
    );
  }

  Widget _recurringCommonDates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(
                  initial: _startDate,
                  onPicked: (date) => setState(() => _startDate = date),
                ),
                icon: const Icon(Icons.today),
                label: Text(
                  _startDate == null
                      ? 'Start Date'
                      : _dateFormat.format(_startDate!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(
                  initial: _endDate,
                  onPicked: (date) => setState(() => _endDate = date),
                ),
                icon: const Icon(Icons.event_available),
                label: Text(
                  _endDate == null ? 'End Date' : _dateFormat.format(_endDate!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addExceptionDate,
          icon: const Icon(Icons.event_busy),
          label: const Text('Add Exception Date'),
        ),
        if (_exceptionDates.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _exceptionDates
                .map(
                  (date) => InputChip(
                    label: Text(_dateFormat.format(date)),
                    onDeleted: () {
                      setState(() => _exceptionDates.remove(date));
                    },
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _addRandomDate() async {
    DateTime? selectedDate;
    await _pickDate(
      initial: DateTime.now(),
      onPicked: (date) => selectedDate = date,
    );
    if (selectedDate == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 30),
    );
    if (time == null || !mounted) return;

    setState(() {
      _randomDates.add(_EventDate(date: selectedDate!, time: time));
      _randomDates.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  Future<void> _addExceptionDate() async {
    await _pickDate(
      initial: DateTime.now(),
      onPicked: (date) {
        final dateOnly = DateUtils.dateOnly(date);
        if (!_exceptionDates.contains(dateOnly)) {
          setState(() => _exceptionDates.add(dateOnly));
        }
      },
    );
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      onPicked(DateUtils.dateOnly(picked));
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
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
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return DateUtils.dateOnly(value.toDate().toLocal());
    return null;
  }

  String _normalisePostcode(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();

  String _normaliseReference(String value) =>
      value.trim().replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

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

class _EventDate {
  final DateTime date;
  final TimeOfDay time;

  const _EventDate({required this.date, required this.time});

  DateTime get dateTime => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
}
