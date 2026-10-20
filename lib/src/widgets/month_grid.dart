import 'package:flutter/material.dart';

import '../core/date_extensions.dart';
import '../l10n/chrono_locale.dart';
import 'controller.dart';
import 'day_cell.dart';
import 'event_chips.dart';
import 'theme.dart';

/// Returns the events (or any objects) on [day]; each draws one marker.
typedef ChronoEventLoader = List<Object?> Function(DateTime day);

/// Decides whether [day] can be selected.
typedef ChronoDayPredicate = bool Function(DateTime day);

/// Picks a marker colour for an event returned by a [ChronoEventLoader].
typedef ChronoMarkerColor = Color? Function(Object? event);

/// Shared rules that turn a date into a [ChronoDayState]. Used internally by
/// every grid-style view so they behave identically.
class ChronoDayRules {
  /// Creates rules.
  const ChronoDayRules({
    required this.firstDay,
    required this.lastDay,
    this.controller,
    this.selectableDayPredicate,
    this.holidayPredicate,
    this.weekendDays = const {DateTime.saturday, DateTime.sunday},
    this.eventLoader,
    this.markerColor,
    this.defaultMarkerColor = Colors.blue,
  });

  /// Earliest selectable day.
  final DateTime firstDay;

  /// Latest selectable day.
  final DateTime lastDay;

  /// Selection source.
  final ChronoCalendarController? controller;

  /// Extra selectable rule.
  final ChronoDayPredicate? selectableDayPredicate;

  /// Holiday rule.
  final ChronoDayPredicate? holidayPredicate;

  /// Weekend days.
  final Set<int> weekendDays;

  /// Events per day.
  final ChronoEventLoader? eventLoader;

  /// Marker colour per event.
  final ChronoMarkerColor? markerColor;

  /// Marker colour when [markerColor] returns null.
  final Color defaultMarkerColor;

  /// Whether [day] can be picked.
  bool isEnabled(DateTime day) =>
      day.isSameDayOrAfter(firstDay) && day.isSameDayOrBefore(lastDay) && (selectableDayPredicate?.call(day) ?? true);

  /// Full state for [day] when shown in a page about [month].
  ChronoDayState stateFor(DateTime day, {DateTime? month}) {
    final c = controller;
    final items = eventLoader?.call(day) ?? const [];
    final mode = c?.mode ?? ChronoSelectionMode.none;
    final start = c?.rangeStart, end = c?.rangeEnd;
    final isRangeMode = mode == ChronoSelectionMode.range;
    final isRangeStart = isRangeMode && day.isSameDay(start);
    final isRangeEnd = isRangeMode && (day.isSameDay(end) || (end == null && day.isSameDay(start)));
    final inRange =
        isRangeMode && start != null && end != null && day.dateOnly.isAfter(start) && day.dateOnly.isBefore(end);
    return ChronoDayState(
      date: day,
      isToday: day.isToday,
      isSelected: c?.isSelected(day) ?? false,
      isRangeStart: isRangeStart,
      isRangeEnd: isRangeEnd,
      isInRange: inRange,
      isDisabled: !isEnabled(day),
      isOutside: month != null && !day.isSameMonth(month),
      isWeekend: weekendDays.contains(day.weekday),
      isHoliday: holidayPredicate?.call(day) ?? false,
      items: items,
      markerColors: [
        for (final e in items) markerColor?.call(e) ?? defaultMarkerColor,
      ],
    );
  }
}

/// The weekday-name row.
class ChronoWeekdayRow extends StatelessWidget {
  /// Creates the row.
  const ChronoWeekdayRow({
    super.key,
    required this.firstDayOfWeek,
    required this.locale,
    required this.theme,
    this.showWeekNumbers = false,
    this.weekendDays = const {},
    this.builder,
  });

  /// First weekday shown.
  final int firstDayOfWeek;

  /// Locale for names.
  final ChronoLocale locale;

  /// Resolved theme.
  final ChronoThemeData theme;

  /// Whether a week-number column is shown.
  final bool showWeekNumbers;

  /// Weekend days (shown in the weekend colour).
  final Set<int> weekendDays;

  /// Optional custom label builder.
  final Widget Function(BuildContext context, int weekday)? builder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: theme.weekdayRowHeight,
      child: Row(children: [
        if (showWeekNumbers)
          SizedBox(
            width: 32,
            child: Center(child: Text(locale.strings.weekShort, style: theme.weekdayTextStyle)),
          ),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: builder?.call(context, (firstDayOfWeek - 1 + i) % 7 + 1) ??
                  ExcludeSemantics(
                    child: Text(
                      locale.weekdayName((firstDayOfWeek - 1 + i) % 7 + 1, style: theme.weekdayStyle),
                      style: theme.weekdayTextStyle,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
            ),
          ),
      ]),
    );
  }
}

