import 'date_extensions.dart';

/// A non-Gregorian calendar Chronoverse can convert to and from.
enum CalendarSystem {
  /// Proleptic Gregorian (the [DateTime] calendar).
  gregorian,

  /// Julian calendar (Orthodox church dates, historical dates).
  julian,

  /// Tabular Islamic (Hijri) civil calendar. Observational calendars such
  /// as Umm al-Qura can differ by a day or two around month starts.
  hijri,

  /// Solar Hijri (Jalali / Persian) calendar, used in Iran and Afghanistan.
  persian,

  /// Indian National (Saka) calendar.
  indianNational,

  /// Thai solar (Buddhist era) calendar: Gregorian months, year + 543.
  buddhist,
}

/// A date in some [CalendarSystem].
class CalendarDate implements Comparable<CalendarDate> {
  /// Creates a date in [system].
  const CalendarDate(this.system, this.year, this.month, this.day);

  /// Calendar this date belongs to.
  final CalendarSystem system;

  /// Year in [system].
  final int year;

  /// Month (1-based) in [system].
  final int month;

  /// Day of month.
  final int day;

  /// Month name in English transliteration.
  String get monthName => CalendarConverter.monthNames(system)[month - 1];

  /// Converts back to a Gregorian [DateTime] (local midnight).
  DateTime toDateTime() => CalendarConverter.toGregorian(this);

  /// Julian Day Number of this date.
  int get julianDay => CalendarConverter.toJulianDay(this);

  @override
  int compareTo(CalendarDate other) => julianDay.compareTo(other.julianDay);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && other.system == system && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(system, year, month, day);

  @override
  String toString() => '$day $monthName $year (${system.name})';
}

/// Conversions between calendar systems, Julian Day Numbers, Unix time and
/// spreadsheet serial numbers.
abstract final class CalendarConverter {
  /// Converts a Gregorian [date] into [system].
  static CalendarDate fromDateTime(DateTime date, CalendarSystem system) =>
      fromJulianDay(gregorianToJulianDay(date.year, date.month, date.day), system);

  /// Converts [date] into a Gregorian [DateTime] at local midnight.
  static DateTime toGregorian(CalendarDate date) {
    final (y, m, d) = julianDayToGregorian(toJulianDay(date));
    return DateTime(y, m, d);
  }

  /// Converts [date] into another calendar system.
  static CalendarDate convert(CalendarDate date, CalendarSystem to) => fromJulianDay(toJulianDay(date), to);

  /// Number of days in [month] of [year] in [system].
  static int monthLength(CalendarSystem system, int year, int month) {
    final next = month == 12 ? CalendarDate(system, year + 1, 1, 1) : CalendarDate(system, year, month + 1, 1);
    return toJulianDay(next) - toJulianDay(CalendarDate(system, year, month, 1));
  }

  /// Julian Day Number of [date].
  static int toJulianDay(CalendarDate date) => switch (date.system) {
        CalendarSystem.gregorian => gregorianToJulianDay(date.year, date.month, date.day),
        CalendarSystem.buddhist => gregorianToJulianDay(date.year - 543, date.month, date.day),
        CalendarSystem.julian => _julianToJd(date.year, date.month, date.day),
        CalendarSystem.hijri => _hijriToJd(date.year, date.month, date.day),
        CalendarSystem.persian => _persianToJd(date.year, date.month, date.day),
        CalendarSystem.indianNational => _sakaToJd(date.year, date.month, date.day),
      };

  /// The date with Julian Day Number [jd] in [system].
  static CalendarDate fromJulianDay(int jd, CalendarSystem system) {
    switch (system) {
      case CalendarSystem.gregorian:
        final (y, m, d) = julianDayToGregorian(jd);
        return CalendarDate(system, y, m, d);
      case CalendarSystem.buddhist:
        final (y, m, d) = julianDayToGregorian(jd);
        return CalendarDate(system, y + 543, m, d);
      case CalendarSystem.julian:
        final (y, m, d) = _jdToJulian(jd);
        return CalendarDate(system, y, m, d);
      case CalendarSystem.hijri:
        final (y, m, d) = _jdToHijri(jd);
        return CalendarDate(system, y, m, d);
      case CalendarSystem.persian:
        final (y, m, d) = _jdToPersian(jd);
        return CalendarDate(system, y, m, d);
      case CalendarSystem.indianNational:
        final (y, m, d) = _jdToSaka(jd);
        return CalendarDate(system, y, m, d);
    }
  }

  /// Julian Day Number (noon-based integer) of a Gregorian date.
  static int gregorianToJulianDay(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + _fdiv(y, 4) - _fdiv(y, 100) + _fdiv(y, 400) - 32045;
  }

