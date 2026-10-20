import 'date_extensions.dart';

/// A calendar difference broken into years, months and days, as people
/// say it ("2 years, 3 months and 5 days").
class DateDifference {
  /// Creates a difference value.
  const DateDifference({
    required this.years,
    required this.months,
    required this.days,
    this.isNegative = false,
  });

  /// Calendar difference between [from] and [to], ignoring time of day.
  ///
  /// Months are counted by calendar month, so Jan 31 → Feb 28 is 28 days,
  /// and Jan 15 → Mar 15 is exactly 2 months.
  factory DateDifference.between(DateTime from, DateTime to) {
    var a = from.dateOnly, b = to.dateOnly;
    final negative = b.isBefore(a);
    if (negative) {
      final t = a;
      a = b;
      b = t;
    }
    var months = (b.year - a.year) * 12 + (b.month - a.month);
    if (a.addMonths(months).isAfter(b)) months--;
    final anchor = a.addMonths(months);
    return DateDifference(
      years: months ~/ 12,
      months: months % 12,
      days: anchor.daysUntil(b),
      isNegative: negative,
    );
  }

  /// Whole years.
  final int years;

  /// Remaining whole months (0–11).
  final int months;

  /// Remaining days.
  final int days;

  /// True when `to` was before `from`.
  final bool isNegative;

  /// Total months, ignoring the day remainder.
  int get totalMonths => years * 12 + months;

  @override
  bool operator ==(Object other) =>
      other is DateDifference &&
      years == other.years &&
      months == other.months &&
      days == other.days &&
      isNegative == other.isNegative;

  @override
  int get hashCode => Object.hash(years, months, days, isNegative);

  @override
  String toString() => '${isNegative ? '-' : ''}${years}y ${months}m ${days}d';
}

/// Date calculations that need more than one date.
abstract final class DateMath {
  /// Age in completed years on [on] (today by default) for someone born on
  /// [birthDate]. A Feb 29 birthday counts as Feb 28 in non-leap years.
  static int age(DateTime birthDate, {DateTime? on}) => DateDifference.between(birthDate, on ?? DateTime.now()).years;

  /// Next occurrence (today or later) of an anniversary such as a birthday.
  static DateTime nextAnniversary(DateTime date, {DateTime? from}) {
    final today = (from ?? DateTime.now()).dateOnly;
    var years = today.year - date.year;
    var next = date.dateOnly.addYears(years);
    if (next.isBefore(today)) next = date.dateOnly.addYears(++years);
    return next;
  }

  /// Whether [day] is a business day: not a weekend day, not a holiday.
  static bool isBusinessDay(
    DateTime day, {
    Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday},
    Iterable<DateTime> holidays = const [],
  }) =>
      !weekendDays.contains(day.weekday) && !holidays.any((h) => h.isSameDay(day));

  /// Moves [days] business days from [from] (negative moves backwards).
  static DateTime addBusinessDays(
    DateTime from,
    int days, {
    Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday},
    Iterable<DateTime> holidays = const [],
  }) {
    assert(weekendDays.length < 7, 'At least one working day is required');
    final step = days.isNegative ? -1 : 1;
    var remaining = days.abs();
    var d = from;
    final holidaySet = _daySet(holidays);
    while (remaining > 0) {
      d = d.addDays(step);
      if (!weekendDays.contains(d.weekday) && !holidaySet.contains(_key(d))) {
        remaining--;
      }
    }
    return d;
  }

  /// Business days strictly after [from] up to and including [to].
  static int businessDaysBetween(
    DateTime from,
    DateTime to, {
    Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday},
    Iterable<DateTime> holidays = const [],
  }) {
    final sign = to.isBefore(from) ? -1 : 1;
    var a = from.dateOnly, b = to.dateOnly;
    if (sign < 0) {
      final t = a;
      a = b;
      b = t;
    }
    final holidaySet = _daySet(holidays);
    var count = 0;
    for (var d = a.addDays(1); !d.isAfter(b); d = d.addDays(1)) {
      if (!weekendDays.contains(d.weekday) && !holidaySet.contains(_key(d))) {
        count++;
      }
    }
    return count * sign;
  }

  /// Gregorian Easter Sunday for [year] (Anonymous Gregorian algorithm).
  static DateTime easterSunday(int year) {
    final a = year % 19, b = year ~/ 100, c = year % 100;
    final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4, k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = (h + l - 7 * m + 114) % 31 + 1;
    return DateTime(year, month, day);
  }

  /// Rounds [time] to the nearest multiple of [step] (e.g. 15 minutes).
  static DateTime roundTo(DateTime time, Duration step) {
    final base = time.dateOnly;
    final us = time.difference(base).inMicroseconds;
    final s = step.inMicroseconds;
    return base.add(Duration(microseconds: ((us + s ~/ 2) ~/ s) * s));
  }

  /// Floors [time] to a multiple of [step] since midnight.
  static DateTime floorTo(DateTime time, Duration step) {
    final base = time.dateOnly;
    final us = time.difference(base).inMicroseconds;
    final s = step.inMicroseconds;
    return base.add(Duration(microseconds: (us ~/ s) * s));
  }

  static int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  static Set<int> _daySet(Iterable<DateTime> days) => {for (final d in days) _key(d)};
}
