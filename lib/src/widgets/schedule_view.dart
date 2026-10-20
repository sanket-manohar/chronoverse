import 'dart:async';

import 'package:flutter/material.dart';

import '../core/calendar_event.dart';
import '../core/date_extensions.dart';
import '../core/date_math.dart';
import '../core/date_range.dart';
import '../l10n/chrono_locale.dart';
import 'theme.dart';

/// Builds an event tile in [ChronoScheduleView].
typedef ChronoEventTileBuilder = Widget Function(BuildContext context, EventOccurrence<Object?> occurrence, Size size);

/// Called when an event was dragged or resized to a new time.
typedef ChronoEventMoved = void Function(EventOccurrence<Object?> occurrence, DateTime newStart, DateTime newEnd);

/// A time grid for one or more days (day view, 3-day view, week view, work
/// week) with overlapping events laid out side by side, an all-day row, a
/// live "now" line, tap-to-create on empty slots, and drag to move or
/// resize events.
class ChronoScheduleView extends StatefulWidget {
  /// Creates a schedule view starting at [date].
  const ChronoScheduleView({
    super.key,
    required this.date,
    this.events = const [],
    this.numberOfDays = 1,
    this.startHour = 0,
    this.endHour = 24,
    this.hourHeight = 60,
    this.snap = const Duration(minutes: 15),
    this.timeColumnWidth = 56,
    this.use24HourFormat,
    this.showNowIndicator = true,
    this.showAllDayRow = true,
    this.enableDrag = true,
    this.enableResize = true,
    this.workHours,
    this.blockedSlots = const [],
    this.onEventTap,
    this.onEventMoved,
    this.onSlotTap,
    this.onSlotLongPress,
    this.eventTileBuilder,
    this.locale,
    this.theme,
    this.initialScrollHour,
  });

  /// First day shown (week views usually pass the start of the week).
  final DateTime date;

  /// Events (repeating events are expanded).
  final List<CalendarEvent<Object?>> events;

  /// Days side by side: 1 day, 3 days, 5 (work week), 7 (week)...
  final int numberOfDays;

  /// First hour on the grid.
  final int startHour;

  /// Last hour on the grid (exclusive).
  final int endHour;

  /// Pixels per hour.
  final double hourHeight;

  /// Drag/tap snapping step.
  final Duration snap;

  /// Width of the hour labels.
  final double timeColumnWidth;

  /// 24-hour labels (defaults to the platform setting).
  final bool? use24HourFormat;

  /// Red line at the current time.
  final bool showNowIndicator;

  /// Row for all-day events.
  final bool showAllDayRow;

  /// Long-press and drag events to move them.
  final bool enableDrag;

  /// Drag the bottom edge to resize.
  final bool enableResize;

  /// Hours outside this range are shaded, e.g. `(9, 18)`.
  final (int, int)? workHours;

  /// Time ranges that are shaded and cannot be tapped (breaks, bookings).
  final List<DateRangeTime> blockedSlots;

  /// Tap on an event.
  final ValueChanged<EventOccurrence<Object?>>? onEventTap;

  /// An event was dropped at a new time; update your data source.
  final ChronoEventMoved? onEventMoved;

  /// Tap on an empty slot (snapped start time).
  final ValueChanged<DateTime>? onSlotTap;

  /// Long press on an empty slot.
  final ValueChanged<DateTime>? onSlotLongPress;

  /// Custom event tile.
  final ChronoEventTileBuilder? eventTileBuilder;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// Hour to scroll to first (current hour − 1 by default).
  final int? initialScrollHour;

  @override
  State<ChronoScheduleView> createState() => _ChronoScheduleViewState();
}

class _ChronoScheduleViewState extends State<ChronoScheduleView> {
  late final ScrollController _scroll;
  Timer? _ticker;
  // Live preview while dragging.
  EventOccurrence<Object?>? _dragging;
  DateTime? _previewStart;
  DateTime? _previewEnd;
  double _dragDy = 0;
  int _dragDayShift = 0;

