import '../l10n/chrono_locale.dart';
import 'date_extensions.dart';

/// Formats and parses dates with a pattern such as `dd MMM yyyy, hh:mm a`.
///
/// | Token  | Meaning                        | Example     |
/// |--------|--------------------------------|-------------|
/// | `yyyy` | year                           | 2026        |
/// | `yy`   | two-digit year                 | 26          |
/// | `MMMM` | month name                     | October     |
/// | `MMM`  | short month name               | Oct         |
/// | `MM`/`M` | month number (padded/not)    | 03 / 3      |
/// | `dd`/`d` | day of month                 | 07 / 7      |
/// | `EEEE` | weekday name                   | Tuesday     |
/// | `EEE`  | short weekday                  | Tue         |
/// | `E`    | narrow weekday                 | T           |
/// | `HH`/`H` | hour 0–23                    | 09 / 9      |
/// | `hh`/`h` | hour 1–12                    | 09 / 9      |
/// | `mm`/`m` | minute                       | 05 / 5      |
/// | `ss`/`s` | second                       | 08 / 8      |
/// | `SSS`  | milliseconds                   | 042         |
/// | `a`    | AM/PM marker                   | PM          |
/// | `Q`    | quarter                        | 4           |
/// | `w`    | ISO week number                | 43          |
/// | `D`    | day of year                    | 293         |
/// | `Z`    | UTC offset                     | +05:30      |
/// | `do`   | English ordinal day            | 1st         |
///
/// Text in single quotes is copied literally: `'Week' w`. Use `''` for a
/// quote character.
class ChronoFormat {
  /// Creates a formatter for [pattern] in [locale] (English by default).
  ChronoFormat(this.pattern, {ChronoLocale? locale, this.nativeDigits = false})
      : locale = locale ?? ChronoLocale.en,
        _tokens = _tokenize(pattern);

  /// The pattern this formatter uses.
  final String pattern;

  /// The locale used for names and digits.
  final ChronoLocale locale;

  /// Whether to write numbers with the locale's own digits (e.g. ٣ or ३).
  final bool nativeDigits;

  final List<_Token> _tokens;

  /// `2026-10-20`.
  static final isoDate = ChronoFormat('yyyy-MM-dd');

  /// `2026-10-20T15:41:00`.
  static final isoDateTime = ChronoFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// `20 Oct 2026`.
  static final medium = ChronoFormat('d MMM yyyy');

  /// `Tuesday, 20 October 2026`.
  static final long = ChronoFormat('EEEE, d MMMM yyyy');

  /// `3:41 PM`.
  static final time12 = ChronoFormat('h:mm a');

  /// `15:41`.
  static final time24 = ChronoFormat('HH:mm');

  /// Formats [date].
  String format(DateTime date) {
    final out = StringBuffer();
    for (final t in _tokens) {
      out.write(t.literal ?? _field(t.field!, date));
    }
    return locale.localizeDigits(out.toString(), enabled: nativeDigits);
  }