  /// Gregorian `(year, month, day)` for Julian Day Number [jd].
  static (int, int, int) julianDayToGregorian(int jd) {
    final a = jd + 32044;
    final b = _fdiv(4 * a + 3, 146097);
    final c = a - _fdiv(146097 * b, 4);
    final d = _fdiv(4 * c + 3, 1461);
    final e = c - _fdiv(1461 * d, 4);
    final m = _fdiv(5 * e + 2, 153);
    return (
      100 * b + d - 4800 + m ~/ 10,
      m + 3 - 12 * (m ~/ 10),
      e - _fdiv(153 * m + 2, 5) + 1,
    );
  }

  /// Seconds since 1970-01-01T00:00:00Z.
  static int toUnixSeconds(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;

  /// UTC [DateTime] for Unix [seconds].
  static DateTime fromUnixSeconds(int seconds) => DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  /// Spreadsheet serial day number (1900 date system), where
  /// 1 is 1900-01-01 and the fraction is the time of day.
  static double toSpreadsheetSerial(DateTime date) {
    final days = DateTime.utc(1899, 12, 30).daysUntil(date);
    final secs = date.hour * 3600 + date.minute * 60 + date.second;
    return days + secs / 86400;
  }

  /// Date for a spreadsheet serial number (1900 date system).
  static DateTime fromSpreadsheetSerial(double serial) {
    final days = serial.floor();
    final secs = ((serial - days) * 86400).round();
    return DateTime(1899, 12, 30 + days).add(Duration(seconds: secs));
  }

  /// Month names for [system], English transliteration.
  static List<String> monthNames(CalendarSystem system) => switch (system) {
        CalendarSystem.gregorian || CalendarSystem.julian || CalendarSystem.buddhist => const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December'
          ],
        CalendarSystem.hijri => const [
            'Muharram',
            'Safar',
            "Rabi' al-Awwal",
            "Rabi' al-Thani",
            'Jumada al-Ula',
            'Jumada al-Akhirah',
            'Rajab',
            "Sha'ban",
            'Ramadan',
            'Shawwal',
            "Dhu al-Qa'dah",
            'Dhu al-Hijjah'
          ],
        CalendarSystem.persian => const [
            'Farvardin',
            'Ordibehesht',
            'Khordad',
            'Tir',
            'Mordad',
            'Shahrivar',
            'Mehr',
            'Aban',
            'Azar',
            'Dey',
            'Bahman',
            'Esfand'
          ],
        CalendarSystem.indianNational => const [
            'Chaitra',
            'Vaishakha',
            'Jyeshtha',
            'Ashadha',
            'Shravana',
            'Bhadrapada',
            'Ashvin',
            'Kartika',
            'Agrahayana',
            'Pausha',
            'Magha',
            'Phalguna'
          ],
      };

  // Floor division that is correct for negative numerators.
  static int _fdiv(int a, int b) => (a / b).floor();

  // --- Julian calendar ---------------------------------------------------
  static int _julianToJd(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + _fdiv(y, 4) - 32083;
  }

  static (int, int, int) _jdToJulian(int jd) {
    final c = jd + 32082;
    final d = _fdiv(4 * c + 3, 1461);
    final e = c - _fdiv(1461 * d, 4);
    final m = _fdiv(5 * e + 2, 153);
    return (
      d - 4800 + m ~/ 10,
      m + 3 - 12 * (m ~/ 10),
      e - _fdiv(153 * m + 2, 5) + 1,
    );
  }

  // --- Tabular Islamic ---------------------------------------------------
  static const _hijriEpoch = 1948440; // 1 Muharram 1 AH (16 July 622 Julian)

  static int _hijriToJd(int year, int month, int day) =>
      day + (29.5 * (month - 1)).ceil() + (year - 1) * 354 + _fdiv(3 + 11 * year, 30) + _hijriEpoch - 1;

  static (int, int, int) _jdToHijri(int jd) {
    final year = _fdiv(30 * (jd - _hijriEpoch) + 10646, 10631);
    final month = ((jd - (29 + _hijriToJd(year, 1, 1))) / 29.5).ceil() + 1;
    final m = month.clamp(1, 12);
    return (year, m, jd - _hijriToJd(year, m, 1) + 1);
  }

  /// Whether Hijri [year] is a leap year (Dhu al-Hijjah has 30 days) in the
  /// tabular 30-year cycle.
  static bool isHijriLeapYear(int year) => (14 + 11 * year) % 30 < 11;

  /// Whether Julian-calendar [year] is a leap year.
  static bool isJulianLeapYear(int year) => year % 4 == 0;