  @override
  void initState() {
    super.initState();
    final hour = (widget.initialScrollHour ?? DateTime.now().hour - 1).clamp(widget.startHour, widget.endHour);
    _scroll = ScrollController(initialScrollOffset: (hour - widget.startHour) * widget.hourHeight);
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  List<DateTime> get _days => [for (var i = 0; i < widget.numberOfDays; i++) widget.date.dateOnly.addDays(i)];

  double _y(DateTime t, DateTime day) {
    final minutes = day.daysUntil(t) * 1440 + t.hour * 60 + t.minute - widget.startHour * 60;
    return minutes / 60 * widget.hourHeight;
  }

  DateTime _timeAt(DateTime day, double dy) {
    final minutes = (dy / widget.hourHeight * 60).round() + widget.startHour * 60;
    final t = day.add(Duration(minutes: minutes));
    return DateMath.floorTo(t, widget.snap);
  }

  bool _isBlocked(DateTime t) => widget.blockedSlots.any((b) => !t.isBefore(b.start) && t.isBefore(b.end));

  String _hourLabel(BuildContext context, int h, ChronoLocale l) {
    final use24 = widget.use24HourFormat ?? MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
    if (use24) return '${h.toString().padLeft(2, '0')}:00';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12 ${l.amPm[h < 12 ? 0 : 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, widget.theme);
    final l = ChronoTheme.localeOf(context, widget.locale);
    final days = _days;
    final range = DateRange(days.first, days.last);
    final byDay = widget.events.groupByDay(range);
    final hours = widget.endHour - widget.startHour;
    final gridHeight = hours * widget.hourHeight;

    final allDay = <EventOccurrence<Object?>>{
      for (final d in days)
        ...?byDay[d]?.where((o) => o.event.isAllDay || o.event.isMultiDay && o.end.difference(o.start).inHours >= 24),
    }.toList();

    return Column(
      children: [
        // Day headers
        Row(children: [
          SizedBox(width: widget.timeColumnWidth),
          for (final d in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Text(l.weekdayName(d.weekday, style: WeekdayStyle.short),
                      style: t.weekdayTextStyle!.copyWith(color: d.isToday ? t.todayColor : null)),
                  const SizedBox(height: 2),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: d.isToday ? t.primaryColor : null,
                      shape: t.dayShapeBorder(),
                    ),
                    child: Text(l.localizeDigits('${d.day}'),
                        style: t.dayTextStyle!
                            .copyWith(color: d.isToday ? t.onPrimaryColor : t.textColor, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
        ]),
        if (widget.showAllDayRow && allDay.isNotEmpty)
          _AllDayRow(
            days: days,
            occurrences: allDay,
            timeColumnWidth: widget.timeColumnWidth,
            theme: t,
            label: l.strings.allDay,
            onTap: widget.onEventTap,
          ),
        Divider(height: 1, color: t.borderColor),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              height: gridHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: widget.timeColumnWidth,
                    child: Stack(children: [
                      for (var h = 1; h < hours; h++)
                        Positioned(
                          top: h * widget.hourHeight - 7,
                          right: 6,
                          child: Text(_hourLabel(context, widget.startHour + h, l),
                              style: t.weekdayTextStyle!.copyWith(fontSize: 10)),
                        ),
                    ]),
                  ),
                  for (var i = 0; i < days.length; i++)
                    Expanded(child: _dayColumn(context, t, days[i], i, byDay[days[i]] ?? const [], gridHeight)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(BuildContext context, ChronoThemeData t, DateTime day, int index,
      List<EventOccurrence<Object?>> items, double height) {
    final timed = items.where((o) => !o.event.isAllDay && o.end.difference(o.start).inHours < 24).toList();
    final layout = Schedule.layoutColumns(timed);
    final hours = widget.endHour - widget.startHour;
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onSlotTap == null
            ? null
            : (d) {
                final time = _timeAt(day, d.localPosition.dy);
                if (!_isBlocked(time)) widget.onSlotTap!(time);
              },
        onLongPressStart: widget.onSlotLongPress == null
            ? null
            : (d) {
                final time = _timeAt(day, d.localPosition.dy);
                if (!_isBlocked(time)) widget.onSlotLongPress!(time);
              },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Hour lines and shading
            for (var h = 0; h < hours; h++)
              Positioned(
                top: h * widget.hourHeight,
                left: 0,
                right: 0,
                height: widget.hourHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.workHours != null &&
                            (widget.startHour + h < widget.workHours!.$1 ||
                                widget.startHour + h >= widget.workHours!.$2)
                        ? t.borderColor!.withValues(alpha: 0.18)
                        : null,
                    border: Border(
                      top: BorderSide(color: t.borderColor!.withValues(alpha: 0.6), width: 0.5),
                      left: BorderSide(color: t.borderColor!.withValues(alpha: 0.6), width: 0.5),
                    ),
                  ),
                ),
              ),
            for (final b in widget.blockedSlots)
              if (b.end.isAfter(day) && b.start.isBefore(day.addDays(1)))
                Positioned(
                  top: _y(maxDate(b.start, day), day).clamp(0, height),
                  height: (_y(minDate(b.end, day.addDays(1)), day) - _y(maxDate(b.start, day), day)).clamp(0, height),
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(color: t.disabledColor!.withValues(alpha: 0.15)),
                  ),
                ),
            for (final o in timed) _eventTile(context, t, o, day, index, width, layout[o]!, height),
            if (_dragging != null && _previewStart != null && _previewStart!.isSameDay(day))
              Positioned(
                top: _y(_previewStart!, day),
                height: (_y(_previewEnd!, day) - _y(_previewStart!, day)).clamp(16, height),
                left: 2,
                right: 2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: t.primaryColor!, width: 2),
                      borderRadius: BorderRadius.circular(6),
                      color: t.primaryColor!.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            if (widget.showNowIndicator && day.isToday)
              Positioned(
                top: _y(DateTime.now(), day) - 4,
                left: -4,
                right: 0,
                child: IgnorePointer(
                  child: Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: t.holidayTextColor, shape: BoxShape.circle),
                    ),
                    Expanded(child: Container(height: 1.5, color: t.holidayTextColor)),
                  ]),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _eventTile(BuildContext context, ChronoThemeData t, EventOccurrence<Object?> o, DateTime day, int dayIndex,
      double width, ({int column, int columns}) slot, double height) {
    final start = maxDate(o.start, day.add(Duration(hours: widget.startHour)));
    final end = minDate(o.end, day.add(Duration(hours: widget.endHour)));
    final top = _y(start, day);
    final h = (_y(end, day) - top).clamp(18.0, height);
    final colW = width / slot.columns;
    final color = o.event.color != null ? Color(o.event.color!) : t.eventColor!;
    final size = Size(colW - 2, h - 2);
    final faded = _dragging == o;
    final tentative = o.event.status == EventStatus.tentative;

    Widget tile = widget.eventTileBuilder?.call(context, o, size) ??
        Container(
          padding: h < 30 ? const EdgeInsets.symmetric(horizontal: 4) : const EdgeInsets.fromLTRB(6, 3, 4, 2),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: tentative ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(6),
            border: tentative ? Border.all(color: color, width: 1.2) : null,
          ),
          child: DefaultTextStyle(
            style: t.dayTextStyle!.copyWith(
                fontSize: 12,
                color: tentative
                    ? color
                    : ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
            overflow: TextOverflow.ellipsis,
            child: OverflowBox(
              alignment: AlignmentDirectional.topStart,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.event.title,
                      maxLines: h > 40 ? 2 : 1,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: h < 30 ? 10 : 12)),
                  if (h > 36)
                    Text(
                      '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(o.start))} – '
                      '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(o.end))}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  if (h > 56 && o.event.location != null) Text(o.event.location!, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        );

    tile = Semantics(
      button: true,
      label: o.event.title,
      child: GestureDetector(
        onTap: widget.onEventTap == null ? null : () => widget.onEventTap!(o),
        onLongPressStart: widget.enableDrag && widget.onEventMoved != null
            ? (_) => setState(() {
                  _dragging = o;
                  _dragDy = 0;
                  _dragDayShift = 0;
                  _previewStart = o.start;
                  _previewEnd = o.end;
                })
            : null,
        onLongPressMoveUpdate: widget.enableDrag && widget.onEventMoved != null
            ? (d) => setState(() {
                  _dragDy = d.offsetFromOrigin.dy;
                  _dragDayShift =
                      (d.offsetFromOrigin.dx / width).round().clamp(-dayIndex, widget.numberOfDays - 1 - dayIndex);
                  final minutes = (_dragDy / widget.hourHeight * 60).round();
                  final s =
                      DateMath.roundTo(o.start.add(Duration(minutes: minutes)).addDays(_dragDayShift), widget.snap);
                  _previewStart = s;
                  _previewEnd = s.add(o.end.difference(o.start));
                })
            : null,
        onLongPressEnd: widget.enableDrag && widget.onEventMoved != null
            ? (_) {
                final s = _previewStart, e = _previewEnd;
                setState(() => _dragging = null);
                if (s != null && e != null && s != o.start) widget.onEventMoved!(o, s, e);
              }
            : null,
        child: Opacity(opacity: faded ? 0.4 : 1, child: tile),
      ),
    );

    return Positioned(
      top: top + 1,
      left: slot.column * colW + 1,
      width: colW - 2,
      height: h - 2,
      child: Stack(
        children: [
          Positioned.fill(child: tile),
          if (widget.enableResize && widget.onEventMoved != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) => setState(() {
                    _dragging = o;
                    _previewStart = o.start;
                    _previewEnd = o.end;
                    _dragDy = 0;
                  }),
                  onVerticalDragUpdate: (d) => setState(() {
                    _dragDy += d.delta.dy;
                    final minutes = (_dragDy / widget.hourHeight * 60).round();
                    final e = DateMath.roundTo(o.end.add(Duration(minutes: minutes)), widget.snap);
                    _previewEnd = e.isAfter(o.start.add(widget.snap)) ? e : o.start.add(widget.snap);
                  }),
                  onVerticalDragEnd: (_) {
                    final e = _previewEnd;
                    setState(() => _dragging = null);
                    if (e != null && e != o.end) widget.onEventMoved!(o, o.start, e);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllDayRow extends StatelessWidget {
  const _AllDayRow({
    required this.days,
    required this.occurrences,
    required this.timeColumnWidth,
    required this.theme,
    required this.label,
    this.onTap,
  });

  final List<DateTime> days;
  final List<EventOccurrence<Object?>> occurrences;
  final double timeColumnWidth;
  final ChronoThemeData theme;
  final String label;
  final ValueChanged<EventOccurrence<Object?>>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 6),
              child: Text(label, textAlign: TextAlign.end, style: t.weekdayTextStyle!.copyWith(fontSize: 10)),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final dayW = box.maxWidth / days.length;
              return Column(children: [
                for (final o in occurrences)
                  () {
                    final first = days.indexWhere((d) => o.coversDay(d));
                    final last = days.lastIndexWhere((d) => o.coversDay(d));
                    final color = o.event.color != null ? Color(o.event.color!) : t.eventColor!;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(start: first * dayW, top: 2),
                      child: GestureDetector(
                        onTap: onTap == null ? null : () => onTap!(o),
                        child: Container(
                          width: (last - first + 1) * dayW - 2,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          child: Text(o.event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.dayTextStyle!.copyWith(
                                  fontSize: 11,
                                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87)),
                        ),
                      ),
                    );
                  }(),
              ]);
            }),
          ),
        ],
      ),
    );
  }
}
