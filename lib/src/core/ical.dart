import 'calendar_event.dart';
import 'recurrence.dart';

/// Reads and writes iCalendar (`.ics`, RFC 5545) VEVENTs, the format used
/// by every major calendar app and service for import and export.
abstract final class ICalendar {
  /// Serialises [events] into an `.ics` document.
  static String encode(
    Iterable<CalendarEvent<Object?>> events, {
    String productId = '-//Chronoverse//EN',
    String? calendarName,
    DateTime? stamp,
  }) {
    final now = (stamp ?? DateTime.now()).toUtc();
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:$productId',
      'CALSCALE:GREGORIAN',
      if (calendarName != null) 'X-WR-CALNAME:${_escape(calendarName)}',
    ];
    for (final e in events) {
      final tz = e.timeZone != null && !e.start.isUtc ? ';TZID=${e.timeZone}' : '';
      lines
        ..add('BEGIN:VEVENT')
        ..add('UID:${_escape(e.id)}')
        ..add('DTSTAMP:${formatIcsDate(now)}')
        ..add(e.isAllDay
            ? 'DTSTART;VALUE=DATE:${formatIcsDate(e.start, dateOnly: true)}'
            : 'DTSTART$tz:${formatIcsDate(e.start)}')
        ..add(e.isAllDay
            // DTEND is exclusive for all-day events.
            ? 'DTEND;VALUE=DATE:${formatIcsDate(DateTime(e.end.year, e.end.month, e.end.day + 1), dateOnly: true)}'
            : 'DTEND$tz:${formatIcsDate(e.end)}')
        ..add('SUMMARY:${_escape(e.title)}');
      if (e.description != null) lines.add('DESCRIPTION:${_escape(e.description!)}');
      if (e.location != null) lines.add('LOCATION:${_escape(e.location!)}');
      if (e.recurrence != null) lines.add('RRULE:${e.recurrence}');
      for (final x in e.exceptionDates) {
        lines.add(e.isAllDay
            ? 'EXDATE;VALUE=DATE:${formatIcsDate(x, dateOnly: true)}'
            : 'EXDATE:${formatIcsDate(x.copyWithTime(e.start))}');
      }
      for (final x in e.additionalDates) {
        lines.add('RDATE$tz:${formatIcsDate(x)}');
      }
      if (e.status != EventStatus.confirmed) lines.add('STATUS:${e.status.name.toUpperCase()}');
      if (e.visibility != EventVisibility.normal) {
        lines.add('CLASS:${e.visibility.name.toUpperCase()}');
      }
      if (e.showAs == EventShowAs.free) lines.add('TRANSP:TRANSPARENT');
      if (e.url != null) lines.add('URL:${e.url}');
      if (e.meetingUrl != null) lines.add('X-CHRONOVERSE-MEETING:${e.meetingUrl}');
      if (e.calendarId != null) lines.add('X-CHRONOVERSE-CALENDAR:${_escape(e.calendarId!)}');
      if (e.type != EventType.normal) lines.add('X-CHRONOVERSE-TYPE:${e.type.name}');
      if (e.organizer != null) lines.add(_person('ORGANIZER', e.organizer!, null));
      for (final a in e.attendees) {
        lines.add(_person('ATTENDEE', a, a));
      }
      for (final r in e.reminders) {
        lines
          ..add('BEGIN:VALARM')
          ..add('ACTION:${r.method == ReminderMethod.email ? 'EMAIL' : 'DISPLAY'}')
          ..add('TRIGGER:-PT${r.before.inMinutes}M')
          ..add('DESCRIPTION:${_escape(e.title)}')
          ..add('END:VALARM');
      }
      if (e.color != null) {
        lines.add('X-CHRONOVERSE-COLOR:#${e.color!.toRadixString(16).padLeft(8, '0')}');
      }
      lines.add('END:VEVENT');
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  /// Parses the VEVENTs in an `.ics` document. Unknown properties are
  /// ignored; TZID parameters are read as local time.
  static List<CalendarEvent<Object?>> decode(String ics) {
    final unfolded = ics.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    final events = <CalendarEvent<Object?>>[];
    Map<String, List<(Map<String, String>, String)>>? cur;
    var inAlarm = false;
    var alarmAction = '';
    var alarmTrigger = '';
    for (final raw in unfolded.split(RegExp(r'\r?\n'))) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line == 'BEGIN:VALARM') {
        inAlarm = true;
        alarmAction = '';
        alarmTrigger = '';
        continue;
      }
      if (line == 'END:VALARM') {
        inAlarm = false;
        if (cur != null && alarmTrigger.isNotEmpty) {
          (cur['X-ALARM'] ??= []).add(({'ACTION': alarmAction}, alarmTrigger));
        }
        continue;
      }
      if (inAlarm) {
        if (line.startsWith('TRIGGER')) alarmTrigger = line.substring(line.indexOf(':') + 1);
        if (line.startsWith('ACTION:')) alarmAction = line.substring(7).toUpperCase();
        continue;
      }
      if (line == 'BEGIN:VEVENT') {
        cur = {};
        continue;
      }
      if (line == 'END:VEVENT') {
        if (cur != null) {
          final e = _toEvent(cur, events.length);
          if (e != null) events.add(e);
        }
        cur = null;
        continue;
      }
      if (cur == null) continue;
      final colon = _valueColon(line);
      if (colon < 0) continue;
      final head = line.substring(0, colon).split(';');
      final params = <String, String>{
        for (final p in head.skip(1))
          if (p.contains('=')) p.substring(0, p.indexOf('=')).toUpperCase(): p.substring(p.indexOf('=') + 1),
      };
      (cur[head.first.toUpperCase()] ??= []).add((params, line.substring(colon + 1)));
    }
    return events;
  }

  static int _valueColon(String line) {
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == '"') quoted = !quoted;
      if (line[i] == ':' && !quoted) return i;
    }
    return -1;
  }

  static CalendarEvent<Object?>? _toEvent(Map<String, List<(Map<String, String>, String)>> p, int index) {
    final dtStart = p['DTSTART']?.first;
    if (dtStart == null) return null;
    final allDay = dtStart.$1['VALUE'] == 'DATE' || dtStart.$2.length == 8;
    final start = parseIcsDate(dtStart.$2);
    DateTime end;
    final dtEnd = p['DTEND']?.first;
    final dur = p['DURATION']?.first.$2;
    if (dtEnd != null) {
      end = parseIcsDate(dtEnd.$2);
      if (allDay) end = DateTime(end.year, end.month, end.day - 1, 23, 59, 59, 999);
    } else if (dur != null) {
      end = start.add(parseDuration(dur));
    } else {
      end = allDay ? DateTime(start.year, start.month, start.day, 23, 59, 59, 999) : start;
    }
    if (end.isBefore(start)) end = start;
    final color = p['X-CHRONOVERSE-COLOR']?.first.$2;
    String? one(String key) => p[key]?.first.$2;
    final tzid = dtStart.$1['TZID'];
    return CalendarEvent<Object?>(
      id: _unescape(p['UID']?.first.$2 ?? 'event-$index'),
      title: _unescape(p['SUMMARY']?.first.$2 ?? ''),
      description: p['DESCRIPTION'] == null ? null : _unescape(p['DESCRIPTION']!.first.$2),
      location: p['LOCATION'] == null ? null : _unescape(p['LOCATION']!.first.$2),
      start: start,
      end: end,
      isAllDay: allDay,
      recurrence: p['RRULE'] == null ? null : RecurrenceRule.parse(p['RRULE']!.first.$2),
      exceptionDates: [
        for (final x in p['EXDATE'] ?? const <(Map<String, String>, String)>[])
          for (final v in x.$2.split(',')) parseIcsDate(v),
      ],
      additionalDates: [
        for (final x in p['RDATE'] ?? const <(Map<String, String>, String)>[])
          for (final v in x.$2.split(',')) parseIcsDate(v),
      ],
      color: color == null ? null : int.tryParse(color.replaceAll('#', ''), radix: 16),
      timeZone: tzid,
      status: switch (one('STATUS')?.toUpperCase()) {
        'TENTATIVE' => EventStatus.tentative,
        'CANCELLED' => EventStatus.cancelled,
        _ => EventStatus.confirmed,
      },
      visibility: switch (one('CLASS')?.toUpperCase()) {
        'PUBLIC' => EventVisibility.public,
        'PRIVATE' || 'CONFIDENTIAL' => EventVisibility.private,
        _ => EventVisibility.normal,
      },
      showAs: one('TRANSP')?.toUpperCase() == 'TRANSPARENT' ? EventShowAs.free : EventShowAs.busy,
      url: one('URL'),
      meetingUrl: one('X-CHRONOVERSE-MEETING'),
      calendarId: one('X-CHRONOVERSE-CALENDAR') == null ? null : _unescape(one('X-CHRONOVERSE-CALENDAR')!),
      type: EventType.values.firstWhere((t) => t.name == one('X-CHRONOVERSE-TYPE'), orElse: () => EventType.normal),
      organizer: p['ORGANIZER'] == null ? null : _readPerson(p['ORGANIZER']!.first),
      attendees: [
        for (final a in p['ATTENDEE'] ?? const <(Map<String, String>, String)>[]) _readAttendee(a),
      ],
      reminders: [
        for (final a in p['X-ALARM'] ?? const <(Map<String, String>, String)>[])
          if (!a.$2.contains('T') || a.$2.startsWith('-') || a.$2.startsWith('P'))
            EventReminder(-parseDuration(a.$2),
                method: a.$1['ACTION'] == 'EMAIL' ? ReminderMethod.email : ReminderMethod.notification),
      ],
    );
  }

  static String _person(String prop, EventPerson p, EventAttendee? a) {
    final params = StringBuffer();
    if (p.name != null) params.write(';CN="${p.name!.replaceAll('"', "'")}"');
    if (a != null) {
      params.write(';PARTSTAT=${switch (a.response) {
        AttendeeResponse.accepted => 'ACCEPTED',
        AttendeeResponse.declined => 'DECLINED',
        AttendeeResponse.tentative => 'TENTATIVE',
        AttendeeResponse.needsAction => 'NEEDS-ACTION',
      }}');
      if (a.optional) params.write(';ROLE=OPT-PARTICIPANT');
      if (a.isResource) params.write(';CUTYPE=RESOURCE');
    }
    return '$prop$params:mailto:${p.email}';
  }

  static String _email(String v) => v.toLowerCase().startsWith('mailto:') ? v.substring(7) : v;

  static EventPerson _readPerson((Map<String, String>, String) v) =>
      EventPerson(email: _email(v.$2), name: v.$1['CN']?.replaceAll('"', ''));

  static EventAttendee _readAttendee((Map<String, String>, String) v) => EventAttendee(
        email: _email(v.$2),
        name: v.$1['CN']?.replaceAll('"', ''),
        response: switch (v.$1['PARTSTAT']?.toUpperCase()) {
          'ACCEPTED' => AttendeeResponse.accepted,
          'DECLINED' => AttendeeResponse.declined,
          'TENTATIVE' => AttendeeResponse.tentative,
          _ => AttendeeResponse.needsAction,
        },
        optional: v.$1['ROLE']?.toUpperCase() == 'OPT-PARTICIPANT',
        isResource: v.$1['CUTYPE']?.toUpperCase() == 'RESOURCE',
      );

  /// Parses an iCalendar DURATION such as `PT1H30M` or `-P2D`.
  static Duration parseDuration(String s) {
    final m = RegExp(r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$').firstMatch(s.trim());
    if (m == null) throw FormatException('Invalid DURATION', s);
    int g(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    final d = Duration(days: g(2) * 7 + g(3), hours: g(4), minutes: g(5), seconds: g(6));
    return m.group(1) == '-' ? -d : d;
  }

  static String _escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll('\n', r'\n');

  static String _unescape(String s) =>
      s.replaceAllMapped(RegExp(r'\\([\\;,nN])'), (m) => m[1] == 'n' || m[1] == 'N' ? '\n' : m[1]!);

  // Lines longer than 75 octets are folded (approximated by characters).
  static String _fold(String line) {
    if (line.length <= 75) return line;
    final b = StringBuffer(line.substring(0, 75));
    for (var i = 75; i < line.length; i += 74) {
      b.write('\r\n ${line.substring(i, i + 74 > line.length ? line.length : i + 74)}');
    }
    return b.toString();
  }
}

extension on DateTime {
  DateTime copyWithTime(DateTime t) => isUtc
      ? DateTime.utc(year, month, day, t.hour, t.minute, t.second)
      : DateTime(year, month, day, t.hour, t.minute, t.second);
}
