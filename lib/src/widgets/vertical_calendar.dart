import 'package:flutter/material.dart';

import '../core/date_availability.dart';
import '../core/date_extensions.dart';
import '../core/date_range.dart';
import '../l10n/chrono_locale.dart';
import 'controller.dart';
import 'day_cell.dart';
import 'month_grid.dart';
import 'theme.dart';

/// Months stacked vertically in an endless scroll, like hotel and flight
/// booking apps. Pairs well with range selection and [dayLabelBuilder] for
/// prices.
class ChronoVerticalCalendar extends StatefulWidget {
  /// Creates a vertical calendar.
  const ChronoVerticalCalendar({
    super.key,
    this.controller,
    this.mode = ChronoSelectionMode.range,
    this.firstDay,
    this.lastDay,
    this.availability,
    this.eventLoader,
    this.onDaySelected,
    this.onRangeSelected,
    this.onDaysSelected,
    this.firstDayOfWeek,
    this.locale,
    this.theme,
    this.enabled = true,
    this.dayBuilder,
    this.dayLabelBuilder,
    this.monthHeaderBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  /// Selection controller.
  final ChronoCalendarController? controller;

  /// Selection mode when no controller is given.
  final ChronoSelectionMode mode;

  /// First month (today by default).
  final DateTime? firstDay;

  /// Last day (two years ahead by default).
  final DateTime? lastDay;

  /// Blocked days.
  final DateAvailability? availability;

  /// Events per day.
  final ChronoEventLoader? eventLoader;

  /// Single selection callback.
  final ValueChanged<DateTime>? onDaySelected;

  /// Range selection callback.
  final ValueChanged<DateRange?>? onRangeSelected;

  /// Multiple selection callback.
  final ValueChanged<Set<DateTime>>? onDaysSelected;

  /// First weekday.
  final int? firstDayOfWeek;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// False freezes it.
  final bool enabled;

  /// Custom day cell.
  final ChronoDayBuilder? dayBuilder;

  /// Small label under each day (e.g. "$120").
  final ChronoDayLabelBuilder? dayLabelBuilder;

  /// Custom month title.
  final Widget Function(BuildContext context, DateTime month)? monthHeaderBuilder;

  /// List padding.
  final EdgeInsets padding;

  @override
  State<ChronoVerticalCalendar> createState() => _ChronoVerticalCalendarState();
}

class _ChronoVerticalCalendarState extends State<ChronoVerticalCalendar> {
  late ChronoCalendarController _c;
  bool _owns = false;

  DateTime get _first => (widget.firstDay ?? DateTime.now()).dateOnly;
  DateTime get _last => (widget.lastDay ?? DateTime.now().addYears(2)).dateOnly;

  @override
  void initState() {
    super.initState();
    _owns = widget.controller == null;
    _c = widget.controller ?? ChronoCalendarController(mode: widget.mode);
    _c.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _c.removeListener(_changed);
    if (_owns) _c.dispose();
    super.dispose();
  }

  void _tap(DateTime d) {
    _c.select(d);
    switch (_c.mode) {
      case ChronoSelectionMode.single:
        widget.onDaySelected?.call(d);
      case ChronoSelectionMode.range:
        widget.onRangeSelected?.call(_c.selectedRange);
      case ChronoSelectionMode.multiple:
        widget.onDaysSelected?.call(_c.selectedDays);
      case ChronoSelectionMode.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, widget.theme);
    final l = ChronoTheme.localeOf(context, widget.locale);
    final dow = widget.firstDayOfWeek ?? l.firstDayOfWeek;
    final months = (_last.year - _first.year) * 12 + _last.month - _first.month + 1;
    final rules = ChronoDayRules(
      firstDay: _first,
      lastDay: _last,
      controller: _c,
      selectableDayPredicate: (d) => widget.enabled && (widget.availability?.isAvailable(d) ?? true),
      weekendDays: l.weekendDays,
      eventLoader: widget.eventLoader,
      defaultMarkerColor: t.eventColor!,
    );
    return Column(
      children: [
        Padding(
          padding: widget.padding,
          child: ChronoWeekdayRow(firstDayOfWeek: dow, locale: l, theme: t),
        ),
        Divider(height: 1, color: t.borderColor),
        Expanded(
          child: ListView.builder(
            padding: widget.padding,
            itemCount: months,
            itemBuilder: (context, i) {
              final month = DateTime(_first.year, _first.month + i);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.monthHeaderBuilder?.call(context, month) ??
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(8, 20, 8, 8),
                        child: Text('${l.monthName(month.month)} ${l.localizeDigits('${month.year}')}',
                            style: t.headerTextStyle),
                      ),
                  ChronoWeeksGrid(
                    weekStarts: monthWeekStarts(month, dow),
                    rules: rules,
                    theme: t,
                    locale: l,
                    month: month,
                    showOutsideDays: false,
                    onDayTap: widget.enabled ? _tap : null,
                    dayBuilder: widget.dayBuilder,
                    dayLabelBuilder: widget.dayLabelBuilder,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
