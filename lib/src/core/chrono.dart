import '../l10n/chrono_locale.dart';
import 'calendar_systems.dart';
import 'chrono_format.dart';
import 'date_extensions.dart';
import 'date_math.dart';
import 'date_range.dart';
import 'natural_date.dart';
import 'zoned_date_time.dart';

/// One place to find every date and time function in Chronoverse.
///
/// Everything here is a thin, discoverable shortcut to the specialised
/// classes ([ChronoFormat], [DateMath], [CalendarConverter],
/// [NaturalDateParser], ...), so `Chrono.` plus autocomplete is all you need.
///
/// ```dart
/// Chrono.isLeapYear(2028);                     // true
/// Chrono.age(DateTime(1995, 3, 10));           // 31
/// Chrono.format(DateTime.now(), 'dd MMM yyyy');
/// Chrono.toHijri(DateTime.now());              // CalendarDate
/// Chrono.parseNatural('next friday');
/// Chrono.addBusinessDays(DateTime.now(), 5);
/// ```
abstract final class Chrono {
  // ── Now ────────────────────────────────────────────────────────────────

  /// Current local date and time.
  static DateTime now() => DateTime.now();

  /// Today at midnight.
  static DateTime today() => DateTime.now().dateOnly;

  /// Tomorrow at midnight.
  static DateTime tomorrow() => today().addDays(1);

  /// Yesterday at midnight.
  static DateTime yesterday() => today().addDays(-1);

  // ── Facts ──────────────────────────────────────────────────────────────

  /// Whether [year] is a Gregorian leap year.
  static bool isLeapYear(int year) => _gregorianLeap(year);

  /// Days in [month] of [year].
  static int daysInMonth(int year, int month) => _gregorianMonthLength(year, month);

  /// 365 or 366.
  static int daysInYear(int year) => isLeapYear(year) ? 366 : 365;

  /// ISO-8601 week number of [date].
  static int weekNumber(DateTime date) => date.isoWeekNumber;

  /// Number of ISO weeks in [year] (52 or 53).
  static int weeksInYear(int year) => DateTime(year, 12, 28).isoWeekNumber;

  /// Quarter (1–4) of [date].
  static int quarter(DateTime date) => date.quarter;

  /// Day of the year (1–366).
  static int dayOfYear(DateTime date) => date.dayOfYear;

