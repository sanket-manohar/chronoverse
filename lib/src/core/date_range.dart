import 'date_extensions.dart';

/// An inclusive range of calendar days, from [start] to [end].
///
/// Both ends are normalised to midnight, and [start] is never after [end].
class DateRange {
  /// Creates a range; the two dates are swapped if given in reverse order.
  factory DateRange(DateTime a, DateTime b) {
    final x = a.dateOnly, y = b.dateOnly;
    return x.isAfter(y) ? DateRange._(y, x) : DateRange._(x, y);
  }

  const DateRange._(this.start, this.end);

  /// A single-day range.
  factory DateRange.day(DateTime day) => DateRange(day, day);

  /// The week containing [day].
  factory DateRange.week(DateTime day, [int firstDayOfWeek = DateTime.monday]) =>
      DateRange(day.startOfWeek(firstDayOfWeek), day.endOfWeek(firstDayOfWeek));

  /// The month containing [day].
  factory DateRange.month(DateTime day) => DateRange(day.startOfMonth, day.endOfMonth);

  /// The year containing [day].
  factory DateRange.year(DateTime day) => DateRange(day.startOfYear, day.endOfYear);

  /// First day, at midnight.
  final DateTime start;

  /// Last day, at midnight (inclusive).
  final DateTime end;

  /// Number of days in the range, counting both ends.
  int get lengthInDays => start.daysUntil(end) + 1;

  /// Whether [day] falls in the range.
  bool contains(DateTime day) => day.isBetweenDays(start, end);

  /// Whether this range shares at least one day with [other].
  bool overlaps(DateRange other) => !end.isBefore(other.start) && !other.end.isBefore(start);

  /// The days both ranges share, or null when they don't overlap.
  DateRange? intersection(DateRange other) =>
      overlaps(other) ? DateRange(maxDate(start, other.start), minDate(end, other.end)) : null;

  /// The smallest range covering both.
  DateRange union(DateRange other) => DateRange(minDate(start, other.start), maxDate(end, other.end));

  /// Every day in the range, in order.
  Iterable<DateTime> get days sync* {
    for (var d = start; !d.isAfter(end); d = d.addDays(1)) {
      yield d;
    }
  }

  /// Range moved by [days] days.
  DateRange shift(int days) => DateRange(start.addDays(days), end.addDays(days));

  @override
  bool operator ==(Object other) => other is DateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange(${_iso(start)} – ${_iso(end)})';

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
