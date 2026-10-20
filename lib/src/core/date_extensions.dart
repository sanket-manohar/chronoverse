/// Calendar-aware helpers on [DateTime].
///
/// All day/month/year arithmetic goes through the [DateTime] constructor
/// instead of adding a [Duration], so results stay correct across
/// daylight-saving changes. UTC values stay UTC and local values stay local.
library;

/// Builds a [DateTime] in the same zone kind (UTC or local) as [ref].
DateTime sameZone(
  DateTime ref,
  int year, [
  int month = 1,
  int day = 1,
  int hour = 0,
  int minute = 0,
  int second = 0,
  int millisecond = 0,
  int microsecond = 0,
]) =>
    ref.isUtc
        ? DateTime.utc(year, month, day, hour, minute, second, millisecond, microsecond)
        : DateTime(year, month, day, hour, minute, second, millisecond, microsecond);

/// Number of days in [month] of [year] (Gregorian).
int daysInMonth(int year, int month) {
  const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month == DateTime.february && isLeapYear(year)) return 29;
  return days[month - 1];
}

/// Whether [year] is a Gregorian leap year.
bool isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// Calendar helpers available on every [DateTime].
extension ChronoDateTime on DateTime {
  /// Midnight at the start of this day, same zone kind.
  DateTime get dateOnly => sameZone(this, year, month, day);

  /// The last microsecond of this day.
  DateTime get endOfDay => sameZone(this, year, month, day, 23, 59, 59, 999, 999);

  /// Whether this and [other] fall on the same calendar day.
  bool isSameDay(DateTime? other) => other != null && year == other.year && month == other.month && day == other.day;

  /// Whether this and [other] fall in the same month of the same year.
  bool isSameMonth(DateTime? other) => other != null && year == other.year && month == other.month;

  /// Whether this and [other] fall in the same year.
  bool isSameYear(DateTime? other) => other != null && year == other.year;

  /// Whether this is the same day as [other] or earlier.
  bool isSameDayOrBefore(DateTime other) => isSameDay(other) || dateOnly.isBefore(other.dateOnly);

  /// Whether this is the same day as [other] or later.
  bool isSameDayOrAfter(DateTime other) => isSameDay(other) || dateOnly.isAfter(other.dateOnly);

  /// Whether this day lies between [start] and [end], both inclusive,
  /// ignoring the time of day.
  bool isBetweenDays(DateTime start, DateTime end) => isSameDayOrAfter(start) && isSameDayOrBefore(end);

  /// Whether this is today in the device's local time.
  bool get isToday => isSameDay(DateTime.now());

  /// Whether this is tomorrow in the device's local time.
  bool get isTomorrow => isSameDay(DateTime.now().addDays(1));

  /// Whether this was yesterday in the device's local time.
  bool get isYesterday => isSameDay(DateTime.now().addDays(-1));

  /// Whether this day is in [weekendDays] (Saturday and Sunday by default).
  bool isWeekend(
          [Set<int> weekendDays = const {
            DateTime.saturday,
            DateTime.sunday,
          }]) =>
      weekendDays.contains(weekday);

  /// Whether this year is a leap year.
  bool get isLeap => isLeapYear(year);

  /// Number of days in this month.
  int get daysInThisMonth => daysInMonth(year, month);

  /// Calendar quarter, 1 to 4.
  int get quarter => (month - 1) ~/ 3 + 1;

  /// Day of the year, 1 to 366.
  int get dayOfYear => DateTime.utc(year, month, day).difference(DateTime.utc(year)).inDays + 1;

  /// ISO-8601 week number (weeks start Monday, week 1 holds the first
  /// Thursday of the year).
  int get isoWeekNumber {
    final thursday = DateTime.utc(year, month, day + 4 - weekday);
    final firstDay = DateTime.utc(thursday.year);
    return thursday.difference(firstDay).inDays ~/ 7 + 1;
  }

  /// The year that owns [isoWeekNumber], which can differ from [year]
  /// in the first and last days of December/January.
  int get isoWeekYear => DateTime.utc(year, month, day + 4 - weekday).year;

  /// Week number where weeks start on [firstDayOfWeek] and week 1 is the
  /// week containing January 1st (the US convention when Sunday).
  int weekOfYear({int firstDayOfWeek = DateTime.sunday}) {
    final jan1 = DateTime.utc(year);
    final offset = (jan1.weekday - firstDayOfWeek + 7) % 7;
    return (dayOfYear - 1 + offset) ~/ 7 + 1;
  }

