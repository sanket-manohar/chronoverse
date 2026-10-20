import '../l10n/chrono_locale.dart';
import 'chrono_format.dart';
import 'date_extensions.dart';

/// Understands what people type into a date box:
///
/// * `today`, `tomorrow`, `yesterday` (and the locale's own words)
/// * `in 3 days`, `2 weeks ago`, `+5d`, `-1m`, `3 months from now`
/// * `next friday`, `last monday`, `this sunday`, `fri`
/// * `next week`, `next month`, `next year`, `end of month`, `start of week`
/// * `25 dec`, `dec 25`, `25 december 2027`, `25/12`, `2026-12-25`
/// * anything matching your own [patterns]
///
/// ```dart
/// NaturalDateParser().parse('next friday'); // DateTime
/// ```
class NaturalDateParser {
  /// Creates a parser. [patterns] are tried first (e.g. `dd/MM/yyyy`).
  NaturalDateParser({
    ChronoLocale? locale,
    this.patterns = const [],
    this.firstDayOfWeek = DateTime.monday,
  }) : locale = locale ?? ChronoLocale.en;

  /// Locale for month/weekday names and today/tomorrow words.
  final ChronoLocale locale;

  /// Explicit patterns tried before natural language.
  final List<String> patterns;

  /// Used by "start of week" / "end of week".
  final int firstDayOfWeek;