  String _field(String f, DateTime d) {
    String pad(int v, int w) => v.toString().padLeft(w, '0');
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return switch (f) {
      'yyyy' => pad(d.year, 4),
      'yy' => pad(d.year % 100, 2),
      'y' => '${d.year}',
      'MMMM' => locale.monthName(d.month),
      'MMM' => locale.monthName(d.month, short: true),
      'MM' => pad(d.month, 2),
      'M' => '${d.month}',
      'dd' => pad(d.day, 2),
      'd' => '${d.day}',
      'do' => '${d.day}${_ordinal(d.day)}',
      'EEEE' => locale.weekdayName(d.weekday),
      'EEE' => locale.weekdayName(d.weekday, style: WeekdayStyle.short),
      'E' => locale.weekdayName(d.weekday, style: WeekdayStyle.narrow),
      'HH' => pad(d.hour, 2),
      'H' => '${d.hour}',
      'hh' => pad(h12, 2),
      'h' => '$h12',
      'mm' => pad(d.minute, 2),
      'm' => '${d.minute}',
      'ss' => pad(d.second, 2),
      's' => '${d.second}',
      'SSS' => pad(d.millisecond, 3),
      'a' => locale.amPm[d.hour < 12 ? 0 : 1],
      'Q' => '${d.quarter}',
      'w' => '${d.isoWeekNumber}',
      'D' => '${d.dayOfYear}',
      'Z' => _offset(d.timeZoneOffset),
      _ => f,
    };
  }

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return 'th';
    return switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
  }

  static String _offset(Duration o) {
    final sign = o.isNegative ? '-' : '+';
    final m = o.inMinutes.abs();
    return '$sign${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  /// Parses [input] with this pattern, or returns null when it does not
  /// match or names an impossible date (e.g. 31/02/2026).
  ///
  /// Two-digit years map into 1950–2049 unless [pivotYear] says otherwise.
  DateTime? tryParse(String input, {bool utc = false, int pivotYear = 1950}) {
    final s = locale.normalizeDigits(input.trim());
    var pos = 0;
    int? year, month, day, hour, minute, second, ms;
    bool? pm;
    Duration? offset;

    int? readInt(int min, int max) {
      var end = pos;
      while (end < s.length && end - pos < max && _isDigit(s.codeUnitAt(end))) {
        end++;
      }
      if (end - pos < min) return null;
      final v = int.parse(s.substring(pos, end));
      pos = end;
      return v;
    }

    int? readName(List<String> names) {
      final lower = s.substring(pos).toLowerCase();
      var best = -1, bestLen = 0;
      for (var i = 0; i < names.length; i++) {
        final n = names[i].toLowerCase();
        if (n.length > bestLen && lower.startsWith(n)) {
          best = i;
          bestLen = n.length;
        }
      }
      if (best < 0) return null;
      pos += bestLen;
      return best;
    }

    for (var i = 0; i < _tokens.length; i++) {
      final t = _tokens[i];
      if (t.literal != null) {
        final lit = t.literal!;
        if (lit.trim().isEmpty) {
          while (pos < s.length && s[pos] == ' ') {
            pos++;
          }
          continue;
        }
        if (!s.startsWith(lit, pos)) {
          // Accept any common separator in place of another.
          if (lit.length == 1 && _separators.contains(lit) && pos < s.length && _separators.contains(s[pos])) {
            pos++;
            continue;
          }
          return null;
        }
        pos += lit.length;
        continue;
      }
      final f = t.field!;
      int? v;
      switch (f) {
        case 'yyyy' || 'y':
          v = readInt(1, 4);
          year = v;
        case 'yy':
          v = readInt(2, 2);
          if (v != null) {
            final century = pivotYear - pivotYear % 100;
            year = century + v < pivotYear ? century + 100 + v : century + v;
          }
        case 'MMMM' || 'MMM':
          v = readName(locale.monthNames) ?? readName(locale.monthShortNames);
          if (v != null) month = v + 1;
        case 'MM' || 'M':
          v = readInt(1, 2);
          month = v;
        case 'dd' || 'd':
          v = readInt(1, 2);
          day = v;
        case 'do':
          v = readInt(1, 2);
          day = v;
          if (v != null && s.length >= pos + 2) pos += 2;
        case 'EEEE' || 'EEE' || 'E':
          v = readName(locale.weekdayNames) ??
              readName(locale.weekdayShortNames) ??
              readName(locale.weekdayNarrowNames);
        case 'HH' || 'H' || 'hh' || 'h':
          v = readInt(1, 2);
          hour = v;
        case 'mm' || 'm':
          v = readInt(1, 2);
          minute = v;
        case 'ss' || 's':
          v = readInt(1, 2);
          second = v;
        case 'SSS':
          v = readInt(1, 3);
          ms = v;
        case 'a':
          v = readName(locale.amPm) ?? readName(const ['am', 'pm']);
          pm = v == 1;
        case 'Z':
          final m = RegExp(r'^(Z|([+-])(\d{2}):?(\d{2}))').firstMatch(s.substring(pos));
          if (m == null) return null;
          pos += m.group(0)!.length;
          offset = m.group(1) == 'Z'
              ? Duration.zero
              : Duration(hours: int.parse(m.group(3)!), minutes: int.parse(m.group(4)!)) * (m.group(2) == '-' ? -1 : 1);
          v = 0;
        default:
          v = readInt(1, 3); // Q, w, D: read and ignore.
      }
      if (v == null) return null;
    }
    if (pos != s.length) return null;

    year ??= 1970;
    month ??= 1;
    day ??= 1;
    hour ??= 0;
    if (pm != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + (pm ? 12 : 0);
    }
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > daysInMonth(year, month)) return null;
    if (hour > 23 || (minute ?? 0) > 59 || (second ?? 0) > 59) return null;

    if (offset != null) {
      return DateTime.utc(year, month, day, hour, minute ?? 0, second ?? 0, ms ?? 0).subtract(offset);
    }
    return utc
        ? DateTime.utc(year, month, day, hour, minute ?? 0, second ?? 0, ms ?? 0)
        : DateTime(year, month, day, hour, minute ?? 0, second ?? 0, ms ?? 0);
  }

  /// Like [tryParse] but throws [FormatException] on failure.
  DateTime parse(String input, {bool utc = false}) =>
      tryParse(input, utc: utc) ?? (throw FormatException('Does not match "$pattern"', input));

  /// The pattern's numeric fields as an input mask, e.g. `dd/MM/yyyy`
  /// becomes `__/__/____`. Only meaningful for all-numeric patterns.
  String get inputMask => _tokens.map((t) {
        if (t.literal != null) return t.literal!;
        final f = t.field!;
        return f == 'yyyy' ? '____' : '_' * f.length.clamp(2, 4);
      }).join();

  /// Whether every field in the pattern is numeric, so it can be typed
  /// with a digit keyboard and auto-inserted separators.
  bool get isNumericOnly => _tokens
      .every((t) => t.literal != null || const {'yyyy', 'yy', 'MM', 'dd', 'HH', 'hh', 'mm', 'ss'}.contains(t.field));

  static const _separators = {'/', '-', '.', ' ', ','};
  static bool _isDigit(int c) => c >= 48 && c <= 57;

  static List<_Token> _tokenize(String pattern) {
    final tokens = <_Token>[];
    final lit = StringBuffer();
    void flush() {
      if (lit.isNotEmpty) {
        tokens.add(_Token.literal(lit.toString()));
        lit.clear();
      }
    }

    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];
      if (c == "'") {
        final end = pattern.indexOf("'", i + 1);
        if (end == i + 1) {
          lit.write("'");
          i += 2;
          continue;
        }
        lit.write(pattern.substring(i + 1, end < 0 ? pattern.length : end));
        i = end < 0 ? pattern.length : end + 1;
        continue;
      }
      if (pattern.startsWith('do', i)) {
        flush();
        tokens.add(const _Token.field('do'));
        i += 2;
        continue;
      }
      if ('yMdEHhmsSaQwDZ'.contains(c)) {
        var j = i;
        while (j < pattern.length && pattern[j] == c) {
          j++;
        }
        flush();
        tokens.add(_Token.field(pattern.substring(i, j)));
        i = j;
        continue;
      }
      lit.write(c);
      i++;
    }
    flush();
    return tokens;
  }
}

