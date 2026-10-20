import 'package:flutter/material.dart';

import '../core/date_extensions.dart';
import '../l10n/chrono_locale.dart';
import 'theme.dart';

/// A contribution-style heatmap: one square per day, coloured by a
/// value. Great for habit trackers, streaks, workouts and attendance.
class ChronoHeatmap extends StatelessWidget {
  /// Creates a heatmap from [values] (any date in a day counts for that day).
  const ChronoHeatmap({
    super.key,
    required this.values,
    this.startDate,
    this.endDate,
    this.colors,
    this.maxValue,
    this.cellSize = 14,
    this.cellSpacing = 3,
    this.firstDayOfWeek,
    this.onDayTap,
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
    this.showLegend = true,
    this.locale,
    this.theme,
  });

  /// Value per day.
  final Map<DateTime, num> values;

  /// First day (a year before [endDate] by default).
  final DateTime? startDate;

  /// Last day (today by default).
  final DateTime? endDate;

  /// Colour steps from empty to most intense (5 shades of the primary
  /// colour by default).
  final List<Color>? colors;

  /// Value that gets the strongest colour (the largest value by default).
  final num? maxValue;

  /// Square size.
  final double cellSize;

  /// Gap between squares.
  final double cellSpacing;

  /// First weekday row.
  final int? firstDayOfWeek;

  /// Tap on a day, with its value.
  final void Function(DateTime day, num value)? onDayTap;

  /// Month names above the columns.
  final bool showMonthLabels;

  /// Mon/Wed/Fri labels on the side.
  final bool showWeekdayLabels;

  /// "Less ▢▢▢▢ More" legend.
  final bool showLegend;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, theme);
    final l = ChronoTheme.localeOf(context, locale);
    final dow = firstDayOfWeek ?? l.firstDayOfWeek;
    final end = (endDate ?? DateTime.now()).dateOnly;
    final start = (startDate ?? end.addYears(-1).addDays(1)).dateOnly;
    final byDay = <DateTime, num>{};
    values.forEach((k, v) => byDay[k.dateOnly] = (byDay[k.dateOnly] ?? 0) + v);
    final max = maxValue ?? (byDay.values.isEmpty ? 1 : byDay.values.reduce((a, b) => a > b ? a : b));
    final palette = colors ??
        [
          t.borderColor!.withValues(alpha: 0.35),
          for (final a in [0.3, 0.5, 0.75, 1.0]) t.primaryColor!.withValues(alpha: a),
        ];

    Color colorFor(num v) {
      if (v <= 0 || max <= 0) return palette.first;
      final i = 1 + ((v / max) * (palette.length - 1) - 0.0001).floor().clamp(0, palette.length - 2);
      return palette[i];
    }

    final firstCol = start.startOfWeek(dow);
    final weeks = firstCol.daysUntil(end) ~/ 7 + 1;
    final step = cellSize + cellSpacing;
    final labelStyle = t.weekdayTextStyle!.copyWith(fontSize: 10);

    final grid = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var w = 0; w < weeks; w++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMonthLabels)
                SizedBox(
                  height: 16,
                  width: step,
                  child: OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    maxWidth: 60,
                    child: () {
                      final colStart = firstCol.addWeeks(w);
                      final firstOfMonth = [for (var i = 0; i < 7; i++) colStart.addDays(i)]
                          .where((d) => d.day == 1 && !d.isBefore(start) && !d.isAfter(end));
                      return firstOfMonth.isEmpty && w != 0
                          ? const SizedBox.shrink()
                          : Text(l.monthName((firstOfMonth.isEmpty ? start : firstOfMonth.first).month, short: true),
                              style: labelStyle);
                    }(),
                  ),
                ),
              for (var d = 0; d < 7; d++)
                () {
                  final day = firstCol.addDays(w * 7 + d);
                  if (day.isBefore(start) || day.isAfter(end)) return SizedBox(width: step, height: step);
                  final v = byDay[day] ?? 0;
                  return Tooltip(
                    message: '${MaterialLocalizations.of(context).formatMediumDate(day)}: $v',
                    child: GestureDetector(
                      onTap: onDayTap == null ? null : () => onDayTap!(day, v),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(right: cellSpacing, bottom: cellSpacing),
                        decoration: BoxDecoration(
                          color: colorFor(v),
                          borderRadius: BorderRadius.circular(cellSize / 4),
                          border: day.isToday ? Border.all(color: t.todayColor!, width: 1) : null,
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showWeekdayLabels)
              Padding(
                padding: EdgeInsets.only(top: showMonthLabels ? 16 : 0, right: 4),
                child: Column(children: [
                  for (var d = 0; d < 7; d++)
                    SizedBox(
                      height: step,
                      child: d.isOdd
                          ? Text(l.weekdayName((dow - 1 + d) % 7 + 1, style: WeekdayStyle.short), style: labelStyle)
                          : null,
                    ),
                ]),
              ),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: grid,
              ),
            ),
          ],
        ),
        if (showLegend)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('−', style: labelStyle),
              const SizedBox(width: 4),
              for (final c in palette)
                Container(
                  width: cellSize * 0.8,
                  height: cellSize * 0.8,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                ),
              const SizedBox(width: 4),
              Text('+', style: labelStyle),
            ]),
          ),
      ],
    );
  }
}
