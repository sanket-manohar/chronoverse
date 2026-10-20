import 'package:flutter/material.dart';

import '../core/date_extensions.dart';
import '../l10n/chrono_locale.dart';
import 'month_grid.dart';
import 'theme.dart';

/// Twelve mini months on one screen: overview of a whole year with event
/// dots, tap a day or a month title to drill in.
class ChronoYearView extends StatelessWidget {
  /// Creates a year view.
  const ChronoYearView({
    super.key,
    required this.year,
    this.onMonthTap,
    this.onDayTap,
    this.eventLoader,
    this.holidayPredicate,
    this.selectedDate,
    this.firstDayOfWeek,
    this.locale,
    this.theme,
    this.crossAxisCount,
    this.padding = const EdgeInsets.all(8),
  });

  /// Year shown.
  final int year;

  /// Tap on a month title.
  final ValueChanged<DateTime>? onMonthTap;

  /// Tap on a day.
  final ValueChanged<DateTime>? onDayTap;

  /// Days with events get a dot.
  final ChronoEventLoader? eventLoader;

  /// Holidays are coloured.
  final ChronoDayPredicate? holidayPredicate;

  /// Highlighted day.
  final DateTime? selectedDate;

  /// First weekday.
  final int? firstDayOfWeek;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// Months per row (auto: 2 on phones, 3–4 on wider screens).
  final int? crossAxisCount;

  /// Outer padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, theme);
    final l = ChronoTheme.localeOf(context, locale);
    final dow = firstDayOfWeek ?? l.firstDayOfWeek;
    return LayoutBuilder(builder: (context, box) {
      final cols = crossAxisCount ??
          (box.maxWidth > 900
              ? 4
              : box.maxWidth > 560
                  ? 3
                  : 2);
      return GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: 12,
        itemBuilder: (context, i) => _MiniMonth(
          month: DateTime(year, i + 1),
          firstDayOfWeek: dow,
          theme: t,
          locale: l,
          onMonthTap: onMonthTap,
          onDayTap: onDayTap,
          eventLoader: eventLoader,
          holidayPredicate: holidayPredicate,
          selectedDate: selectedDate,
        ),
      );
    });
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.month,
    required this.firstDayOfWeek,
    required this.theme,
    required this.locale,
    this.onMonthTap,
    this.onDayTap,
    this.eventLoader,
    this.holidayPredicate,
    this.selectedDate,
  });

  final DateTime month;
  final int firstDayOfWeek;
  final ChronoThemeData theme;
  final ChronoLocale locale;
  final ValueChanged<DateTime>? onMonthTap;
  final ValueChanged<DateTime>? onDayTap;
  final ChronoEventLoader? eventLoader;
  final ChronoDayPredicate? holidayPredicate;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final small = t.dayTextStyle!.copyWith(fontSize: 10);
    final weeks = monthWeekStarts(month, firstDayOfWeek, sixWeeks: true);
    final isCurrent = month.isSameMonth(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onMonthTap == null ? null : () => onMonthTap!(month),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(locale.monthName(month.month),
                style: t.headerTextStyle!.copyWith(fontSize: 14, color: isCurrent ? t.todayColor : null)),
          ),
        ),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(locale.weekdayName((firstDayOfWeek - 1 + i) % 7 + 1, style: WeekdayStyle.narrow),
                    style: t.weekdayTextStyle!.copyWith(fontSize: 9)),
              ),
            ),
        ]),
        Expanded(
          child: Column(children: [
            for (final w in weeks)
              Expanded(
                child: Row(children: [
                  for (var i = 0; i < 7; i++) Expanded(child: _day(context, w.addDays(i), small)),
                ]),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _day(BuildContext context, DateTime d, TextStyle style) {
    if (!d.isSameMonth(month)) return const SizedBox.shrink();
    final t = theme;
    final selected = d.isSameDay(selectedDate);
    final hasEvents = (eventLoader?.call(d).isNotEmpty) ?? false;
    final holiday = holidayPredicate?.call(d) ?? false;
    return GestureDetector(
      onTap: onDayTap == null ? null : () => onDayTap!(d),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: ShapeDecoration(
          color: selected
              ? t.primaryColor
              : hasEvents
                  ? t.eventColor!.withValues(alpha: 0.18)
                  : null,
          shape:
              t.dayShapeBorder(d.isToday && !selected ? BorderSide(color: t.todayColor!, width: 1) : BorderSide.none),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Text(
            locale.localizeDigits('${d.day}'),
            style: style.copyWith(
              color: selected
                  ? t.onPrimaryColor
                  : holiday
                      ? t.holidayTextColor
                      : t.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
