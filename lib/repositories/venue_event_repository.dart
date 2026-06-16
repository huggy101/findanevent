import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_models.dart';
import '../models/settings_models.dart';
import '../services/distance_service.dart';
import '../services/firestore_service.dart';

class VenueEventRepository {
  final FirestoreService _fs;
  VenueEventRepository(this._fs);

  Future<List<(EventItem e, Venue v)>> eventsWithVenues({
    required List<String> typeIds,
    required DateTime from,
    DateTime? to,
    SearchSettings? settings,
    (double lat, double lng)? origin,
    DistanceService? distanceService,
  }) async {
    final rangeStart = _dateOnly(from);
    final rangeEnd = _endOfDay(
      _dateOnly(to ?? from.add(const Duration(days: 7))),
    );
    if (rangeEnd.isBefore(rangeStart)) return const [];

    final eventsByKey = <String, EventItem>{};

    for (final typeId in typeIds) {
      final docs = await _fs.getEventDocsByType(typeId);
      for (final doc in docs) {
        for (final event in _eventsInRange(doc, rangeStart, rangeEnd)) {
          eventsByKey['${event.id}-${event.start.toIso8601String()}'] = event;
        }
      }
    }

    final events = eventsByKey.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final venuesCache = <String, Venue>{};
    final out = <(EventItem, Venue)>[];

    for (final e in events) {
      final v = venuesCache[e.venueId] ??=
          await _fs.getVenue(e.venueId) ??
          (throw StateError('Venue not found for id ${e.venueId}'));
      if (!_venueMatchesDistance(
        venue: v,
        settings: settings,
        origin: origin,
        distanceService: distanceService,
      )) {
        continue;
      }
      out.add((e, v));
    }

    return out;
  }

  Iterable<EventItem> _eventsInRange(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) sync* {
    final data = doc.data();
    final venueId = (data['venueId'] ?? '').toString();
    final typeId = (data['type'] ?? '').toString();
    if (venueId.isEmpty || typeId.isEmpty) return;

    final frequency = (data['frequency'] ?? '').toString();
    final scheduleStart = _timestampToLocalDate(data['scheduleStartDate']);
    final scheduleEnd = _timestampToLocalDate(data['scheduleEndDate']);
    final recurringStartTime = _recurringStartTime(data['recurringStartTime']);
    final activeStart = scheduleStart == null
        ? rangeStart
        : _latestDate(rangeStart, _dateOnly(scheduleStart));
    final activeEnd = scheduleEnd == null
        ? rangeEnd
        : _earliestDate(rangeEnd, _endOfDay(_dateOnly(scheduleEnd)));
    if (activeEnd.isBefore(activeStart)) return;

    final exceptions = _exceptionDates(data['exceptionDates']);

    if (frequency == 'weekly') {
      final weekday = _weekdayNumber((data['weeklyDay'] ?? '').toString());
      if (weekday == null) return;
      yield* _recurringDayEvents(
        docId: doc.id,
        venueId: venueId,
        typeId: typeId,
        first: activeStart,
        last: activeEnd,
        weekday: weekday,
        everyWeeks: 1,
        exceptions: exceptions,
        startTime: recurringStartTime,
      );
      return;
    }

    if (frequency == 'fortnightly') {
      final weekday = _weekdayNumber((data['fortnightlyDay'] ?? '').toString());
      if (weekday == null) return;
      final anchor = _dateOnly(scheduleStart ?? rangeStart);
      yield* _recurringDayEvents(
        docId: doc.id,
        venueId: venueId,
        typeId: typeId,
        first: activeStart,
        last: activeEnd,
        weekday: weekday,
        everyWeeks: 2,
        exceptions: exceptions,
        startTime: recurringStartTime,
        anchor: anchor,
      );
      return;
    }

    if (frequency == 'monthly') {
      final weekday = _weekdayNumber((data['monthlyDay'] ?? '').toString());
      final ordinal = (data['monthlyWeek'] ?? '').toString();
      if (weekday == null || ordinal.isEmpty) return;
      yield* _monthlyEvents(
        docId: doc.id,
        venueId: venueId,
        typeId: typeId,
        first: activeStart,
        last: activeEnd,
        weekday: weekday,
        ordinal: ordinal,
        exceptions: exceptions,
        startTime: recurringStartTime,
      );
      return;
    }

    final randomDates = _randomDates(data['randomDates']);
    if (randomDates.isNotEmpty) {
      for (final start in randomDates) {
        if (start.isBefore(rangeStart) || start.isAfter(rangeEnd)) continue;
        if (exceptions.contains(_dateKey(start))) continue;
        yield _eventForOccurrence(doc.id, venueId, typeId, start);
      }
      return;
    }

    final legacyStart = _timestampToLocal(data['start']);
    if (legacyStart == null) return;
    if (legacyStart.isBefore(rangeStart) || legacyStart.isAfter(rangeEnd)) {
      return;
    }
    if (exceptions.contains(_dateKey(legacyStart))) return;
    yield EventItem(
      id: doc.id,
      venueId: venueId,
      typeId: typeId,
      start: legacyStart,
      end: _timestampToLocal(data['end']) ??
          legacyStart.add(const Duration(hours: 2)),
    );
  }