class _Token {
  const _Token.literal(String this.literal) : field = null;
  const _Token.field(String this.field) : literal = null;
  final String? literal;
  final String? field;
}

/// "in 3 days", "2 hours ago", "Yesterday" in any [ChronoLocale].
abstract final class RelativeTime {
  /// Describes [date] relative to [now] (the current time by default).
  ///
  /// With [useDayWords], dates one day away use "Yesterday"/"Tomorrow" and
  /// the same day under a minute away reads "Just now".
  static String format(
    DateTime date, {
    DateTime? now,
    ChronoLocale? locale,
    bool useDayWords = true,
  }) {
    final l = locale ?? ChronoLocale.en;
    final ref = now ?? DateTime.now();
    final diff = date.difference(ref);
    final abs = diff.abs();
    if (abs.inSeconds < 45) return l.strings.now;
    if (useDayWords && abs.inHours >= 12) {
      final days = ref.daysUntil(date);
      if (days == 1) return l.strings.tomorrow;
      if (days == -1) return l.strings.yesterday;
    }
    final (unit, n) = switch (abs) {
      _ when abs.inMinutes < 1 => (ChronoUnit.second, abs.inSeconds),
      _ when abs.inHours < 1 => (ChronoUnit.minute, abs.inMinutes),
      _ when abs.inDays < 1 => (ChronoUnit.hour, abs.inHours),
      _ when abs.inDays < 7 => (ChronoUnit.day, abs.inDays),
      _ when abs.inDays < 30 => (ChronoUnit.week, abs.inDays ~/ 7),
      _ when abs.inDays < 365 => (ChronoUnit.month, abs.inDays ~/ 30),
      _ => (ChronoUnit.year, abs.inDays ~/ 365),
    };
    final text = l.unit(unit, n);
    return (diff.isNegative ? l.relativePast : l.relativeFuture).replaceAll('{0}', text);
  }

  /// A short duration such as "1 hour 30 minutes".
  static String duration(Duration d, {ChronoLocale? locale, int maxParts = 2}) {
    final l = locale ?? ChronoLocale.en;
    final parts = <String>[];
    var rest = d.abs();
    for (final (unit, size) in [
      (ChronoUnit.day, const Duration(days: 1)),
      (ChronoUnit.hour, const Duration(hours: 1)),
      (ChronoUnit.minute, const Duration(minutes: 1)),
      (ChronoUnit.second, const Duration(seconds: 1)),
    ]) {
      final n = rest.inMicroseconds ~/ size.inMicroseconds;
      if (n > 0 && parts.length < maxParts) {
        parts.add(l.unit(unit, n));
        rest -= size * n;
      }
    }
    return parts.isEmpty ? l.unit(ChronoUnit.second, 0) : parts.join(' ');
  }
}
