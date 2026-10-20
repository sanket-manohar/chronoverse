import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/calendar_event.dart';
import '../core/date_availability.dart';
import '../core/date_extensions.dart';
import '../core/date_range.dart';
import '../l10n/chrono_locale.dart';
import 'controller.dart';
import 'day_cell.dart';
import 'event_chips.dart';
import 'month_grid.dart';
import 'theme.dart';
import 'year_month_pickers.dart';

enum _PickerStage { days, months, years }

/// Builds a fully custom header. [title] is the localised "October 2026".
typedef ChronoHeaderBuilder = Widget Function(
    BuildContext context, DateTime focusedDay, String title, ChronoCalendarController controller);

/// The all-in-one month/week calendar.
///
/// * Swipe left/right (or use the arrows) to change month or week.
/// * Expandable: drag down or tap the handle to open the full month, drag up
///   to collapse to the week set by [ChronoCalendarController.showWeekOf].
/// * Tap the title to jump through a year grid and a month grid.
/// * Single, multiple and range selection, min/max dates, disabled days,
///   holidays, event dots, week numbers, keyboard arrows, RTL, 14 languages.
/// * Every pixel is themeable through [ChronoThemeData], and every part can
///   be replaced with a builder.
///
/// ```dart
/// ChronoCalendar(
///   mode: ChronoSelectionMode.range,
///   onRangeSelected: (range) => print(range),
/// )
/// ```
class ChronoCalendar extends StatefulWidget {
  /// Creates a calendar.
  const ChronoCalendar({
    super.key,
    this.controller,
    this.mode,
    this.initialFormat = ChronoCalendarFormat.month,
    this.initialDate,
    this.firstDay,
    this.lastDay,
    this.expandable = false,
    this.enabled = true,
    this.readOnly = false,
    this.availability,
    this.formatToggle = false,
    this.selectableDayPredicate,
    this.holidayPredicate,
    this.weekendDays,
    this.events,
    this.eventLoader,
    this.markerColor,
    this.onDaySelected,
    this.onDaysSelected,
    this.onRangeSelected,
    this.onDayLongPress,
    this.onPageChanged,
    this.onFormatChanged,
    this.firstDayOfWeek,
    this.locale,
    this.theme,
    this.nativeDigits = false,
    this.showHeader = true,
    this.showWeekdays = true,
    this.showWeekNumbers = false,
    this.showOutsideDays = true,
    this.showTodayButton = true,
    this.sixWeekMonths = false,
    this.swipeEnabled = true,
    this.quickPickers = true,
    this.maxRangeDays,
    this.headerBuilder,
    this.dayBuilder,
    this.dayLabelBuilder,
    this.weekdayBuilder,
    this.markerStyle = ChronoMarkerStyle.dots,
    this.chipStyle = const ChronoChipStyle(),
    this.itemLabel = chronoItemLabel,
    this.onItemTap,
    this.onDrop,
    this.canDrop,
  });

  /// Dots, bars or titled cards for events in each day.
  final ChronoMarkerStyle markerStyle;

  /// Card shape and size in chips mode.
  final ChronoChipStyle chipStyle;

  /// Title of each item in chips mode.
  final String Function(Object? item) itemLabel;

  /// Tap on an event card (chips mode).
  final ValueChanged<Object?>? onItemTap;

  /// Makes days drop targets: receives the day and whatever was dropped
  /// (an event card dragged from another day, or any [ChronoDragItem]).
  /// Update your data and rebuild with the new events.
  final void Function(DateTime day, Object data)? onDrop;

  /// Whether a drop is allowed on a day.
  final bool Function(DateTime day, Object data)? canDrop;

  /// Controller for navigation and selection from code.
  final ChronoCalendarController? controller;

  /// Selection mode (defaults to the controller's or single).
  final ChronoSelectionMode? mode;

  /// Starting format when no controller is given.
  final ChronoCalendarFormat initialFormat;