  Iterable<EventItem> _recurringDayEvents({
    required String docId,
    required String venueId,
    required String typeId,
    required DateTime first,
    required DateTime last,
    required int weekday,
    required int everyWeeks,
    required Set<String> exceptions,
    required ({int hour, int minute}) startTime,
    DateTime? anchor,
  }) sync* {
    var cursor = _nextWeekdayOnOrAfter(_dateOnly(first), weekday);
    final anchorDate = anchor == null
        ? null
        : _nextWeekdayOnOrAfter(_dateOnly(anchor), weekday);

    while (!cursor.isAfter(last)) {
      final matchesCycle = anchorDate == null ||
          (cursor.difference(anchorDate).inDays ~/ 7) % everyWeeks == 0;
      if (matchesCycle && !exceptions.contains(_dateKey(cursor))) {
        yield _eventForOccurrence(
          docId,
          venueId,
          typeId,
          _withTime(cursor, startTime),
        );
      }
      cursor = cursor.add(Duration(days: 7 * everyWeeks));
    }
  }

  Iterable<EventItem> _monthlyEvents({
    required String docId,
    required String venueId,
    required String typeId,
    required DateTime first,
    required DateTime last,
    required int weekday,
    required String ordinal,
    required Set<String> exceptions,
    required ({int hour, int minute}) startTime,
  }) sync* {
    var month = DateTime(first.year, first.month);
    final lastMonth = DateTime(last.year, last.month);

    while (!month.isAfter(lastMonth)) {
      final occurrence = _monthlyWeekday(
        month.year,
        month.month,
        weekday,
        ordinal,
      );
      if (occurrence != null &&
          !occurrence.isBefore(first) &&
          !occurrence.isAfter(last) &&
          !exceptions.contains(_dateKey(occurrence))) {
        yield _eventForOccurrence(
          docId,
          venueId,
          typeId,
          _withTime(occurrence, startTime),
        );
      }
      month = DateTime(month.year, month.month + 1);
    }
  }

  EventItem _eventForOccurrence(
    String id,
    String venueId,
    String typeId,
    DateTime start,
  ) {
    return EventItem(
      id: id,
      venueId: venueId,
      typeId: typeId,
      start: start,
      end: start.add(const Duration(hours: 2)),
    );
  }

  bool _venueMatchesDistance({
    required Venue venue,
    required SearchSettings? settings,
    required (double lat, double lng)? origin,
    required DistanceService? distanceService,
  }) {
    if (settings == null ||
        settings.proximityScope != ProximityScope.miles ||
        origin == null ||
        distanceService == null) {
      return true;
    }

    final km = distanceService.haversineKm(
      origin.$1,
      origin.$2,
      venue.lat,
      venue.lng,
    );
    return km <= settings.miles * 1.609344;
  }

  List<DateTime> _randomDates(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((item) => _timestampToLocal(item['dateTime']))
        .whereType<DateTime>()
        .toList(growable: false);
  }

  Set<String> _exceptionDates(dynamic value) {
    if (value is! Iterable) return const {};
    return value
        .whereType<Timestamp>()
        .map((timestamp) => _dateKey(timestamp.toDate().toLocal()))
        .toSet();
  }

  DateTime? _timestampToLocal(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    return null;
  }

  DateTime? _timestampToLocalDate(dynamic value) {
    final date = _timestampToLocal(value);
    return date == null ? null : _dateOnly(date);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  DateTime _withTime(DateTime date, ({int hour, int minute}) time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  ({int hour, int minute}) _recurringStartTime(dynamic value) {
    if (value is Map) {
      final hour = value['hour'];
      final minute = value['minute'];
      if (hour is int &&
          minute is int &&
          hour >= 0 &&
          hour < 24 &&
          minute >= 0 &&
          minute < 60) {
        return (hour: hour, minute: minute);
      }
    }
    return (hour: 0, minute: 0);
  }

  DateTime _latestDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  DateTime _earliestDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  DateTime _nextWeekdayOnOrAfter(DateTime start, int weekday) {
    final offset = (weekday - start.weekday + 7) % 7;
    return start.add(Duration(days: offset));
  }

  DateTime? _monthlyWeekday(
    int year,
    int month,
    int weekday,
    String ordinal,
  ) {
    if (ordinal.toLowerCase() == 'last') {
      var cursor = DateTime(year, month + 1, 0);
      while (cursor.weekday != weekday) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return cursor;
    }

    final index = switch (ordinal) {
      '1st' => 1,
      '2nd' => 2,
      '3rd' => 3,
      '4th' => 4,
      _ => null,
    };
    if (index == null) return null;

    var cursor = DateTime(year, month);
    while (cursor.weekday != weekday) {
      cursor = cursor.add(const Duration(days: 1));
    }
    cursor = cursor.add(Duration(days: 7 * (index - 1)));
    return cursor.month == month ? cursor : null;
  }

  int? _weekdayNumber(String value) {
    switch (value.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
    }
    return null;
  }

  String _dateKey(DateTime date) {
    final d = _dateOnly(date);
    return '${d.year}-${d.month}-${d.day}';
  }
}