/// A block of week rows. Used by the month calendar, vertical calendar and
/// any custom layout you build.
class ChronoWeeksGrid extends StatelessWidget {
  /// Creates a grid of [weekStarts.length] rows.
  const ChronoWeeksGrid({
    super.key,
    required this.weekStarts,
    required this.rules,
    required this.theme,
    required this.locale,
    this.month,
    this.showOutsideDays = true,
    this.showWeekNumbers = false,
    this.nativeDigits = false,
    this.onDayTap,
    this.onDayLongPress,
    this.dayBuilder,
    this.dayLabelBuilder,
    this.markerStyle = ChronoMarkerStyle.dots,
    this.chipStyle = const ChronoChipStyle(),
    this.itemLabel = chronoItemLabel,
    this.onItemTap,
    this.onDrop,
    this.canDrop,
  });

  /// How events are drawn in each day.
  final ChronoMarkerStyle markerStyle;

  /// Card look for [ChronoMarkerStyle.chips].
  final ChronoChipStyle chipStyle;

  /// Title for each item in chips mode.
  final String Function(Object? item) itemLabel;

  /// Tap on an item in chips mode.
  final ValueChanged<Object?>? onItemTap;

  /// Something was dropped on a day: an item dragged from another day or
  /// anything wrapped in a draggable (see [ChronoDragItem]). Setting this
  /// makes every day a drop target and chips draggable.
  final void Function(DateTime day, Object data)? onDrop;

  /// Whether [data] may be dropped on [day] (enabled days only by default).
  final bool Function(DateTime day, Object data)? canDrop;

  /// First day of each row.
  final List<DateTime> weekStarts;

  /// Day rules.
  final ChronoDayRules rules;

  /// Resolved theme.
  final ChronoThemeData theme;

  /// Locale for digits and semantics.
  final ChronoLocale locale;

  /// Month the page is about (for outside-day styling), if any.
  final DateTime? month;

  /// Whether days from neighbouring months are drawn.
  final bool showOutsideDays;

  /// Whether to show ISO week numbers.
  final bool showWeekNumbers;

  /// Whether to use the locale's native digits.
  final bool nativeDigits;

  /// Tap callback (only for enabled days).
  final ValueChanged<DateTime>? onDayTap;

  /// Long-press callback.
  final ValueChanged<DateTime>? onDayLongPress;

  /// Custom cell builder.
  final ChronoDayBuilder? dayBuilder;

  /// Sub-label builder.
  final ChronoDayLabelBuilder? dayLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final longDate = MaterialLocalizations.of(context);
    return Column(
      children: [
        for (final ws in weekStarts)
          SizedBox(
            height: theme.cellHeight,
            child: Row(children: [
              if (showWeekNumbers)
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      locale.localizeDigits('${ws.addDays(3).isoWeekNumber}', enabled: nativeDigits),
                      style: theme.weekdayTextStyle,
                    ),
                  ),
                ),
              for (var i = 0; i < 7; i++) Expanded(child: _cell(context, ws.addDays(i), longDate)),
            ]),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime day, MaterialLocalizations ml) {
    final state = rules.stateFor(day, month: month);
    if (state.isOutside && !showOutsideDays) return const SizedBox.shrink();
    final custom = dayBuilder?.call(context, state);
    final number = locale.localizeDigits('${day.day}', enabled: nativeDigits);
    Widget cell = custom ??
        (markerStyle == ChronoMarkerStyle.chips
            ? ChronoChipsDayCell(
                state: state,
                theme: theme,
                text: number,
                chipStyle: chipStyle,
                labelFor: itemLabel,
                draggable: onDrop != null,
                onItemTap: onItemTap,
              )
            : ChronoDayCell(
                state: state,
                theme: theme,
                text: number,
                label: dayLabelBuilder?.call(context, day),
                bars: markerStyle == ChronoMarkerStyle.bars,
              ));
    if (onDrop != null) {
      final inner = cell;
      cell = DragTarget<Object>(
        onWillAcceptWithDetails: (d) => canDrop?.call(day, d.data) ?? !state.isDisabled,
        onAcceptWithDetails: (d) => onDrop!(day, d.data),
        builder: (context, candidates, _) => AnimatedContainer(
          duration: theme.animationDuration,
          decoration: BoxDecoration(
            color: candidates.isEmpty ? null : theme.primaryColor!.withValues(alpha: 0.12),
            border: candidates.isEmpty ? null : Border.all(color: theme.primaryColor!, width: 1.5),
            borderRadius: BorderRadius.circular(theme.dayRadius / 2),
          ),
          child: inner,
        ),
      );
    }
    return Semantics(
      button: !state.isDisabled,
      selected: state.isSelected,
      enabled: !state.isDisabled,
      label: ml.formatFullDate(day),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: state.isDisabled || onDayTap == null ? null : () => onDayTap!(day),
        onLongPress: state.isDisabled || onDayLongPress == null ? null : () => onDayLongPress!(day),
        child: cell,
      ),
    );
  }
}

/// Start of each row for the month of [month].
List<DateTime> monthWeekStarts(DateTime month, int firstDayOfWeek, {bool sixWeeks = false}) {
  final first = month.startOfMonth.startOfWeek(firstDayOfWeek);
  final rows = sixWeeks ? 6 : (first.daysUntil(month.endOfMonth) ~/ 7) + 1;
  return [for (var i = 0; i < rows; i++) first.addWeeks(i)];
}
