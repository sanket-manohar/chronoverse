import 'package:flutter/material.dart';

import 'theme.dart';

/// Everything a day builder needs to know about one day cell.
@immutable
class ChronoDayState {
  /// Creates a day state.
  const ChronoDayState({
    required this.date,
    this.isToday = false,
    this.isSelected = false,
    this.isRangeStart = false,
    this.isRangeEnd = false,
    this.isInRange = false,
    this.isDisabled = false,
    this.isOutside = false,
    this.isWeekend = false,
    this.isHoliday = false,
    this.markerColors = const [],
    this.items = const [],
  });

  /// The day (midnight).
  final DateTime date;

  /// Is today.
  final bool isToday;

  /// Is selected (single/multiple, or a range end).
  final bool isSelected;

  /// First day of the selected range.
  final bool isRangeStart;

  /// Last day of the selected range.
  final bool isRangeEnd;

  /// Strictly inside the selected range.
  final bool isInRange;

  /// Outside min/max or rejected by the selectable predicate.
  final bool isDisabled;

  /// Belongs to the previous or next month.
  final bool isOutside;

  /// A weekend day.
  final bool isWeekend;

  /// Marked as a holiday.
  final bool isHoliday;

  /// One colour per event dot to draw.
  final List<Color> markerColors;

  /// The raw items (events, notes...) on this day, same order as
  /// [markerColors].
  final List<Object?> items;
}

/// Returns a custom cell for a day, or null to use the default.
typedef ChronoDayBuilder = Widget? Function(BuildContext context, ChronoDayState state);

/// Returns a small text or widget under the day number (prices, moon
/// phases, availability), or null for none.
typedef ChronoDayLabelBuilder = Widget? Function(BuildContext context, DateTime day);

/// The default day cell: range band, selection shape, today ring, number,
/// optional sub-label and event dots.
class ChronoDayCell extends StatelessWidget {
  /// Creates a day cell.
  const ChronoDayCell({
    super.key,
    required this.state,
    required this.theme,
    required this.text,
    this.label,
    this.showRangeBand = true,
    this.bars = false,
  });

  /// Draw short bars instead of dots.
  final bool bars;

  /// Day state.
  final ChronoDayState state;

  /// Resolved theme.
  final ChronoThemeData theme;

  /// The day number text (already localised).
  final String text;

  /// Optional widget under the number.
  final Widget? label;

  /// Whether to paint the range band behind range days.
  final bool showRangeBand;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final selected = s.isSelected || s.isRangeStart || s.isRangeEnd;
    Color textColor = theme.textColor!;
    if (s.isWeekend) textColor = theme.weekendTextColor!;
    if (s.isHoliday) textColor = theme.holidayTextColor!;
    if (s.isOutside) textColor = theme.mutedTextColor!;
    if (s.isDisabled) textColor = theme.disabledColor!;
    if (selected) textColor = theme.onPrimaryColor!;
    if (s.isToday && !selected && !s.isDisabled) textColor = theme.todayColor!;

    final style = theme.dayTextStyle!.copyWith(
      color: textColor,
      fontWeight: selected || s.isToday ? FontWeight.w600 : null,
      decoration: s.isDisabled ? TextDecoration.lineThrough : null,
      decorationColor: theme.disabledColor,
    );

    // Range band: full width for inner days, half width at the ends.
    Widget? band;
    final hasRangeEnds = s.isRangeStart && s.isRangeEnd;
    if (showRangeBand && (s.isInRange || ((s.isRangeStart || s.isRangeEnd) && !hasRangeEnds))) {
      // Row follows the text direction, so "start half" is the left half in
      // LTR and the right half in RTL.
      Widget half(bool filled) => Expanded(child: ColoredBox(color: filled ? theme.rangeColor! : Colors.transparent));
      band = Positioned.fill(
        top: theme.cellPadding,
        bottom: theme.cellPadding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          half(s.isInRange || s.isRangeEnd),
          half(s.isInRange || s.isRangeStart),
        ]),
      );
    }

    final highlight = AnimatedContainer(
      duration: theme.animationDuration,
      curve: theme.animationCurve,
      margin: EdgeInsets.all(theme.cellPadding),
      decoration: ShapeDecoration(
        color: selected ? theme.primaryColor : Colors.transparent,
        shape: theme.dayShapeBorder(s.isToday && !selected
            ? BorderSide(color: theme.todayColor!, width: theme.todayBorderWidth)
            : BorderSide.none),
      ),
      // Scale down instead of overflowing with large accessibility text.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: style),
            if (label != null)
              DefaultTextStyle(
                style: theme.weekdayTextStyle!.copyWith(fontSize: 9, color: selected ? theme.onPrimaryColor : null),
                child: label!,
              ),
          ],
        ),
      ),
    );

    final markers = s.markerColors.take(theme.maxMarkers).toList();
    return Stack(
      children: [
        if (band != null) band,
        Positioned.fill(
          child: theme.dayShape == ChronoDayShape.circle
              ? Center(child: AspectRatio(aspectRatio: 1, child: highlight))
              : highlight,
        ),
        if (markers.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: theme.cellPadding + 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in markers)
                  Container(
                    width: bars ? theme.markerSize * 2.6 : theme.markerSize,
                    height: bars ? theme.markerSize * 0.7 : theme.markerSize,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: selected ? theme.onPrimaryColor : c,
                      shape: bars ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: bars ? BorderRadius.circular(theme.markerSize) : null,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
