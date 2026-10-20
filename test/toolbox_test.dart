import 'package:chronoverse/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 20); // Tuesday

  group('natural language', () {
    final p = NaturalDateParser();
    final cases = <String, DateTime?>{
      'today': now,
      'Tomorrow': DateTime(2026, 10, 21),
      'yesterday': DateTime(2026, 10, 19),
      'in 3 days': DateTime(2026, 10, 23),
      '2 weeks ago': DateTime(2026, 10, 6),
      'in a month': DateTime(2026, 11, 20),
      '+5d': DateTime(2026, 10, 25),
      '-1m': DateTime(2026, 9, 20),
      'next friday': DateTime(2026, 10, 23),
      'last monday': DateTime(2026, 10, 19),
      'fri': DateTime(2026, 10, 23),
      'tuesday': now,
      'next month': DateTime(2026, 11, 1),
      'end of month': DateTime(2026, 10, 31),
      'start of week': DateTime(2026, 10, 19),
      '25 dec': DateTime(2026, 12, 25),
      'dec 25, 2027': DateTime(2027, 12, 25),
      '5th of march': DateTime(2027, 3, 5),
      '25/12/2026': DateTime(2026, 12, 25),
      '2026-02-29': null,
      '2028-02-29': DateTime(2028, 2, 29),
      'gibberish': null,
    };
    cases.forEach((input, expected) {
      test(input, () => expect(p.parse(input, now: now), expected));
    });

    test('localised words', () {
      final es = NaturalDateParser(locale: ChronoLocale.of('es'));
      expect(es.parse('mañana', now: now), DateTime(2026, 10, 21));
      expect(es.parse('25 diciembre', now: now), DateTime(2026, 12, 25));
    });

    test('US month-first numbers', () {
      final en = NaturalDateParser(); // English default pattern is MM/dd/yyyy
      expect(en.parse('12/25', now: now), DateTime(2026, 12, 25));
      final fr = NaturalDateParser(locale: ChronoLocale.of('fr'));
      expect(fr.parse('25/12', now: now), DateTime(2026, 12, 25));
    });
  });

  group('Chrono toolbox', () {
    test('facts', () {
      expect(Chrono.isLeapYear(2028), isTrue);
      expect(Chrono.daysInYear(2100), 365);
      expect(Chrono.weeksInYear(2026), 53);
      expect(Chrono.weeksInYear(2027), 52);
      expect(Chrono.isValidDate('29/02/2027'), isFalse);
      expect(Chrono.isValidYmd(2024, 2, 29), isTrue);
    });

    test('between', () {
      expect(Chrono.monthsBetween(DateTime(2026, 1, 31), DateTime(2026, 3, 30)), 1);
      expect(Chrono.yearsBetween(DateTime(2030), DateTime(2026)), -4);
      expect(Chrono.datesBetween(DateTime(2026, 1, 30), DateTime(2026, 2, 2)), hasLength(4));
      expect(Chrono.monthMatrix(now), hasLength(6));
    });

    test('conversion shortcuts', () {
      expect(Chrono.toPersian(now).toString(), '28 Mehr 1405 (persian)');
      expect(Chrono.fromCalendar(Chrono.toHijri(now)), now);
      expect(Chrono.convertOffset(DateTime(2026, 10, 20, 9), '+05:30', '-04:00').toIso8601String(),
          '2026-10-19T23:30:00-04:00');
      expect(Chrono.formatHms(const Duration(hours: 26, minutes: 5, seconds: 9)), '26:05:09');
    });

    test('time of day', () {
      expect(Chrono.isTimeBetween(DateTime(2026, 1, 1, 23), '22:00', '06:00'), isTrue);
      expect(Chrono.isTimeBetween(DateTime(2026, 1, 1, 12), '22:00', '06:00'), isFalse);
      expect(Chrono.partOfDay(DateTime(2026, 1, 1, 18)), 'evening');
    });

    test('countdown', () {
      final c = Chrono.countdown(DateTime(2026, 10, 22, 3, 4, 5), now: now);
      expect((c.days, c.hours, c.minutes, c.seconds, c.isPast), (2, 3, 4, 5, false));
    });

    test('zodiac and moon', () {
      expect(Chrono.zodiacSign(DateTime(1995, 3, 10)), 'Pisces');
      expect(Chrono.zodiacSign(DateTime(1995, 12, 25)), 'Capricorn');
      expect(Chrono.zodiacSign(DateTime(1995, 1, 25)), 'Aquarius');
      expect(Chrono.chineseZodiac(2024), 'Dragon');
      // Full moon on 2024-04-23.
      expect(Chrono.moonPhaseName(DateTime.utc(2024, 4, 23, 23)), 'Full Moon');
    });
  });

  group('availability', () {
    final rules = DateAvailability(
      disabledWeekdays: {DateTime.sunday},
      disabledDates: [DateTime(2026, 12, 25)],
      disabledRanges: [DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 3))],
    );
    test('rules', () {
      expect(rules.isAvailable(DateTime(2026, 12, 25)), isFalse);
      expect(rules.isAvailable(DateTime(2026, 10, 25)), isFalse); // Sunday
      expect(rules.isAvailable(DateTime(2026, 8, 2)), isFalse);
      expect(rules.isAvailable(DateTime(2026, 10, 20)), isTrue);
      expect(rules.nextAvailable(DateTime(2026, 7, 31)), DateTime(2026, 7, 31));
      expect(rules.nextAvailable(DateTime(2026, 8, 1)), DateTime(2026, 8, 4));
      expect(rules.isRangeAvailable(DateRange(DateTime(2026, 10, 19), DateTime(2026, 10, 24))), isTrue);
    });
  });
}
