import 'date_extensions.dart';

/// How often a [RecurrenceRule] repeats.
enum Frequency {
  /// Every N days.
  daily,

  /// Every N weeks.
  weekly,

  /// Every N months.
  monthly,

  /// Every N years.
  yearly,
}

/// A weekday, optionally with a position: "every Monday" (no [ordinal]),
/// "the 2nd Tuesday" (`ordinal: 2`) or "the last Friday" (`ordinal: -1`).
class ByWeekday {
  /// Creates a weekday selector.
  const ByWeekday(this.weekday, [this.ordinal]);

  /// [DateTime.monday]..[DateTime.sunday].
  final int weekday;

  /// Position inside the month (or year); negative counts from the end.
  final int? ordinal;

  static const _codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// RRULE code such as `MO`, `2TU` or `-1FR`.
  String get code => '${ordinal ?? ''}${_codes[weekday - 1]}';

  /// Parses `MO`, `+2TU`, `-1FR`.
  static ByWeekday parse(String s) {
    final m = RegExp(r'^([+-]?\d{1,2})?(MO|TU|WE|TH|FR|SA|SU)$').firstMatch(s.trim().toUpperCase());
    if (m == null) throw FormatException('Invalid BYDAY value', s);
    return ByWeekday(
      _codes.indexOf(m.group(2)!) + 1,
      m.group(1) == null ? null : int.parse(m.group(1)!.replaceAll('+', '')),
    );
  }

  @override
  bool operator ==(Object other) => other is ByWeekday && other.weekday == weekday && other.ordinal == ordinal;

  @override
  int get hashCode => Object.hash(weekday, ordinal);

  @override
  String toString() => code;
}