  /// Adds [days] calendar days, keeping the time of day (DST safe).
  DateTime addDays(int days) => sameZone(this, year, month, day + days, hour, minute, second, millisecond, microsecond);

  /// Adds [weeks] calendar weeks.
  DateTime addWeeks(int weeks) => addDays(weeks * 7);

  /// Adds [months] months, clamping the day to the target month's length
  /// (Jan 31 + 1 month = Feb 28/29).
  DateTime addMonths(int months) {
    final total = year * 12 + (month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final d = day.clamp(1, daysInMonth(y, m));
    return sameZone(this, y, m, d, hour, minute, second, millisecond, microsecond);
  }

  /// Adds [years] years, clamping Feb 29 to Feb 28 in non-leap years.
  DateTime addYears(int years) => addMonths(years * 12);

  /// First day of this week, where weeks start on [firstDayOfWeek].
  DateTime startOfWeek([int firstDayOfWeek = DateTime.monday]) =>
      dateOnly.addDays(-((weekday - firstDayOfWeek + 7) % 7));

  /// Last day of this week (at midnight).
  DateTime endOfWeek([int firstDayOfWeek = DateTime.monday]) => startOfWeek(firstDayOfWeek).addDays(6);

  /// First day of this month.
  DateTime get startOfMonth => sameZone(this, year, month);

  /// Last day of this month (at midnight).
  DateTime get endOfMonth => sameZone(this, year, month, daysInThisMonth);

  /// First day of this quarter.
  DateTime get startOfQuarter => sameZone(this, year, (quarter - 1) * 3 + 1);

  /// Last day of this quarter (at midnight).
  DateTime get endOfQuarter => startOfQuarter.addMonths(3).addDays(-1);

  /// First day of this year.
  DateTime get startOfYear => sameZone(this, year);

  /// Last day of this year (at midnight).
  DateTime get endOfYear => sameZone(this, year, 12, 31);

  /// The next date (strictly after this day) that falls on [weekday].
  DateTime nextWeekday(int weekday) {
    final diff = (weekday - this.weekday + 7) % 7;
    return dateOnly.addDays(diff == 0 ? 7 : diff);
  }

  /// The previous date (strictly before this day) that falls on [weekday].
  DateTime previousWeekday(int weekday) {
    final diff = (this.weekday - weekday + 7) % 7;
    return dateOnly.addDays(-(diff == 0 ? 7 : diff));
  }

  /// The [n]th [weekday] of this month; negative [n] counts from the end
  /// (`-1` is the last). Returns null when it does not exist (5th Monday).
  DateTime? nthWeekdayOfMonth(int n, int weekday) => nthWeekdayOf(year, month, n, weekday, utc: isUtc);

  /// Whole calendar days from this day to [other] (negative if [other] is
  /// earlier). Time of day and DST are ignored.
  int daysUntil(DateTime other) =>
      DateTime.utc(other.year, other.month, other.day).difference(DateTime.utc(year, month, day)).inDays;

  /// Clamps this date into [min]..[max] (either may be null).
  DateTime clampTo(DateTime? min, DateTime? max) {
    if (min != null && isBefore(min)) return min;
    if (max != null && isAfter(max)) return max;
    return this;
  }

  /// Copy with some fields replaced.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) =>
      sameZone(
        this,
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
      );

  /// Same calendar date with the time set from [hour] and [minute].
  DateTime atTime(int hour, [int minute = 0, int second = 0]) => sameZone(this, year, month, day, hour, minute, second);
}

/// The [n]th [weekday] of [month]/[year]; negative [n] counts from the end.
DateTime? nthWeekdayOf(int year, int month, int n, int weekday, {bool utc = false}) {
  if (n == 0) return null;
  final dim = daysInMonth(year, month);
  if (n > 0) {
    final first = DateTime.utc(year, month).weekday;
    final day = 1 + (weekday - first + 7) % 7 + (n - 1) * 7;
    if (day > dim) return null;
    return utc ? DateTime.utc(year, month, day) : DateTime(year, month, day);
  }
  final last = DateTime.utc(year, month, dim).weekday;
  final day = dim - (last - weekday + 7) % 7 + (n + 1) * 7;
  if (day < 1) return null;
  return utc ? DateTime.utc(year, month, day) : DateTime(year, month, day);
}

/// Smallest of two dates.
DateTime minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

/// Largest of two dates.
DateTime maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
