import 'date_extensions.dart';
import 'date_range.dart';

/// Which days can be picked: combine blocked dates, blocked ranges, blocked
/// weekdays, an allow-list and your own rule. Pure Dart, so the same rules
/// can be validated on a server.
///
/// ```dart
/// final rules = DateAvailability(
///   disabledWeekdays: {DateTime.sunday},
///   disabledDates: [DateTime(2026, 12, 25)],
///   disabledRanges: [DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 15))],
/// );
/// rules.isAvailable(DateTime(2026, 12, 25)); // false
/// ```
class DateAvailability {
  /// Creates availability rules. Everything is available by default.
  const DateAvailability({
    this.disabledDates = const [],
    this.disabledRanges = const [],
    this.disabledWeekdays = const {},
    this.enabledDates,
    this.disablePast = false,
    this.disableFuture = false,
    this.predicate,
  });

  /// Specific days that cannot be picked.
  final List<DateTime> disabledDates;

  /// Ranges that cannot be picked (e.g. a fully booked week).
  final List<DateRange> disabledRanges;

  /// Weekdays that cannot be picked ([DateTime.monday]..[DateTime.sunday]).
  final Set<int> disabledWeekdays;

  /// When set, only these days can be picked.
  final List<DateTime>? enabledDates;

  /// Block every day before today.
  final bool disablePast;

  /// Block every day after today.
  final bool disableFuture;

  /// Extra rule; return false to block a day.
  final bool Function(DateTime day)? predicate;

  /// Whether [day] can be picked.
  bool isAvailable(DateTime day) {
    final today = DateTime.now();
    if (disablePast && day.dateOnly.isBefore(today.dateOnly)) return false;
    if (disableFuture && day.dateOnly.isAfter(today.dateOnly)) return false;
    if (disabledWeekdays.contains(day.weekday)) return false;
    if (disabledDates.any(day.isSameDay)) return false;
    if (disabledRanges.any((r) => r.contains(day))) return false;
    final allow = enabledDates;
    if (allow != null && !allow.any(day.isSameDay)) return false;
    return predicate?.call(day) ?? true;
  }

  /// Whether every day of [range] is available (useful for bookings).
  bool isRangeAvailable(DateRange range) => range.days.every(isAvailable);

  /// The first available day on or after [from], searching up to
  /// [maxDays] days ahead; null when none is found.
  DateTime? nextAvailable(DateTime from, {int maxDays = 3660}) {
    for (var i = 0; i <= maxDays; i++) {
      final d = from.dateOnly.addDays(i);
      if (isAvailable(d)) return d;
    }
    return null;
  }
}