  /// Initially focused and selected day when no controller is given.
  final DateTime? initialDate;

  /// Earliest day (defaults to 1 Jan 1900).
  final DateTime? firstDay;

  /// Latest day (defaults to 31 Dec 2200).
  final DateTime? lastDay;

  /// Shows a handle and enables drag up/down between week and month.
  final bool expandable;

  /// False freezes the calendar: no taps, swipes or navigation, and every
  /// day is drawn disabled. Also controllable with
  /// [ChronoCalendarController.freeze].
  final bool enabled;

  /// Navigation still works but days cannot be selected and look normal.
  final bool readOnly;

  /// Blocked dates, ranges and weekdays, allow-lists, past/future blocking.
  final DateAvailability? availability;

  /// Shows a month/2 weeks/week toggle in the header.
  final bool formatToggle;

  /// Extra rule for which days can be picked (e.g. weekdays only).
  final ChronoDayPredicate? selectableDayPredicate;

  /// Marks holidays (shown in [ChronoThemeData.holidayTextColor]).
  final ChronoDayPredicate? holidayPredicate;

  /// Weekend days (defaults to the locale's).
  final Set<int>? weekendDays;

  /// Events to show as dots (repeating events are expanded automatically).
  final List<CalendarEvent<Object?>>? events;

  /// Alternative to [events]: return anything per day; each item is a dot.
  final ChronoEventLoader? eventLoader;

  /// Dot colour per item (events use their own colour by default).
  final ChronoMarkerColor? markerColor;

  /// Single mode: the picked day.
  final ValueChanged<DateTime>? onDaySelected;

  /// Multiple mode: all picked days.
  final ValueChanged<Set<DateTime>>? onDaysSelected;

  /// Range mode: the range once both ends are picked (null while picking).
  final ValueChanged<DateRange?>? onRangeSelected;

  /// Long press on a day.
  final ValueChanged<DateTime>? onDayLongPress;

  /// Swiped or navigated to a new month/week.
  final ValueChanged<DateTime>? onPageChanged;

  /// Expanded, collapsed or toggled the format.
  final ValueChanged<ChronoCalendarFormat>? onFormatChanged;

  /// First column ([DateTime.monday]..[DateTime.sunday]); defaults to the
  /// locale's.
  final int? firstDayOfWeek;

  /// Language override (defaults to the app's locale).
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// Use the locale's own digits (Arabic, Devanagari).
  final bool nativeDigits;

  /// Show the header with title and arrows.
  final bool showHeader;

  /// Show the weekday names row.
  final bool showWeekdays;

  /// Show ISO week numbers.
  final bool showWeekNumbers;

  /// Show neighbouring-month days.
  final bool showOutsideDays;

  /// Show a "Today" button in the header when not on today's page.
  final bool showTodayButton;

  /// Always show 6 rows so the height never changes between months.
  final bool sixWeekMonths;

  /// Allow horizontal swiping between pages.
  final bool swipeEnabled;

  /// Tap the title to choose a year and month from grids.
  final bool quickPickers;

  /// Longest range allowed in range mode (days beyond it are disabled
  /// while picking the end).
  final int? maxRangeDays;

  /// Replace the whole header.
  final ChronoHeaderBuilder? headerBuilder;

  /// Replace day cells (return null to keep the default for a day).
  final ChronoDayBuilder? dayBuilder;

  /// Small widget under each day number (prices, availability...).
  final ChronoDayLabelBuilder? dayLabelBuilder;

  /// Replace weekday labels.
  final Widget Function(BuildContext context, int weekday)? weekdayBuilder;

  @override
  State<ChronoCalendar> createState() => _ChronoCalendarState();
}

class _ChronoCalendarState extends State<ChronoCalendar> {
  late ChronoCalendarController _controller;
  bool _ownsController = false;
  late PageController _pages;
  late int _lastRequest;
  late ChronoCalendarFormat _lastFormat;
  _PickerStage _stage = _PickerStage.days;
  int _pickerYear = DateTime.now().year;
  final _focusNode = FocusNode(debugLabel: 'ChronoCalendar');