  /// Whether [date] is a weekend day.
  static bool isWeekend(DateTime date, [Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday}]) =>
      weekendDays.contains(date.weekday);

  /// Whether [date] is in the past (before now).
  static bool isPast(DateTime date) => date.isBefore(DateTime.now());

  /// Whether [date] is in the future.
  static bool isFuture(DateTime date) => date.isAfter(DateTime.now());

  /// Whether two dates are the same day.
  static bool isSameDay(DateTime a, DateTime b) => a.isSameDay(b);

  /// Whether [text] is a real date for [pattern] (e.g. rejects 31/02).
  static bool isValidDate(String text, [String pattern = 'dd/MM/yyyy']) => ChronoFormat(pattern).tryParse(text) != null;

  /// Whether [year]/[month]/[day] exists.
  static bool isValidYmd(int year, int month, int day) =>
      month >= 1 && month <= 12 && day >= 1 && day <= daysInMonth(year, month);

  // ── Arithmetic ─────────────────────────────────────────────────────────

  /// Adds days (DST safe).
  static DateTime addDays(DateTime date, int days) => date.addDays(days);

  /// Adds weeks.
  static DateTime addWeeks(DateTime date, int weeks) => date.addWeeks(weeks);

  /// Adds months, clamping to month end (Jan 31 + 1 → Feb 28/29).
  static DateTime addMonths(DateTime date, int months) => date.addMonths(months);

  /// Adds years, clamping Feb 29.
  static DateTime addYears(DateTime date, int years) => date.addYears(years);

  /// Adds business days, skipping weekends and [holidays].
  static DateTime addBusinessDays(DateTime date, int days,
          {Iterable<DateTime> holidays = const [],
          Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday}}) =>
      DateMath.addBusinessDays(date, days, holidays: holidays, weekendDays: weekendDays);

  /// Business days between two dates.
  static int businessDaysBetween(DateTime from, DateTime to,
          {Iterable<DateTime> holidays = const [],
          Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday}}) =>
      DateMath.businessDaysBetween(from, to, holidays: holidays, weekendDays: weekendDays);

  /// Whole calendar days from [from] to [to].
  static int daysBetween(DateTime from, DateTime to) => from.daysUntil(to);

  /// Whole weeks from [from] to [to].
  static int weeksBetween(DateTime from, DateTime to) => from.daysUntil(to) ~/ 7;

  /// Whole calendar months from [from] to [to].
  static int monthsBetween(DateTime from, DateTime to) {
    final d = DateDifference.between(from, to);
    return d.totalMonths * (d.isNegative ? -1 : 1);
  }

  /// Whole years from [from] to [to].
  static int yearsBetween(DateTime from, DateTime to) {
    final d = DateDifference.between(from, to);
    return d.years * (d.isNegative ? -1 : 1);
  }

  /// "2 years, 3 months, 5 days" style difference.
  static DateDifference difference(DateTime from, DateTime to) => DateDifference.between(from, to);

  /// Age in completed years.
  static int age(DateTime birthDate, {DateTime? on}) => DateMath.age(birthDate, on: on);

  /// Next birthday/anniversary on or after today.
  static DateTime nextAnniversary(DateTime date, {DateTime? from}) => DateMath.nextAnniversary(date, from: from);

  /// Every day from [start] to [end], inclusive.
  static List<DateTime> datesBetween(DateTime start, DateTime end) => DateRange(start, end).days.toList();

  /// The 6×7 (or 5×7) grid of days shown for [month].
  static List<List<DateTime>> monthMatrix(DateTime month,
      {int firstDayOfWeek = DateTime.monday, bool sixWeeks = true}) {
    final first = month.startOfMonth.startOfWeek(firstDayOfWeek);
    final rows = sixWeeks ? 6 : first.daysUntil(month.endOfMonth) ~/ 7 + 1;
    return [
      for (var r = 0; r < rows; r++) [for (var c = 0; c < 7; c++) first.addDays(r * 7 + c)],
    ];
  }

  /// Gregorian Easter Sunday.
  static DateTime easter(int year) => DateMath.easterSunday(year);

  /// The [n]th [weekday] of a month (negative from the end).
  static DateTime? nthWeekday(int year, int month, int n, int weekday) => nthWeekdayOf(year, month, n, weekday);

  // ── Format & parse ─────────────────────────────────────────────────────

  /// Formats with a pattern (see [ChronoFormat] for tokens).
  static String format(DateTime date, String pattern, {String? locale, bool nativeDigits = false}) =>
      ChronoFormat(pattern, locale: ChronoLocale.of(locale), nativeDigits: nativeDigits).format(date);

  /// Parses with a pattern, or null if invalid.
  static DateTime? parse(String text, String pattern, {String? locale}) =>
      ChronoFormat(pattern, locale: ChronoLocale.of(locale)).tryParse(text);

  /// Parses typed text such as "next friday", "in 3 days", "25 dec".
  static DateTime? parseNatural(String text, {DateTime? now, String? locale}) =>
      NaturalDateParser(locale: ChronoLocale.of(locale)).parse(text, now: now);

  /// "in 3 days", "2 hours ago", "Yesterday".
  static String timeAgo(DateTime date, {DateTime? now, String? locale}) =>
      RelativeTime.format(date, now: now, locale: ChronoLocale.of(locale));

  /// "1 hour 30 minutes".
  static String formatDuration(Duration d, {String? locale, int maxParts = 2}) =>
      RelativeTime.duration(d, locale: ChronoLocale.of(locale), maxParts: maxParts);

  /// `01:05:09` (hours can exceed 24).
  static String formatHms(Duration d) {
    final a = d.abs();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${d.isNegative ? '-' : ''}${p(a.inHours)}:${p(a.inMinutes % 60)}:${p(a.inSeconds % 60)}';
  }

  /// Time left until [target], split into days/hours/minutes/seconds.
  static ({int days, int hours, int minutes, int seconds, bool isPast}) countdown(DateTime target, {DateTime? now}) {
    final diff = target.difference(now ?? DateTime.now());
    final a = diff.abs();
    return (
      days: a.inDays,
      hours: a.inHours % 24,
      minutes: a.inMinutes % 60,
      seconds: a.inSeconds % 60,
      isPast: diff.isNegative,
    );
  }

  /// Month names in a locale.
  static List<String> monthNames({String? locale, bool short = false}) {
    final l = ChronoLocale.of(locale);
    return short ? l.monthShortNames : l.monthNames;
  }

  /// Weekday names in a locale, starting Monday.
  static List<String> weekdayNames({String? locale, WeekdayStyle style = WeekdayStyle.full}) {
    final l = ChronoLocale.of(locale);
    return switch (style) {
      WeekdayStyle.full => l.weekdayNames,
      WeekdayStyle.short => l.weekdayShortNames,
      WeekdayStyle.narrow => l.weekdayNarrowNames,
    };
  }

  // ── Conversions ────────────────────────────────────────────────────────

  /// To Islamic (Hijri) date.
  static CalendarDate toHijri(DateTime date) => date.toCalendar(CalendarSystem.hijri);

  /// To Persian (Jalali) date.
  static CalendarDate toPersian(DateTime date) => date.toCalendar(CalendarSystem.persian);

  /// To Indian National (Saka) date.
  static CalendarDate toIndianNational(DateTime date) => date.toCalendar(CalendarSystem.indianNational);

  /// To Thai Buddhist-era date.
  static CalendarDate toBuddhist(DateTime date) => date.toCalendar(CalendarSystem.buddhist);

  /// To Julian-calendar date.
  static CalendarDate toJulianCalendar(DateTime date) => date.toCalendar(CalendarSystem.julian);

  /// From any [CalendarDate] back to Gregorian.
  static DateTime fromCalendar(CalendarDate date) => date.toDateTime();

  /// Julian Day Number.
  static int toJulianDay(DateTime date) => date.julianDay;

  /// Unix seconds.
  static int toUnix(DateTime date) => CalendarConverter.toUnixSeconds(date);

  /// From Unix seconds (UTC).
  static DateTime fromUnix(int seconds) => CalendarConverter.fromUnixSeconds(seconds);

  /// Unix milliseconds.
  static int toUnixMillis(DateTime date) => date.millisecondsSinceEpoch;

  /// From Unix milliseconds (UTC).
  static DateTime fromUnixMillis(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  /// Spreadsheet serial day number (1900 date system).
  static double toSpreadsheetSerial(DateTime date) => CalendarConverter.toSpreadsheetSerial(date);

  /// From a spreadsheet serial day number.
  static DateTime fromSpreadsheetSerial(double serial) => CalendarConverter.fromSpreadsheetSerial(serial);

  /// The same instant at another UTC offset (e.g. `+05:30`).
  static ZonedDateTime atOffset(DateTime instant, String offset) =>
      ZonedDateTime(instant, ZonedDateTime.parseOffset(offset)!);

  /// Converts a wall-clock time from one offset to another, e.g. 09:00 in
  /// `+05:30` → 23:30 the previous day in `-04:00`.
  static ZonedDateTime convertOffset(DateTime wall, String fromOffset, String toOffset) => ZonedDateTime.wall(
          ZonedDateTime.parseOffset(fromOffset)!, wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second)
      .withOffset(ZonedDateTime.parseOffset(toOffset)!);

  /// ISO-8601 string.
  static String toIso(DateTime date) => date.toIso8601String();

  /// Parses ISO-8601 (with or without offset), or null.
  static DateTime? fromIso(String text) => DateTime.tryParse(text);

  // ── Time of day ────────────────────────────────────────────────────────

  /// Minutes since midnight.
  static int minutesOfDay(DateTime date) => date.hour * 60 + date.minute;

  /// Whether the time of [date] is between [start] and [end] (`HH:mm`),
  /// handling ranges that cross midnight such as 22:00–06:00.
  static bool isTimeBetween(DateTime date, String start, String end) {
    int m(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    final now = minutesOfDay(date), s = m(start), e = m(end);
    return s <= e ? now >= s && now < e : now >= s || now < e;
  }

  /// Rounds to the nearest [step] (e.g. 15 minutes).
  static DateTime roundTime(DateTime date, Duration step) => DateMath.roundTo(date, step);

  /// "Good morning" bucket: morning (5–12), afternoon (12–17), evening
  /// (17–21) or night.
  static String partOfDay(DateTime date) => switch (date.hour) {
        >= 5 && < 12 => 'morning',
        >= 12 && < 17 => 'afternoon',
        >= 17 && < 21 => 'evening',
        _ => 'night',
      };

  // ── Fun but useful ─────────────────────────────────────────────────────

  /// Western zodiac sign for a birthday.
  static String zodiacSign(DateTime date) {
    const signs = [
      (1, 20, 'Capricorn'),
      (2, 19, 'Aquarius'),
      (3, 21, 'Pisces'),
      (4, 20, 'Aries'),
      (5, 21, 'Taurus'),
      (6, 21, 'Gemini'),
      (7, 23, 'Cancer'),
      (8, 23, 'Leo'),
      (9, 23, 'Virgo'),
      (10, 23, 'Libra'),
      (11, 22, 'Scorpio'),
      (12, 22, 'Sagittarius'),
    ];
    final (month, startDay, prev) = signs[date.month - 1];
    if (date.day < startDay) return prev;
    return signs[month % 12].$3;
  }

  /// Chinese zodiac animal for a Gregorian year (approximate: the Chinese
  /// year starts in late January/February).
  static String chineseZodiac(int year) => const [
        'Rat',
        'Ox',
        'Tiger',
        'Rabbit',
        'Dragon',
        'Snake',
        'Horse',
        'Goat',
        'Monkey',
        'Rooster',
        'Dog',
        'Pig',
      ][(year - 4) % 12];

  /// Moon phase on [date] as a fraction of the cycle: 0 new, 0.25 first
  /// quarter, 0.5 full, 0.75 last quarter (accurate to about a day).
  static double moonPhase(DateTime date) {
    const synodic = 29.530588853;
    final days = date.toUtc().difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes / 1440;
    final phase = (days % synodic) / synodic;
    return phase < 0 ? phase + 1 : phase;
  }

  /// Moon phase name for [date].
  static String moonPhaseName(DateTime date) {
    const names = [
      'New Moon',
      'Waxing Crescent',
      'First Quarter',
      'Waxing Gibbous',
      'Full Moon',
      'Waning Gibbous',
      'Last Quarter',
      'Waning Crescent'
    ];
    return names[((moonPhase(date) * 8) + 0.5).floor() % 8];
  }
}

// Tear-offs so [Chrono]'s same-named static members can call them.
const _gregorianLeap = isLeapYear;
const _gregorianMonthLength = daysInMonth;