/// A repeat rule compatible with iCalendar RRULE (RFC 5545):
/// FREQ, INTERVAL, COUNT, UNTIL, BYDAY, BYMONTHDAY, BYMONTH, BYSETPOS, WKST.
///
/// ```dart
/// // Every other week on Monday and Wednesday, 10 times.
/// final rule = RecurrenceRule(
///   frequency: Frequency.weekly,
///   interval: 2,
///   byWeekdays: [ByWeekday(DateTime.monday), ByWeekday(DateTime.wednesday)],
///   count: 10,
/// );
/// rule.occurrences(start).take(3);
/// RecurrenceRule.parse('FREQ=MONTHLY;BYDAY=-1FR'); // last Friday monthly
/// ```
class RecurrenceRule {
  /// Creates a rule.
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byWeekdays = const [],
    this.byMonthDays = const [],
    this.byMonths = const [],
    this.bySetPositions = const [],
    this.weekStart = DateTime.monday,
  })  : assert(interval > 0, 'interval must be positive'),
        assert(count == null || until == null, 'Use count or until, not both');

  /// Every day.
  static const daily = RecurrenceRule(frequency: Frequency.daily);

  /// Every week on the start date's weekday.
  static const weekly = RecurrenceRule(frequency: Frequency.weekly);

  /// Every month on the start date's day.
  static const monthly = RecurrenceRule(frequency: Frequency.monthly);

  /// Every year on the start date.
  static const yearly = RecurrenceRule(frequency: Frequency.yearly);

  /// Monday to Friday.
  static const weekdays = RecurrenceRule(
    frequency: Frequency.weekly,
    byWeekdays: [
      ByWeekday(DateTime.monday), ByWeekday(DateTime.tuesday),
      ByWeekday(DateTime.wednesday), ByWeekday(DateTime.thursday),
      ByWeekday(DateTime.friday), //
    ],
  );

  /// Repeat unit.
  final Frequency frequency;

  /// Repeat every [interval] units.
  final int interval;

  /// Total number of occurrences, including the first.
  final int? count;

  /// Last allowed occurrence (inclusive).
  final DateTime? until;

  /// BYDAY.
  final List<ByWeekday> byWeekdays;

  /// BYMONTHDAY (1..31 or -31..-1).
  final List<int> byMonthDays;

  /// BYMONTH (1..12).
  final List<int> byMonths;

  /// BYSETPOS: keep only these positions of each period's matches.
  final List<int> bySetPositions;

  /// WKST: first day of the week for weekly rules.
  final int weekStart;

  /// Parses an RRULE value, with or without the `RRULE:` prefix.
  factory RecurrenceRule.parse(String rrule) {
    var text = rrule.trim();
    if (text.toUpperCase().startsWith('RRULE:')) text = text.substring(6);
    final parts = <String, String>{};
    for (final p in text.split(';')) {
      if (p.isEmpty) continue;
      final i = p.indexOf('=');
      if (i < 0) throw FormatException('Invalid RRULE part', p);
      parts[p.substring(0, i).toUpperCase()] = p.substring(i + 1);
    }
    final freq = switch (parts['FREQ']?.toUpperCase()) {
      'DAILY' => Frequency.daily,
      'WEEKLY' => Frequency.weekly,
      'MONTHLY' => Frequency.monthly,
      'YEARLY' => Frequency.yearly,
      _ => throw FormatException('Unsupported or missing FREQ', rrule),
    };
    List<int> ints(String? v) => v == null ? const [] : v.split(',').map(int.parse).toList();
    return RecurrenceRule(
      frequency: freq,
      interval: int.tryParse(parts['INTERVAL'] ?? '') ?? 1,
      count: int.tryParse(parts['COUNT'] ?? ''),
      until: parts['UNTIL'] == null ? null : parseIcsDate(parts['UNTIL']!),
      byWeekdays: parts['BYDAY'] == null ? const [] : parts['BYDAY']!.split(',').map(ByWeekday.parse).toList(),
      byMonthDays: ints(parts['BYMONTHDAY']),
      byMonths: ints(parts['BYMONTH']),
      bySetPositions: ints(parts['BYSETPOS']),
      weekStart: parts['WKST'] == null ? DateTime.monday : ByWeekday.parse(parts['WKST']!).weekday,
    );
  }

  /// RRULE text, e.g. `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE`.
  @override
  String toString() {
    final b = StringBuffer('FREQ=${frequency.name.toUpperCase()}');
    if (interval != 1) b.write(';INTERVAL=$interval');
    if (count != null) b.write(';COUNT=$count');
    if (until != null) b.write(';UNTIL=${formatIcsDate(until!)}');
    if (byWeekdays.isNotEmpty) b.write(';BYDAY=${byWeekdays.join(',')}');
    if (byMonthDays.isNotEmpty) b.write(';BYMONTHDAY=${byMonthDays.join(',')}');
    if (byMonths.isNotEmpty) b.write(';BYMONTH=${byMonths.join(',')}');
    if (bySetPositions.isNotEmpty) {
      b.write(';BYSETPOS=${bySetPositions.join(',')}');
    }
    if (weekStart != DateTime.monday) {
      b.write(';WKST=${ByWeekday(weekStart).code}');
    }
    return b.toString();
  }

  /// Copy with some fields replaced. Pass `clearCount`/`clearUntil` to
  /// remove a limit.
  RecurrenceRule copyWith({
    Frequency? frequency,
    int? interval,
    int? count,
    DateTime? until,
    bool clearCount = false,
    bool clearUntil = false,
    List<ByWeekday>? byWeekdays,
    List<int>? byMonthDays,
    List<int>? byMonths,
    List<int>? bySetPositions,
    int? weekStart,
  }) =>
      RecurrenceRule(
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        count: clearCount ? null : count ?? this.count,
        until: clearUntil ? null : until ?? this.until,
        byWeekdays: byWeekdays ?? this.byWeekdays,
        byMonthDays: byMonthDays ?? this.byMonthDays,
        byMonths: byMonths ?? this.byMonths,
        bySetPositions: bySetPositions ?? this.bySetPositions,
        weekStart: weekStart ?? this.weekStart,
      );

  /// Every occurrence starting at [start] (which counts as the first when
  /// it matches the rule), in order. Lazy, so `take`/`takeWhile` are cheap
  /// even for endless rules. [exclude] removes dates (EXDATE) without
  /// affecting [count].
  Iterable<DateTime> occurrences(DateTime start, {Iterable<DateTime> exclude = const []}) sync* {
    final excluded = {for (final e in exclude) _dayKey(e)};
    var produced = 0;
    var emptyPeriods = 0;
    // A date-only UNTIL (midnight) includes that whole day.
    final last = until == null
        ? null
        : until!.dateOnly == until
            ? until!.endOfDay
            : until!;
    for (var period = 0;; period++) {
      final dates = _expand(start, period);
      if (dates.isEmpty) {
        // A rule like "Feb 30" never matches; stop instead of looping forever.
        if (++emptyPeriods > 1000) return;
        continue;
      }
      emptyPeriods = 0;
      for (final d in dates) {
        if (d.isBefore(start)) continue;
        if (last != null && d.isAfter(last)) return;
        if (count != null && produced >= count!) return;
        produced++;
        if (!excluded.contains(_dayKey(d))) yield d;
      }
    }
  }

  /// Occurrences that fall inside [from]..[to] (inclusive).
  Iterable<DateTime> between(DateTime start, DateTime from, DateTime to, {Iterable<DateTime> exclude = const []}) =>
      occurrences(start, exclude: exclude).skipWhile((d) => d.isBefore(from)).takeWhile((d) => !d.isAfter(to));

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  List<DateTime> _expand(DateTime start, int period) {
    final step = period * interval;
    final days = switch (frequency) {
      Frequency.daily => _filter([start.dateOnly.addDays(step)]),
      Frequency.weekly => _weekly(start, step),
      Frequency.monthly => _monthly(start, step),
      Frequency.yearly => _yearly(start, step),
    };
    final positioned = _applySetPos(days..sort());
    return [
      for (final d in positioned) sameZone(start, d.year, d.month, d.day, start.hour, start.minute, start.second),
    ];
  }

  List<DateTime> _filter(List<DateTime> days) => days.where((d) {
        if (byMonths.isNotEmpty && !byMonths.contains(d.month)) return false;
        if (byMonthDays.isNotEmpty && !_matchesMonthDay(d)) return false;
        if (byWeekdays.isNotEmpty && !byWeekdays.any((w) => w.weekday == d.weekday)) {
          return false;
        }
        return true;
      }).toList();

  bool _matchesMonthDay(DateTime d) {
    final dim = d.daysInThisMonth;
    return byMonthDays.any((m) => m > 0 ? m == d.day : dim + m + 1 == d.day);
  }

  List<DateTime> _weekly(DateTime start, int stepWeeks) {
    final weekBegin = start.startOfWeek(weekStart).addWeeks(stepWeeks);
    final weekdays = byWeekdays.isEmpty ? [start.weekday] : byWeekdays.map((w) => w.weekday).toSet().toList();
    return [
      for (final wd in weekdays) weekBegin.addDays((wd - weekStart + 7) % 7),
    ].where((d) => byMonths.isEmpty || byMonths.contains(d.month)).toList();
  }

  List<DateTime> _monthly(DateTime start, int stepMonths) {
    final first = sameZone(start, start.year, start.month).addMonths(stepMonths);
    if (byMonths.isNotEmpty && !byMonths.contains(first.month)) return [];
    return _daysInMonth(first.year, first.month, start);
  }

  List<DateTime> _daysInMonth(int year, int month, DateTime start) {
    final dim = daysInMonth(year, month);
    DateTime mk(int d) => sameZone(start, year, month, d);
    if (byWeekdays.isEmpty && byMonthDays.isEmpty) {
      return start.day <= dim ? [mk(start.day)] : [];
    }
    final out = <DateTime>[];
    if (byWeekdays.isNotEmpty) {
      for (final w in byWeekdays) {
        if (w.ordinal != null) {
          final d = nthWeekdayOf(year, month, w.ordinal!, w.weekday, utc: start.isUtc);
          if (d != null) out.add(d);
        } else {
          for (var day = 1; day <= dim; day++) {
            if (DateTime.utc(year, month, day).weekday == w.weekday) {
              out.add(mk(day));
            }
          }
        }
      }
      if (byMonthDays.isNotEmpty) out.retainWhere(_matchesMonthDay);
    } else {
      for (final m in byMonthDays) {
        final day = m > 0 ? m : dim + m + 1;
        if (day >= 1 && day <= dim) out.add(mk(day));
      }
    }
    return out.toSet().toList();
  }

  List<DateTime> _yearly(DateTime start, int stepYears) {
    final year = start.year + stepYears;
    if (byMonths.isEmpty && byMonthDays.isEmpty && byWeekdays.isEmpty) {
      final dim = daysInMonth(year, start.month);
      return start.day <= dim ? [sameZone(start, year, start.month, start.day)] : [];
    }
    if (byMonths.isEmpty && byWeekdays.any((w) => w.ordinal != null)) {
      // e.g. FREQ=YEARLY;BYDAY=20MO → 20th Monday of the year.
      final out = <DateTime>[];
      final jan1 = sameZone(start, year);
      final dec31 = sameZone(start, year, 12, 31);
      for (final w in byWeekdays) {
        final all = <DateTime>[
          for (var d = jan1.nextWeekday(w.weekday).addDays(jan1.weekday == w.weekday ? -7 : 0);
              !d.isAfter(dec31);
              d = d.addDays(7))
            d,
        ];
        final n = w.ordinal;
        if (n == null) {
          out.addAll(all);
        } else {
          final i = n > 0 ? n - 1 : all.length + n;
          if (i >= 0 && i < all.length) out.add(all[i]);
        }
      }
      return out;
    }
    final months = byMonths.isEmpty ? [start.month] : byMonths;
    return [for (final m in months) ..._daysInMonth(year, m, start)];
  }

  List<DateTime> _applySetPos(List<DateTime> days) {
    if (bySetPositions.isEmpty) return days;
    final out = <DateTime>[];
    for (final p in bySetPositions) {
      final i = p > 0 ? p - 1 : days.length + p;
      if (i >= 0 && i < days.length) out.add(days[i]);
    }
    return out..sort();
  }

  /// Plain-English description, e.g. "Every 2 weeks on Mon, Wed, 10 times".
  String describe() {
    const units = {
      Frequency.daily: ('day', 'days'),
      Frequency.weekly: ('week', 'weeks'),
      Frequency.monthly: ('month', 'months'),
      Frequency.yearly: ('year', 'years'),
    };
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String ord(int n) => switch (n) {
          -1 => 'last',
          -2 => 'second to last',
          1 => '1st',
          2 => '2nd',
          3 => '3rd',
          _ => '${n}th',
        };
    final u = units[frequency]!;
    final b = StringBuffer(interval == 1 ? 'Every ${u.$1}' : 'Every $interval ${u.$2}');
    if (byMonths.isNotEmpty) {
      b.write(' in ${byMonths.map((m) => mn[m - 1]).join(', ')}');
    }
    if (byWeekdays.isNotEmpty) {
      final isWorkweek = byWeekdays.length == 5 && byWeekdays.every((w) => w.ordinal == null && w.weekday <= 5);
      b.write(isWorkweek
          ? ' on weekdays'
          : ' on ${byWeekdays.map((w) => w.ordinal == null ? wd[w.weekday - 1] : 'the ${ord(w.ordinal!)} ${wd[w.weekday - 1]}').join(', ')}');
    }
    if (byMonthDays.isNotEmpty) {
      b.write(' on day ${byMonthDays.map((d) => d < 0 ? ord(d) : '$d').join(', ')}');
    }
    if (bySetPositions.isNotEmpty) {
      b.write(' (${bySetPositions.map(ord).join(', ')} match)');
    }
    if (count != null) b.write(', ${count == 1 ? 'once' : '$count times'}');
    if (until != null) {
      b.write(', until ${until!.day} ${mn[until!.month - 1]} ${until!.year}');
    }
    return b.toString();
  }

  @override
  bool operator ==(Object other) => other is RecurrenceRule && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;
}

/// Formats [d] as an iCalendar DATE-TIME (`20261020T154100Z` for UTC,
/// floating local time otherwise) or DATE when [dateOnly].
String formatIcsDate(DateTime d, {bool dateOnly = false}) {
  String p(int v, [int n = 2]) => v.toString().padLeft(n, '0');
  final date = '${p(d.year, 4)}${p(d.month)}${p(d.day)}';
  if (dateOnly) return date;
  return '${date}T${p(d.hour)}${p(d.minute)}${p(d.second)}${d.isUtc ? 'Z' : ''}';
}

/// Parses an iCalendar DATE (`20261020`) or DATE-TIME
/// (`20261020T154100` / `...Z`).
DateTime parseIcsDate(String s) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$').firstMatch(s.trim());
  if (m == null) throw FormatException('Invalid iCalendar date', s);
  final parts = [for (var i = 1; i <= 6; i++) int.tryParse(m.group(i) ?? '') ?? 0];
  return m.group(7) == 'Z'
      ? DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5])
      : DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
}