  DateTime get _first => (widget.firstDay ?? DateTime(1900)).dateOnly;
  DateTime get _last => (widget.lastDay ?? DateTime(2200, 12, 31)).dateOnly;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      if (widget.mode != null && widget.mode != _controller.mode) _controller.mode = widget.mode!;
    } else {
      _controller = ChronoCalendarController(
        focusedDay: widget.initialDate,
        selectedDay: widget.mode == null || widget.mode == ChronoSelectionMode.single ? widget.initialDate : null,
        format: widget.initialFormat,
        mode: widget.mode ?? ChronoSelectionMode.single,
      );
      _ownsController = true;
    }
    _lastRequest = _controller.pageRequest;
    _lastFormat = _controller.format;
    _pagesReady = false;
    _controller.addListener(_onController);
  }

  bool _pagesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first weekday can come from the locale, which needs context, so
    // the page controller is created here rather than in initState.
    if (!_pagesReady) {
      _pages = PageController(initialPage: _pageOfCtx(_controller.focusedDay));
      _pagesReady = true;
    }
  }

  @override
  void didUpdateWidget(ChronoCalendar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _controller.removeListener(_onController);
      if (_ownsController) _controller.dispose();
      _pages.dispose();
      _attach();
      _pages = PageController(initialPage: _pageOfCtx(_controller.focusedDay));
      _pagesReady = true;
    } else if (widget.mode != null && widget.mode != _controller.mode) {
      _controller.mode = widget.mode!;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    if (_ownsController) _controller.dispose();
    _pages.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _firstDow => widget.firstDayOfWeek ?? _locale.firstDayOfWeek;
  ChronoLocale get _locale => ChronoTheme.localeOf(context, widget.locale);

  int _pageOfCtx(DateTime day) => switch (_controller.format) {
        ChronoCalendarFormat.month => (day.year - _first.year) * 12 + day.month - _first.month,
        ChronoCalendarFormat.week => _first.startOfWeek(_firstDow).daysUntil(day.startOfWeek(_firstDow)) ~/ 7,
        ChronoCalendarFormat.twoWeeks => _first.startOfWeek(_firstDow).daysUntil(day.startOfWeek(_firstDow)) ~/ 14,
      };

  int get _pageCount => _pageOfCtx(_last) + 1;

  List<DateTime> _weeksForPage(int page) {
    switch (_controller.format) {
      case ChronoCalendarFormat.month:
        final month = DateTime(_first.year, _first.month + page);
        return monthWeekStarts(month, _firstDow, sixWeeks: widget.sixWeekMonths);
      case ChronoCalendarFormat.week:
        return [_first.startOfWeek(_firstDow).addWeeks(page)];
      case ChronoCalendarFormat.twoWeeks:
        final s = _first.startOfWeek(_firstDow).addWeeks(page * 2);
        return [s, s.addWeeks(1)];
    }
  }

  void _onController() {
    if (!mounted) return;
    if (_controller.format != _lastFormat) {
      _lastFormat = _controller.format;
      _lastRequest = _controller.pageRequest;
      _pages.dispose();
      _pages = PageController(initialPage: _pageOfCtx(_controller.focusedDay));
      widget.onFormatChanged?.call(_controller.format);
    } else if (_controller.pageRequest != _lastRequest) {
      _lastRequest = _controller.pageRequest;
      final target = _pageOfCtx(_controller.focusedDay).clamp(0, _pageCount - 1);
      if (_pages.hasClients && _pages.page?.round() != target) {
        final current = _pages.page?.round() ?? target;
        final t = ChronoTheme.of(context, widget.theme);
        if ((current - target).abs() <= 2) {
          _pages.animateToPage(target, duration: t.animationDuration, curve: t.animationCurve);
        } else {
          _pages.jumpToPage(target);
        }
      }
    }
    setState(() {});
  }

  void _onPageChanged(int page) {
    final weeks = _weeksForPage(page);
    final focused = switch (_controller.format) {
      ChronoCalendarFormat.month => DateTime(_first.year, _first.month + page),
      _ => _keepWeekday(weeks.first),
    };
    _controller.updateFocusFromView(focused);
    widget.onPageChanged?.call(focused);
  }

  DateTime _keepWeekday(DateTime weekStart) {
    final sel = _controller.selectedDay;
    if (sel != null && !sel.isBefore(weekStart) && sel.daysUntil(weekStart) > -7) return sel;
    return weekStart;
  }

  void _onDayTap(DateTime day) {
    final c = _controller;
    c.select(day);
    switch (c.mode) {
      case ChronoSelectionMode.single:
        widget.onDaySelected?.call(day);
      case ChronoSelectionMode.multiple:
        widget.onDaysSelected?.call(c.selectedDays);
      case ChronoSelectionMode.range:
        widget.onRangeSelected?.call(c.selectedRange);
      case ChronoSelectionMode.none:
        break;
    }
    if (c.format == ChronoCalendarFormat.month &&
        !day.isSameMonth(DateTime(_first.year, _first.month + (_pages.page?.round() ?? 0)))) {
      c.jumpTo(day);
    }
  }

  ChronoDayPredicate? get _rangeLimit {
    final max = widget.maxRangeDays;
    final c = _controller;
    if (max == null || c.mode != ChronoSelectionMode.range || c.rangeStart == null || c.rangeEnd != null) {
      return null;
    }
    return (d) => c.rangeStart!.daysUntil(d).abs() < max;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final base = _controller.selectedDay ?? _controller.focusedDay;
    final delta = switch (e.logicalKey) {
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => null,
    };
    if (delta != null) {
      final next = base.addDays(delta);
      if (_controller.mode == ChronoSelectionMode.single && next.isBetweenDays(_first, _last)) {
        _onDayTap(next);
        if (!_weeksForPage(_pages.page?.round() ?? 0).any((w) => next.isBetweenDays(w, w.addDays(6)))) {
          _controller.jumpTo(next);
        }
      } else {
        _controller.jumpTo(next);
      }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.pageUp) {
      _controller.previousPage();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.pageDown) {
      _controller.nextPage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, widget.theme);
    final l = _locale;
    final events = widget.events;
    final weekend = widget.weekendDays ?? l.weekendDays;
    final rangeLimit = _rangeLimit;
    final frozen = !widget.enabled || _controller.isFrozen;
    final interactive = !frozen && !widget.readOnly;
    final availability = widget.availability;
    final rules = ChronoDayRules(
      firstDay: _first,
      lastDay: _last,
      controller: _controller,
      selectableDayPredicate: (d) =>
          !frozen &&
          (availability?.isAvailable(d) ?? true) &&
          (widget.selectableDayPredicate?.call(d) ?? true) &&
          (rangeLimit?.call(d) ?? true),
      holidayPredicate: widget.holidayPredicate,
      weekendDays: weekend,
      eventLoader: widget.eventLoader ?? (events == null ? null : _indexedLoader(events)),
      markerColor:
          widget.markerColor ?? (e) => e is EventOccurrence && e.event.color != null ? Color(e.event.color!) : null,
      defaultMarkerColor: t.eventColor!,
    );

    final focused = _controller.focusedDay;
    final title = _controller.format == ChronoCalendarFormat.month ||
            focused.startOfWeek(_firstDow).isSameMonth(focused.endOfWeek(_firstDow))
        ? '${l.monthName(focused.month)} ${l.localizeDigits('${focused.year}', enabled: widget.nativeDigits)}'
        : '${l.monthName(focused.startOfWeek(_firstDow).month, short: true)} – ${l.monthName(focused.endOfWeek(_firstDow).month, short: true)} ${focused.endOfWeek(_firstDow).year}';

    final rows = _weeksForPage(_pageOfCtx(focused).clamp(0, _pageCount - 1)).length;
    final gridHeight = rows * t.cellHeight;

    Widget body;
    if (_stage == _PickerStage.months) {
      body = ChronoMonthPicker(
        year: _pickerYear,
        selectedMonth: focused,
        firstDay: _first,
        lastDay: _last,
        locale: l,
        theme: widget.theme,
        onYearChanged: (y) => setState(() => _pickerYear = y),
        onYearTap: () => setState(() => _stage = _PickerStage.years),
        onMonthSelected: (m) {
          setState(() => _stage = _PickerStage.days);
          _controller.jumpTo(m.clampTo(_first, _last));
        },
      );
    } else if (_stage == _PickerStage.years) {
      body = ChronoYearPicker(
        firstYear: _first.year,
        lastYear: _last.year,
        selectedYear: _pickerYear,
        locale: l,
        theme: widget.theme,
        onYearSelected: (y) => setState(() {
          _pickerYear = y;
          _stage = _PickerStage.months;
        }),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showWeekdays)
            ChronoWeekdayRow(
              firstDayOfWeek: _firstDow,
              locale: l,
              theme: t,
              showWeekNumbers: widget.showWeekNumbers,
              weekendDays: weekend,
              builder: widget.weekdayBuilder,
            ),
          GestureDetector(
            onVerticalDragEnd: widget.expandable && !frozen
                ? (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v > 150 && !_controller.isExpanded) _controller.expand();
                    if (v < -150 && _controller.isExpanded) _controller.collapse();
                  }
                : null,
            child: AnimatedContainer(
              duration: t.animationDuration,
              curve: t.animationCurve,
              height: gridHeight,
              // Mouse and stylus can swipe pages too, not only touch.
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                child: PageView.builder(
                  key: ValueKey(_controller.format),
                  controller: _pages,
                  physics:
                      widget.swipeEnabled && !frozen ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
                  itemCount: _pageCount,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, page) => OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: ChronoWeeksGrid(
                      weekStarts: _weeksForPage(page),
                      rules: rules,
                      theme: t,
                      locale: l,
                      month: _controller.format == ChronoCalendarFormat.month
                          ? DateTime(_first.year, _first.month + page)
                          : null,
                      showOutsideDays: widget.showOutsideDays,
                      showWeekNumbers: widget.showWeekNumbers,
                      nativeDigits: widget.nativeDigits,
                      onDayTap:
                          !interactive || (_controller.mode == ChronoSelectionMode.none && widget.onDaySelected == null)
                              ? null
                              : _onDayTap,
                      onDayLongPress: interactive ? widget.onDayLongPress : null,
                      dayBuilder: widget.dayBuilder,
                      dayLabelBuilder: widget.dayLabelBuilder,
                      markerStyle: widget.markerStyle,
                      chipStyle: widget.chipStyle,
                      itemLabel: widget.itemLabel,
                      onItemTap: interactive ? widget.onItemTap : null,
                      onDrop: interactive ? widget.onDrop : null,
                      canDrop: widget.canDrop,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.expandable && !frozen) _handle(t),
        ],
      );
    }

    return Focus(
      focusNode: _focusNode,
      canRequestFocus: interactive,
      onKeyEvent: interactive ? _onKey : null,
      child: Container(
        decoration: t.decoration ?? BoxDecoration(color: t.backgroundColor),
        clipBehavior: t.decoration == null ? Clip.none : Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showHeader)
              widget.headerBuilder?.call(context, focused, title, _controller) ??
                  IgnorePointer(
                    ignoring: frozen,
                    child: Opacity(opacity: frozen ? 0.5 : 1, child: _header(t, l, title)),
                  ),
            AnimatedSize(
              duration: t.animationDuration,
              curve: t.animationCurve,
              alignment: Alignment.topCenter,
              child: body,
            ),
          ],
        ),
      ),
    );
  }

  // Expanding every event for every cell is slow with many or repeating
  // events, so occurrences are indexed once for the months around the
  // focused one and reused until the events or the window change.
  List<CalendarEvent<Object?>>? _indexedEvents;
  DateRange? _indexWindow;
  Map<DateTime, List<EventOccurrence<Object?>>> _index = const {};

  ChronoEventLoader _indexedLoader(List<CalendarEvent<Object?>> events) {
    final f = _controller.focusedDay;
    final window = DateRange(f.startOfMonth.addMonths(-1).addDays(-7), f.endOfMonth.addMonths(1).addDays(14));
    final covered = _indexWindow != null && _indexWindow!.contains(window.start) && _indexWindow!.contains(window.end);
    if (!identical(events, _indexedEvents) || !covered) {
      _indexedEvents = events;
      _indexWindow = DateRange(window.start.addMonths(-2), window.end.addMonths(2));
      _index = events.groupByDay(_indexWindow!);
    }
    return (d) => _index[DateTime(d.year, d.month, d.day)] ?? const [];
  }

  Widget _handle(ChronoThemeData t) => Semantics(
        button: true,
        label: _controller.isExpanded ? 'Collapse calendar' : 'Expand calendar',
        child: InkWell(
          onTap: _controller.toggleExpanded,
          child: SizedBox(
            height: 22,
            child: Center(
              child: AnimatedRotation(
                turns: _controller.isExpanded ? 0.5 : 0,
                duration: t.animationDuration,
                child: Icon(Icons.keyboard_arrow_down, size: 20, color: t.mutedTextColor),
              ),
            ),
          ),
        ),
      );

  Widget _header(ChronoThemeData t, ChronoLocale l, String title) {
    final onToday = _weeksForPage(_pageOfCtx(_controller.focusedDay).clamp(0, _pageCount - 1))
        .any((w) => DateTime.now().isBetweenDays(w, w.addDays(6)));
    final inDays = _stage == _PickerStage.days;
    return SizedBox(
      height: t.headerHeight,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: widget.quickPickers
                    ? () => setState(() {
                          _pickerYear = _controller.focusedDay.year;
                          _stage = inDays ? _PickerStage.months : _PickerStage.days;
                        })
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(title, style: t.headerTextStyle, overflow: TextOverflow.ellipsis)),
                    if (widget.quickPickers)
                      AnimatedRotation(
                        turns: inDays ? 0 : 0.5,
                        duration: t.animationDuration,
                        child: Icon(Icons.arrow_drop_down, color: t.textColor),
                      ),
                  ]),
                ),
              ),
            ),
          ),
          if (widget.showTodayButton && inDays && !onToday)
            TextButton(onPressed: _controller.today, child: Text(l.strings.today)),
          if (widget.formatToggle && inDays)
            IconButton(
              tooltip: _controller.format.name,
              icon: Icon(switch (_controller.format) {
                ChronoCalendarFormat.month => Icons.calendar_view_month,
                ChronoCalendarFormat.twoWeeks => Icons.view_agenda_outlined,
                ChronoCalendarFormat.week => Icons.calendar_view_week,
              }),
              onPressed: () => _controller.setFormat(
                  ChronoCalendarFormat.values[(_controller.format.index + 1) % ChronoCalendarFormat.values.length]),
            ),
          if (inDays) ...[
            IconButton(
              tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
              icon: const Icon(Icons.chevron_left),
              onPressed: _controller.focusedDay.isSameMonth(_first) && _controller.isExpanded
                  ? null
                  : _controller.previousPage,
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  _controller.focusedDay.isSameMonth(_last) && _controller.isExpanded ? null : _controller.nextPage,
            ),
          ],
        ],
      ),
    );
  }
}