  /// Whether [year] is a leap year in [system].
  static bool isLeapYearIn(CalendarSystem system, int year) => switch (system) {
        CalendarSystem.gregorian => isLeapYear(year),
        CalendarSystem.buddhist => isLeapYear(year - 543),
        CalendarSystem.julian => isJulianLeapYear(year),
        CalendarSystem.hijri => isHijriLeapYear(year),
        CalendarSystem.persian => isPersianLeapYear(year),
        CalendarSystem.indianNational => isLeapYear(year + 78),
      };

  // --- Solar Hijri (Borkowski / jalaali-js algorithm) ----------------------
  static const _breaks = [
    -61,
    9,
    38,
    199,
    426,
    686,
    756,
    818,
    1111,
    1181,
    1210,
    1635,
    2060,
    2097,
    2192,
    2262,
    2324,
    2394,
    2456,
    3178
  ];

  static ({int leap, int gy, int march}) _jalCal(int jy) {
    final gy = jy + 621;
    var leapJ = -14;
    var jp = _breaks[0];
    if (jy < jp || jy >= _breaks.last) {
      throw RangeError.range(jy, jp, _breaks.last - 1, 'year');
    }
    var jump = 0;
    for (var i = 1; i < _breaks.length; i++) {
      final jm = _breaks[i];
      jump = jm - jp;
      if (jy < jm) break;
      leapJ += jump ~/ 33 * 8 + jump.remainder(33) ~/ 4;
      jp = jm;
    }
    var n = jy - jp;
    leapJ += n ~/ 33 * 8 + (n.remainder(33) + 3) ~/ 4;
    if (jump.remainder(33) == 4 && jump - n == 4) leapJ += 1;
    final leapG = gy ~/ 4 - ((gy ~/ 100 + 1) * 3) ~/ 4 - 150;
    final march = 20 + leapJ - leapG;
    if (jump - n < 6) n = n - jump + (jump + 4) ~/ 33 * 33;
    var leap = ((n + 1).remainder(33) - 1).remainder(4);
    if (leap == -1) leap = 4;
    return (leap: leap, gy: gy, march: march);
  }

  static int _persianToJd(int jy, int jm, int jd) {
    final r = _jalCal(jy);
    return gregorianToJulianDay(r.gy, 3, r.march) + (jm - 1) * 31 - jm ~/ 7 * (jm - 7) + jd - 1;
  }

  static (int, int, int) _jdToPersian(int jdn) {
    final gy = julianDayToGregorian(jdn).$1;
    var jy = gy - 621;
    final r = _jalCal(jy);
    final start = gregorianToJulianDay(gy, 3, r.march);
    var k = jdn - start;
    if (k >= 0) {
      if (k <= 185) return (jy, 1 + k ~/ 31, k.remainder(31) + 1);
      k -= 186;
    } else {
      jy -= 1;
      k += 179;
      if (r.leap == 1) k += 1;
    }
    return (jy, 7 + k ~/ 30, k.remainder(30) + 1);
  }

  /// Whether Persian year [jy] is a leap year (Esfand has 30 days).
  static bool isPersianLeapYear(int jy) => _jalCal(jy).leap == 0;

  // --- Indian National (Saka) --------------------------------------------
  static int _sakaToJd(int year, int month, int day) {
    final gy = year + 78;
    final leap = isLeapYear(gy);
    final start = gregorianToJulianDay(gy, 3, leap ? 21 : 22);
    final chaitra = leap ? 31 : 30;
    if (month == 1) return start + day - 1;
    var jd = start + chaitra;
    final m = month - 2;
    jd += m <= 5 ? m * 31 : 5 * 31 + (m - 5) * 30;
    return jd + day - 1;
  }

  static (int, int, int) _jdToSaka(int jd) {
    final (gy, _, _) = julianDayToGregorian(jd);
    var year = gy - 78;
    var start = _sakaToJd(year, 1, 1);
    if (jd < start) {
      year--;
      start = _sakaToJd(year, 1, 1);
    }
    var yday = jd - start;
    final chaitra = isLeapYear(year + 78) ? 31 : 30;
    if (yday < chaitra) return (year, 1, yday + 1);
    yday -= chaitra;
    if (yday < 5 * 31) return (year, 2 + yday ~/ 31, yday % 31 + 1);
    yday -= 5 * 31;
    return (year, 7 + yday ~/ 30, yday % 30 + 1);
  }
}

/// Helpers to convert straight from a [DateTime].
extension CalendarSystemDateTime on DateTime {
  /// This date in [system].
  CalendarDate toCalendar(CalendarSystem system) => CalendarConverter.fromDateTime(this, system);

  /// Julian Day Number (noon-based) of this date.
  int get julianDay => CalendarConverter.gregorianToJulianDay(year, month, day);
}
