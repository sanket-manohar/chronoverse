import 'package:flutter/foundation.dart';

import '../core/date_extensions.dart';
import '../core/date_range.dart';

/// How a calendar lets people pick days.
enum ChronoSelectionMode {
  /// Display only.
  none,

  /// One day.
  single,

  /// Any number of separate days.
  multiple,

  /// A start and an end day.
  range,
}

/// How many rows the month grid shows.
enum ChronoCalendarFormat {
  /// Whole month (5–6 rows).
  month,

  /// Two weeks.
  twoWeeks,

  /// One week.
  week,
}

/// Drives a [ChronoCalendar] from code: navigate, select, expand/collapse.
///
/// ```dart
/// final controller = ChronoCalendarController(format: ChronoCalendarFormat.week);
/// controller.showWeekOf(DateTime(2026, 12, 24)); // focus a week
/// controller.expand();                           // open the full month
/// controller.nextPage();
/// ```
class ChronoCalendarController extends ChangeNotifier {
  /// Creates a controller.
  ChronoCalendarController({
    DateTime? focusedDay,
    ChronoCalendarFormat format = ChronoCalendarFormat.month,
    ChronoSelectionMode mode = ChronoSelectionMode.single,
    DateTime? selectedDay,
    Set<DateTime>? selectedDays,
    DateRange? selectedRange,
  })  : _focusedDay = (focusedDay ?? selectedDay ?? DateTime.now()).dateOnly,
        _format = format,
        _mode = mode,
        _selectedDay = selectedDay?.dateOnly,
        _selectedDays = {...?selectedDays?.map((d) => d.dateOnly)},
        _rangeStart = selectedRange?.start,
        _rangeEnd = selectedRange?.end;

  DateTime _focusedDay;
  ChronoCalendarFormat _format;
  ChronoSelectionMode _mode;
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDays;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int _pageRequest = 0;
  bool _frozen = false;

  /// Whether the calendar is frozen: nothing can be tapped, swiped or
  /// navigated, and days are drawn as disabled.
  bool get isFrozen => _frozen;

  /// Freezes the calendar (see [isFrozen]).
  void freeze() => _setFrozen(true);

  /// Unfreezes the calendar.
  void unfreeze() => _setFrozen(false);

  void _setFrozen(bool value) {
    if (value == _frozen) return;
    _frozen = value;
    notifyListeners();
  }

  /// The day whose month or week is on screen.
  DateTime get focusedDay => _focusedDay;

  /// Current format (month, two weeks, week).
  ChronoCalendarFormat get format => _format;

  /// Current selection mode.
  ChronoSelectionMode get mode => _mode;

  /// Selected day in [ChronoSelectionMode.single].
  DateTime? get selectedDay => _selectedDay;

  /// Selected days in [ChronoSelectionMode.multiple].
  Set<DateTime> get selectedDays => Set.unmodifiable(_selectedDays);

  /// First day of the range being picked (end may still be null).
  DateTime? get rangeStart => _rangeStart;

  /// Last day of the range being picked.
  DateTime? get rangeEnd => _rangeEnd;

  /// The complete range, or null while only the start is picked.
  DateRange? get selectedRange => _rangeStart != null && _rangeEnd != null ? DateRange(_rangeStart!, _rangeEnd!) : null;

  /// Increments whenever code asks the view to animate to [focusedDay].
  int get pageRequest => _pageRequest;

  /// Whether the full month is showing.
  bool get isExpanded => _format == ChronoCalendarFormat.month;

  set mode(ChronoSelectionMode value) {
    if (value == _mode) return;
    _mode = value;
    clearSelection();
  }

  /// Shows the month or week containing [day].
  void jumpTo(DateTime day) {
    _focusedDay = day.dateOnly;
    _pageRequest++;
    notifyListeners();
  }

  /// Focuses today.
  void today() => jumpTo(DateTime.now());

  /// Moves one page forward (a month, two weeks or a week).
  void nextPage() => jumpTo(_step(1));

  /// Moves one page back.
  void previousPage() => jumpTo(_step(-1));

  DateTime _step(int dir) => switch (_format) {
        ChronoCalendarFormat.month => _focusedDay.startOfMonth.addMonths(dir),
        ChronoCalendarFormat.twoWeeks => _focusedDay.addWeeks(2 * dir),
        ChronoCalendarFormat.week => _focusedDay.addWeeks(dir),
      };

  /// Changes the format.
  void setFormat(ChronoCalendarFormat format) {
    if (format == _format) return;
    _format = format;
    _pageRequest++;
    notifyListeners();
  }

  /// Collapses to the week containing [day] (the selected or focused day by
  /// default).
  void showWeekOf([DateTime? day]) {
    _focusedDay = (day ?? _selectedDay ?? _focusedDay).dateOnly;
    _format = ChronoCalendarFormat.week;
    _pageRequest++;
    notifyListeners();
  }

  /// Opens the full month.
  void expand() => setFormat(ChronoCalendarFormat.month);

  /// Collapses to one week.
  void collapse() => showWeekOf();

  /// Toggles between month and week.
  void toggleExpanded() => isExpanded ? collapse() : expand();

  /// Selects [day] according to [mode]. In range mode the first tap sets
  /// the start, the second the end (swapping if needed), a third restarts.
  void select(DateTime day) {
    final d = day.dateOnly;
    switch (_mode) {
      case ChronoSelectionMode.none:
        return;
      case ChronoSelectionMode.single:
        _selectedDay = d;
      case ChronoSelectionMode.multiple:
        if (!_selectedDays.remove(d)) _selectedDays.add(d);
      case ChronoSelectionMode.range:
        if (_rangeStart == null || _rangeEnd != null) {
          _rangeStart = d;
          _rangeEnd = null;
        } else if (d.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = d;
        } else {
          _rangeEnd = d;
        }
    }
    _focusedDay = d;
    notifyListeners();
  }

  /// Sets a range directly.
  void selectRange(DateRange? range) {
    _rangeStart = range?.start;
    _rangeEnd = range?.end;
    if (range != null) _focusedDay = range.start;
    _pageRequest++;
    notifyListeners();
  }

  /// Replaces the multiple-selection set.
  void selectDays(Iterable<DateTime> days) {
    _selectedDays
      ..clear()
      ..addAll(days.map((d) => d.dateOnly));
    notifyListeners();
  }

  /// Clears every selection.
  void clearSelection() {
    _selectedDay = null;
    _selectedDays.clear();
    _rangeStart = null;
    _rangeEnd = null;
    notifyListeners();
  }

  /// Whether [day] is selected in the current mode.
  bool isSelected(DateTime day) => switch (_mode) {
        ChronoSelectionMode.none => false,
        ChronoSelectionMode.single => day.isSameDay(_selectedDay),
        ChronoSelectionMode.multiple => _selectedDays.contains(day.dateOnly),
        ChronoSelectionMode.range => day.isSameDay(_rangeStart) || day.isSameDay(_rangeEnd),
      };

  /// Internal: the view swiped to a new page.
  void updateFocusFromView(DateTime day) {
    if (day.isSameDay(_focusedDay)) return;
    _focusedDay = day.dateOnly;
    notifyListeners();
  }
}
