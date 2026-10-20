import 'package:chronoverse/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('time zones', () {
    final ny = ChronoTimeZone.get('America/New_York');
    final london = ChronoTimeZone.get('Europe/London');
    final sydney = ChronoTimeZone.get('Australia/Sydney');
    final india = ChronoTimeZone.get('Asia/Kolkata');

    test('DST boundaries (2026)', () {
      // US: 8 Mar 2026 02:00 EST = 07:00 UTC.
      expect(ny.isDst(DateTime.utc(2026, 3, 8, 6, 59)), isFalse);
      expect(ny.isDst(DateTime.utc(2026, 3, 8, 7)), isTrue);
      // US: 1 Nov 2026 02:00 EDT = 06:00 UTC.
      expect(ny.isDst(DateTime.utc(2026, 11, 1, 5, 59)), isTrue);
      expect(ny.isDst(DateTime.utc(2026, 11, 1, 6)), isFalse);
      // EU: 29 Mar and 25 Oct 2026 at 01:00 UTC.
      expect(london.isDst(DateTime.utc(2026, 3, 29, 0, 59)), isFalse);
      expect(london.isDst(DateTime.utc(2026, 3, 29, 1)), isTrue);
      expect(london.isDst(DateTime.utc(2026, 10, 25, 1)), isFalse);
      // Southern hemisphere: Sydney is on DST in January.
      expect(sydney.offsetAt(DateTime.utc(2026, 1, 15)), const Duration(hours: 11));
      expect(sydney.offsetAt(DateTime.utc(2026, 7, 15)), const Duration(hours: 10));
      expect(india.offsetAt(DateTime.utc(2026, 7, 15)), const Duration(hours: 5, minutes: 30));
    });

    test('convert wall times', () {
      final meeting = india.convert(DateTime(2026, 10, 20, 19, 30), ny);
      expect(meeting.toIso8601String(), '2026-10-20T10:00:00-04:00');
      final winter = india.convert(DateTime(2026, 12, 1, 19, 30), ny);
      expect(winter.toIso8601String(), '2026-12-01T09:00:00-05:00');
      expect(ny.fromWall(2026, 3, 8, 2, 30).toIso8601String(), '2026-03-08T03:30:00-04:00');
      expect(india.offsetLabel(), 'UTC+05:30');
      expect(ChronoTimeZone.tryGet('+02:00')!.standardOffset, const Duration(hours: 2));
      expect(ChronoTimeZone.ids.length, greaterThan(50));
    });

    test('event local time uses its zone', () {
      final e = CalendarEvent<void>(
        id: 'x',
        title: 'Call',
        start: DateTime(2026, 10, 20, 10),
        end: DateTime(2026, 10, 20, 11),
        timeZone: 'America/New_York',
      );
      expect(e.localStart.toUtc(), DateTime.utc(2026, 10, 20, 14));
    });
  });

  group('event options', () {
    final e = CalendarEvent<Object?>(
      id: 'sync-1',
      title: 'Design review',
      start: DateTime(2026, 10, 20, 15),
      end: DateTime(2026, 10, 20, 16),
      timeZone: 'Asia/Kolkata',
      calendarId: 'work',
      status: EventStatus.tentative,
      visibility: EventVisibility.private,
      showAs: EventShowAs.free,
      type: EventType.focusTime,
      organizer: const EventPerson(email: 'lead@example.com', name: 'Lead'),
      attendees: const [
        EventAttendee(email: 'a@example.com', name: 'A', response: AttendeeResponse.accepted),
        EventAttendee(email: 'room@example.com', isResource: true, optional: true),
      ],
      reminders: const [EventReminder.minutes(10), EventReminder.minutes(60, method: ReminderMethod.email)],
      url: 'https://example.com/doc',
      meetingUrl: 'https://example.com/meet',
      additionalDates: [DateTime(2026, 10, 30, 15)],
    );

    test('reminders and extra dates', () {
      expect(e.reminderTimes(), [DateTime(2026, 10, 20, 14, 50), DateTime(2026, 10, 20, 14)]);
      expect([e].occurrencesIn(DateRange(DateTime(2026, 10, 1), DateTime(2026, 10, 31))), hasLength(2));
    });

    test('free events do not block time, cancelled are hidden', () {
      final busy = CalendarEvent<Object?>(
          id: 'b', title: 'b', start: DateTime(2026, 10, 20, 9), end: DateTime(2026, 10, 20, 10));
      final cancelled = busy.copyWith(id: 'c', status: EventStatus.cancelled);
      final occ = [e, busy, cancelled].occurrencesIn(DateRange.day(DateTime(2026, 10, 20)));
      expect(occ, hasLength(2));
      final free = Schedule.freeSlots(occ, from: DateTime(2026, 10, 20, 8), to: DateTime(2026, 10, 20, 18));
      expect(free.length, 2);
    });

    test('ics keeps every option', () {
      final back = ICalendar.decode(ICalendar.encode([e])).single;
      expect(back.timeZone, 'Asia/Kolkata');
      expect(back.status, EventStatus.tentative);
      expect(back.visibility, EventVisibility.private);
      expect(back.showAs, EventShowAs.free);
      expect(back.type, EventType.focusTime);
      expect(back.calendarId, 'work');
      expect(back.organizer, const EventPerson(email: 'lead@example.com', name: 'Lead'));
      expect(back.attendees.first.response, AttendeeResponse.accepted);
      expect(back.attendees.last.isResource, isTrue);
      expect(back.attendees.last.optional, isTrue);
      expect(back.reminders, e.reminders);
      expect(back.url, e.url);
      expect(back.meetingUrl, e.meetingUrl);
      expect(back.additionalDates, e.additionalDates);
    });

    test('filters', () {
      const sources = [CalendarSource(id: 'work', name: 'Work', isVisible: false)];
      expect([e].visibleIn(sources), isEmpty);
      expect([e].involving('a@example.com'), hasLength(1));
      expect([e].search('REVIEW'), hasLength(1));
    });
  });
}