  static const _enMonths = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december'
  ];
  static const _enWeekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  /// Parses [input] relative to [now] (today by default); null when the
  /// text is not understood. Results are dates at midnight.
  DateTime? parse(String input, {DateTime? now}) {
    final ref = (now ?? DateTime.now()).dateOnly;
    final raw = locale.normalizeDigits(input.trim());
    if (raw.isEmpty) return null;

    for (final p in patterns) {
      final d = ChronoFormat(p, locale: locale).tryParse(raw);
      if (d != null) return d;
    }
    final text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final s = locale.strings;
    if (text == 'today' || text == s.today.toLowerCase() || text == 'now') return ref;
    if (text == 'tomorrow' || text == s.tomorrow.toLowerCase() || text == 'tmr') return ref.addDays(1);
    if (text == 'yesterday' || text == s.yesterday.toLowerCase()) return ref.addDays(-1);

    // ISO
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
    if (iso != null) return _valid(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));

    // +5d, -2w, +1m, +1y
    final short = RegExp(r'^([+-])\s?(\d+)\s?([dwmy])$').firstMatch(text);
    if (short != null) {
      final n = int.parse(short[2]!) * (short[1] == '-' ? -1 : 1);
      return _shift(ref, n, short[3]!);
    }

    // in 3 days / 3 days from now / 2 weeks ago / in a month
    final rel = RegExp(r'^(?:in )?(\d+|a|an|one|two|three) (day|week|month|year)s?(?: (ago|from now|later))?$')
        .firstMatch(text);
    if (rel != null && (text.startsWith('in ') || rel[3] != null)) {
      final n = switch (rel[1]) {
        'a' || 'an' || 'one' => 1,
        'two' => 2,
        'three' => 3,
        _ => int.parse(rel[1]!),
      };
      return _shift(ref, rel[3] == 'ago' ? -n : n, rel[2]![0]);
    }

    // next/last/this <weekday|week|month|year>
    final nl = RegExp(r'^(next|last|this|coming|previous) (\S+)$').firstMatch(text);
    if (nl != null) {
      final dir = switch (nl[1]) { 'next' || 'coming' => 1, 'last' || 'previous' => -1, _ => 0 };
      final word = nl[2]!;
      final wd = _weekday(word);
      if (wd != null) {
        if (dir == 0) return ref.startOfWeek(firstDayOfWeek).addDays((wd - firstDayOfWeek + 7) % 7);
        return dir > 0 ? ref.nextWeekday(wd) : ref.previousWeekday(wd);
      }
      switch (word) {
        case 'week':
          return ref.addWeeks(dir).startOfWeek(firstDayOfWeek);
        case 'month':
          return ref.startOfMonth.addMonths(dir);
        case 'year':
          return DateTime(ref.year + dir);
      }
    }

    // bare weekday → the next one (today counts)
    final wdOnly = _weekday(text);
    if (wdOnly != null) return ref.addDays((wdOnly - ref.weekday + 7) % 7);

    // start/end of week/month/year
    final se = RegExp(r'^(start|beginning|end) of (?:the )?(week|month|year)$').firstMatch(text);
    if (se != null) {
      final start = se[1] != 'end';
      return switch (se[2]) {
        'week' => start ? ref.startOfWeek(firstDayOfWeek) : ref.endOfWeek(firstDayOfWeek),
        'month' => start ? ref.startOfMonth : ref.endOfMonth,
        _ => start ? ref.startOfYear : ref.endOfYear,
      };
    }

    // 25 dec [2027] / dec 25[,] [2027] / 25th of december
    final dm = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?(?: of)? ([^\d\s,.]+)\.?,?(?: (\d{2,4}))?$').firstMatch(text);
    final md = RegExp(r'^([^\d\s,.]+)\.? (\d{1,2})(?:st|nd|rd|th)?,?(?: (\d{2,4}))?$').firstMatch(text);
    final (dayStr, monStr, yearStr) = dm != null
        ? (dm[1], dm[2], dm[3])
        : md != null
            ? (md[2], md[1], md[3])
            : (null, null, null);
    if (dayStr != null) {
      final m = _month(monStr!);
      if (m != null) {
        final day = int.parse(dayStr);
        if (yearStr != null) return _valid(_year(yearStr), m, day);
        final thisYear = _valid(ref.year, m, day);
        // No year typed: pick the next time that date comes round.
        if (thisYear != null && !thisYear.isBefore(ref)) return thisYear;
        return _valid(ref.year + 1, m, day) ?? thisYear;
      }
    }

    // 25/12[/2026] or 25.12 – day first unless the locale writes month first
    final num = RegExp(r'^(\d{1,4})[/.-](\d{1,2})(?:[/.-](\d{2,4}))?$').firstMatch(text);
    if (num != null) {
      final monthFirst = locale.defaultDatePattern.startsWith('M');
      final a = int.parse(num[1]!), b = int.parse(num[2]!);
      if (num[1]!.length == 4) return _valid(a, b, int.tryParse(num[3] ?? '') ?? 1);
      final (d, m) = monthFirst ? (b, a) : (a, b);
      final y = num[3] == null ? ref.year : _year(num[3]!);
      // When the locale's order is impossible (25/12 in the US), try the
      // other order so obvious input still works.
      return _valid(y, m, d) ?? _valid(y, d, m);
    }
    return null;
  }

  int _year(String s) => s.length == 2 ? 2000 + int.parse(s) : int.parse(s);

  DateTime? _valid(int y, int m, int d) =>
      m >= 1 && m <= 12 && d >= 1 && d <= daysInMonth(y, m) ? DateTime(y, m, d) : null;

  DateTime _shift(DateTime ref, int n, String unit) => switch (unit) {
        'd' => ref.addDays(n),
        'w' => ref.addWeeks(n),
        'm' => ref.addMonths(n),
        _ => ref.addYears(n),
      };

  int? _weekday(String w) {
    for (var i = 0; i < 7; i++) {
      final names = [
        _enWeekdays[i],
        _enWeekdays[i].substring(0, 3),
        locale.weekdayNames[i].toLowerCase(),
        locale.weekdayShortNames[i].toLowerCase().replaceAll('.', ''),
      ];
      if (names.contains(w.replaceAll('.', ''))) return i + 1;
    }
    return null;
  }

  int? _month(String w) {
    final word = w.replaceAll('.', '');
    for (var i = 0; i < 12; i++) {
      if (word.length >= 3 && _enMonths[i].startsWith(word)) return i + 1;
      if (locale.monthNames[i].toLowerCase() == word ||
          locale.monthShortNames[i].toLowerCase().replaceAll('.', '') == word) {
        return i + 1;
      }
    }
    return null;
  }
}
