import 'package:chronoverse/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('leap years', () {
    test('Gregorian century rules', () {
      expect(isLeapYear(2024), isTrue);
      expect(isLeapYear(2023), isFalse);
      expect(isLeapYear(1900), isFalse);
      expect(isLeapYear(2000), isTrue);
      expect(isLeapYear(2100), isFalse);
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
    });

    test('Feb 29 arithmetic clamps', () {
      expect(DateTime(2024, 2, 29).addYears(1), DateTime(2025, 2, 28));
      expect(DateTime(2024, 2, 29).addYears(4), DateTime(2028, 2, 29));
      expect(DateTime(2026, 1, 31).addMonths(1), DateTime(2026, 2, 28));
      expect(DateTime(2024, 1, 31).addMonths(1), DateTime(2024, 2, 29));
      expect(DateTime(2024, 3, 31).addMonths(-1), DateTime(2024, 2, 29));
    });

    test('age for a leap-day birthday', () {
      final born = DateTime(2000, 2, 29);
      expect(DateMath.age(born, on: DateTime(2025, 2, 27)), 24);
      expect(DateMath.age(born, on: DateTime(2025, 2, 28)), 25);
      expect(DateMath.age(born, on: DateTime(2028, 2, 29)), 28);
    });

    test('other calendars', () {
      expect(CalendarConverter.isPersianLeapYear(1403), isTrue);
      expect(CalendarConverter.isPersianLeapYear(1404), isFalse);
      expect(CalendarConverter.monthLength(CalendarSystem.persian, 1403, 12), 30);
      expect(CalendarConverter.monthLength(CalendarSystem.persian, 1404, 12), 29);
      expect(CalendarConverter.isJulianLeapYear(1900), isTrue);
      expect(CalendarConverter.monthLength(CalendarSystem.indianNational, 1946, 1), 31);
      expect(CalendarConverter.monthLength(CalendarSystem.indianNational, 1947, 1), 30);
      final hijriLeaps = [
        for (var y = 1; y <= 30; y++)
          if (CalendarConverter.isHijriLeapYear(y)) y
      ];
      expect(hijriLeaps, [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29]);
      expect(CalendarConverter.monthLength(CalendarSystem.hijri, 1445, 12),
          CalendarConverter.isHijriLeapYear(1445) ? 30 : 29);
    });
  });

  group('extensions', () {
    test('weeks', () {
      final d = DateTime(2026, 10, 20); // Tuesday
      expect(d.startOfWeek(), DateTime(2026, 10, 19));
      expect(d.startOfWeek(DateTime.sunday), DateTime(2026, 10, 18));
      expect(d.isoWeekNumber, 43);
      expect(DateTime(2021, 1, 1).isoWeekNumber, 53);
      expect(DateTime(2021, 1, 1).isoWeekYear, 2020);
      expect(DateTime(2026, 12, 31).dayOfYear, 365);
      expect(DateTime(2024, 12, 31).dayOfYear, 366);
    });

    test('nth weekday', () {
      expect(nthWeekdayOf(2026, 11, 4, DateTime.thursday), DateTime(2026, 11, 26));
      expect(nthWeekdayOf(2026, 5, -1, DateTime.monday), DateTime(2026, 5, 25));
      expect(nthWeekdayOf(2026, 2, 5, DateTime.monday), isNull);
    });

    test('UTC stays UTC', () {
      final u = DateTime.utc(2026, 3, 29, 10);
      expect(u.addDays(1).isUtc, isTrue);
      expect(u.addMonths(1), DateTime.utc(2026, 4, 29, 10));
    });
  });

  group('DateMath', () {
    test('difference', () {
      expect(DateDifference.between(DateTime(2020, 1, 15), DateTime(2026, 10, 20)),
          const DateDifference(years: 6, months: 9, days: 5));
      expect(DateDifference.between(DateTime(2026, 1, 31), DateTime(2026, 3, 1)),
          const DateDifference(years: 0, months: 1, days: 1));
      expect(DateDifference.between(DateTime(2026, 3, 1), DateTime(2026, 1, 31)).isNegative, isTrue);
    });

    test('business days', () {
      final fri = DateTime(2026, 10, 23);
      expect(DateMath.addBusinessDays(fri, 1), DateTime(2026, 10, 26));
      expect(DateMath.addBusinessDays(fri, 1, holidays: [DateTime(2026, 10, 26)]), DateTime(2026, 10, 27));
      expect(DateMath.addBusinessDays(DateTime(2026, 10, 26), -1), fri);
      expect(DateMath.businessDaysBetween(DateTime(2026, 10, 19), DateTime(2026, 10, 30)), 9);
    });

    test('easter', () {
      expect(DateMath.easterSunday(2024), DateTime(2024, 3, 31));
      expect(DateMath.easterSunday(2025), DateTime(2025, 4, 20));
      expect(DateMath.easterSunday(2026), DateTime(2026, 4, 5));
    });

    test('next anniversary', () {
      expect(DateMath.nextAnniversary(DateTime(1995, 3, 10), from: DateTime(2026, 10, 20)), DateTime(2027, 3, 10));
    });

    test('rounding', () {
      expect(DateMath.roundTo(DateTime(2026, 1, 1, 10, 8), const Duration(minutes: 15)), DateTime(2026, 1, 1, 10, 15));
      expect(DateMath.floorTo(DateTime(2026, 1, 1, 10, 14), const Duration(minutes: 15)), DateTime(2026, 1, 1, 10));
    });
  });

  group('DateRange', () {
    test('basics', () {
      final r = DateRange(DateTime(2026, 10, 25), DateTime(2026, 10, 20));
      expect(r.start, DateTime(2026, 10, 20));
      expect(r.lengthInDays, 6);
      expect(r.contains(DateTime(2026, 10, 22, 18)), isTrue);
      final other = DateRange(DateTime(2026, 10, 24), DateTime(2026, 11, 2));
      expect(r.intersection(other), DateRange(DateTime(2026, 10, 24), DateTime(2026, 10, 25)));
      expect(r.days.length, 6);
    });
  });

  group('calendar systems', () {
    test('julian day', () {
      expect(DateTime(2000, 1, 1).julianDay, 2451545);
      expect(CalendarConverter.julianDayToGregorian(2451545), (2000, 1, 1));
    });

    test('persian', () {
      expect(DateTime(2024, 3, 20).toCalendar(CalendarSystem.persian),
          const CalendarDate(CalendarSystem.persian, 1403, 1, 1));
      expect(DateTime(2025, 3, 21).toCalendar(CalendarSystem.persian),
          const CalendarDate(CalendarSystem.persian, 1404, 1, 1));
      expect(const CalendarDate(CalendarSystem.persian, 1405, 7, 28).toDateTime(), DateTime(2026, 10, 20));
    });

    test('indian national', () {
      expect(DateTime(2024, 3, 21).toCalendar(CalendarSystem.indianNational),
          const CalendarDate(CalendarSystem.indianNational, 1946, 1, 1));
      expect(DateTime(2026, 3, 22).toCalendar(CalendarSystem.indianNational),
          const CalendarDate(CalendarSystem.indianNational, 1948, 1, 1));
      expect(DateTime(2026, 10, 20).toCalendar(CalendarSystem.indianNational),
          const CalendarDate(CalendarSystem.indianNational, 1948, 7, 28));
    });

    test('julian calendar', () {
      expect(DateTime(2024, 1, 7).toCalendar(CalendarSystem.julian),
          const CalendarDate(CalendarSystem.julian, 2023, 12, 25));
    });

    test('hijri', () {
      final r = DateTime(2024, 3, 11).toCalendar(CalendarSystem.hijri);
      expect(r.year, 1445);
      expect(r.month, 9); // Ramadan
      expect(r.day, inInclusiveRange(1, 2));
    });

    test('round trips across 200 years', () {
      for (final system in CalendarSystem.values) {
        for (var d = DateTime(1900, 1, 1); d.year < 2100; d = d.addDays(37)) {
          expect(d.toCalendar(system).toDateTime(), d, reason: '$system $d');
        }
      }
    });

    test('spreadsheet and unix', () {
      expect(CalendarConverter.toSpreadsheetSerial(DateTime(2024, 1, 1)), 45292);
      expect(CalendarConverter.fromSpreadsheetSerial(45292.5), DateTime(2024, 1, 1, 12));
      expect(CalendarConverter.fromUnixSeconds(0), DateTime.utc(1970));
    });
  });

  group('format & parse', () {
    test('format tokens', () {
      final d = DateTime(2026, 10, 20, 15, 4, 9);
      expect(ChronoFormat('EEEE, do MMMM yyyy').format(d), 'Tuesday, 20th October 2026');
      expect(ChronoFormat("hh:mm a 'Q'Q w").format(d), '03:04 PM Q4 43');
      expect(ChronoFormat('dd MMM yy', locale: ChronoLocale.of('de')).format(d), '20 Okt. 26');
      expect(ChronoFormat('d MMMM', locale: ChronoLocale.of('hi'), nativeDigits: true).format(d), '२० अक्तूबर');
    });

    test('parse', () {
      expect(ChronoFormat('dd/MM/yyyy').tryParse('20/10/2026'), DateTime(2026, 10, 20));
      expect(ChronoFormat('dd/MM/yyyy').tryParse('20-10-2026'), DateTime(2026, 10, 20));
      expect(ChronoFormat('dd/MM/yyyy').tryParse('31/02/2026'), isNull);
      expect(ChronoFormat('dd/MM/yyyy').tryParse('29/02/2024'), DateTime(2024, 2, 29));
      expect(ChronoFormat('dd/MM/yyyy').tryParse('29/02/2026'), isNull);
      expect(ChronoFormat('d MMM yyyy').tryParse('5 oct 2026'), DateTime(2026, 10, 5));
      expect(ChronoFormat('h:mm a').tryParse('12:30 AM'), DateTime(1970, 1, 1, 0, 30));
      expect(ChronoFormat('dd/MM/yy').tryParse('01/01/49'), DateTime(2049));
      expect(ChronoFormat('dd/MM/yy').tryParse('01/01/50'), DateTime(1950));
      expect(ChronoFormat("yyyy-MM-dd'T'HH:mmZ").tryParse('2026-10-20T09:00+05:30'), DateTime.utc(2026, 10, 20, 3, 30));
      expect(ChronoFormat('dd/MM/yyyy', locale: ChronoLocale.of('ar')).tryParse('٢٠/١٠/٢٠٢٦'), DateTime(2026, 10, 20));
    });

    test('relative', () {
      final now = DateTime(2026, 10, 20, 12);
      expect(RelativeTime.format(now.add(const Duration(days: 3)), now: now), 'in 3 days');
      expect(RelativeTime.format(now.subtract(const Duration(hours: 2)), now: now), '2 hours ago');
      expect(RelativeTime.format(now.add(const Duration(days: 1)), now: now), 'Tomorrow');
      expect(RelativeTime.format(now.subtract(const Duration(days: 5)), now: now, locale: ChronoLocale.of('ru')),
          '5 дней назад');
      expect(RelativeTime.duration(const Duration(minutes: 90)), '1 hour 30 minutes');
    });

    test('every locale is complete', () {
      for (final l in ChronoLocale.builtInLocales) {
        expect(l.monthNames, hasLength(12), reason: l.code);
        expect(l.monthShortNames, hasLength(12), reason: l.code);
        expect(l.weekdayNames, hasLength(7), reason: l.code);
        expect(l.weekdayShortNames, hasLength(7), reason: l.code);
        expect(l.weekdayNarrowNames, hasLength(7), reason: l.code);
        expect(l.unitNames.keys.toSet(), ChronoUnit.values.toSet(), reason: l.code);
      }
      expect(ChronoLocale.of('pt-BR').code, 'pt');
      expect(ChronoLocale.of('xx').code, 'en');
    });
  });

  group('recurrence', () {
    test('weekly with interval and count', () {
      const rule = RecurrenceRule(
        frequency: Frequency.weekly,
        interval: 2,
        count: 4,
        byWeekdays: [ByWeekday(DateTime.monday), ByWeekday(DateTime.wednesday)],
      );
      expect(rule.occurrences(DateTime(2026, 10, 19, 9)).toList(), [
        DateTime(2026, 10, 19, 9),
        DateTime(2026, 10, 21, 9),
        DateTime(2026, 11, 2, 9),
        DateTime(2026, 11, 4, 9),
      ]);
    });

    test('monthly on the 31st skips short months', () {
      final r = RecurrenceRule.parse('FREQ=MONTHLY;COUNT=4');
      expect(r.occurrences(DateTime(2026, 1, 31)).toList(), [
        DateTime(2026, 1, 31),
        DateTime(2026, 3, 31),
        DateTime(2026, 5, 31),
        DateTime(2026, 7, 31),
      ]);
    });

    test('last Friday and last weekday', () {
      final lastFri = RecurrenceRule.parse('RRULE:FREQ=MONTHLY;BYDAY=-1FR;COUNT=3');
      expect(lastFri.occurrences(DateTime(2026, 10, 1)).toList(), [
        DateTime(2026, 10, 30),
        DateTime(2026, 11, 27),
        DateTime(2026, 12, 25),
      ]);
      final lastWorkday = RecurrenceRule.parse('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1;COUNT=2');
      expect(lastWorkday.occurrences(DateTime(2026, 10, 1)).toList(), [DateTime(2026, 10, 30), DateTime(2026, 11, 30)]);
    });

    test('yearly Feb 29 only in leap years', () {
      final r = RecurrenceRule.parse('FREQ=YEARLY;COUNT=3');
      expect(r.occurrences(DateTime(2024, 2, 29)).toList(),
          [DateTime(2024, 2, 29), DateTime(2028, 2, 29), DateTime(2032, 2, 29)]);
    });

    test('thanksgiving', () {
      final r = RecurrenceRule.parse('FREQ=YEARLY;BYMONTH=11;BYDAY=4TH');
      expect(r.occurrences(DateTime(2026, 1, 1)).take(2).toList(), [DateTime(2026, 11, 26), DateTime(2027, 11, 25)]);
    });

    test('until is inclusive and exdates skip', () {
      final r = RecurrenceRule(frequency: Frequency.daily, until: DateTime(2026, 10, 23));
      expect(r.occurrences(DateTime(2026, 10, 20, 10), exclude: [DateTime(2026, 10, 21)]).toList(),
          [DateTime(2026, 10, 20, 10), DateTime(2026, 10, 22, 10), DateTime(2026, 10, 23, 10)]);
    });

    test('impossible rule terminates', () {
      final r = RecurrenceRule.parse('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=30');
      expect(r.occurrences(DateTime(2026)).take(1).toList(), isEmpty);
    });

    test('round trip and describe', () {
      const text = 'FREQ=WEEKLY;INTERVAL=2;COUNT=10;BYDAY=MO,WE';
      expect(RecurrenceRule.parse(text).toString(), text);
      expect(RecurrenceRule.parse(text).describe(), 'Every 2 weeks on Mon, Wed, 10 times');
      expect(RecurrenceRule.weekdays.describe(), 'Every week on weekdays');
    });
  });

  group('events', () {
    test('recurring occurrences in a range', () {
      final e = CalendarEvent<void>(
        id: 'standup',
        title: 'Stand-up',
        start: DateTime(2026, 10, 1, 9),
        end: DateTime(2026, 10, 1, 9, 15),
        recurrence: RecurrenceRule.weekdays,
      );
      final occ = [e].occurrencesIn(DateRange.week(DateTime(2026, 10, 20)));
      expect(occ, hasLength(5));
      expect(occ.first.start, DateTime(2026, 10, 19, 9));
    });

    test('layout columns and free slots', () {
      CalendarEvent<void> ev(String id, int h1, int h2) =>
          CalendarEvent(id: id, title: id, start: DateTime(2026, 1, 1, h1), end: DateTime(2026, 1, 1, h2));
      final occ = [ev('a', 9, 11), ev('b', 10, 12), ev('c', 13, 14)].occurrencesIn(DateRange.day(DateTime(2026)));
      final layout = Schedule.layoutColumns(occ);
      expect(layout[occ[0]], (column: 0, columns: 2));
      expect(layout[occ[1]], (column: 1, columns: 2));
      expect(layout[occ[2]], (column: 0, columns: 1));
      final free = Schedule.freeSlots(occ, from: DateTime(2026, 1, 1, 8), to: DateTime(2026, 1, 1, 18));
      expect(free, [
        DateRangeTime(DateTime(2026, 1, 1, 8), DateTime(2026, 1, 1, 9)),
        DateRangeTime(DateTime(2026, 1, 1, 12), DateTime(2026, 1, 1, 13)),
        DateRangeTime(DateTime(2026, 1, 1, 14), DateTime(2026, 1, 1, 18)),
      ]);
    });

    test('ics round trip', () {
      final events = [
        CalendarEvent<Object?>(
          id: 'x@chronoverse',
          title: 'Review; plan, ship',
          description: 'Line 1\nLine 2',
          start: DateTime.utc(2026, 10, 20, 9),
          end: DateTime.utc(2026, 10, 20, 10),
          recurrence: RecurrenceRule.parse('FREQ=WEEKLY;COUNT=3'),
          color: 0xFF2196F3,
        ),
        CalendarEvent<Object?>.allDay(id: 'h', title: 'Holiday', start: DateTime(2026, 12, 25)),
      ];
      final ics = ICalendar.encode(events);
      expect(ics, contains('DTSTART;VALUE=DATE:20261225'));
      expect(ics, contains('DTEND;VALUE=DATE:20261226'));
      final back = ICalendar.decode(ics);
      expect(back, hasLength(2));
      expect(back[0].title, 'Review; plan, ship');
      expect(back[0].description, 'Line 1\nLine 2');
      expect(back[0].start, DateTime.utc(2026, 10, 20, 9));
      expect(back[0].recurrence.toString(), 'FREQ=WEEKLY;COUNT=3');
      expect(back[0].color, 0xFF2196F3);
      expect(back[1].isAllDay, isTrue);
      expect(back[1].end.day, 25);
    });
  });

  test('zoned time', () {
    final z = ZonedDateTime.tryParse('2026-10-20T09:00:00+05:30')!;
    expect(z.utc, DateTime.utc(2026, 10, 20, 3, 30));
    expect(z.withOffset(const Duration(hours: -4)).toIso8601String(), '2026-10-19T23:30:00-04:00');
  });
}
