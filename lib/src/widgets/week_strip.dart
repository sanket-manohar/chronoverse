import 'package:flutter/material.dart';

import '../core/date_availability.dart';
import '../core/date_extensions.dart';
import '../l10n/chrono_locale.dart';
import 'month_grid.dart';
import 'theme.dart';

/// A horizontal, scrollable strip of day chips (timeline picker), common in
/// booking, fitness and to-do apps.
class ChronoWeekStrip extends StatefulWidget {
  /// Creates a strip.
  const ChronoWeekStrip({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
    this.firstDate,
    this.lastDate,
    this.availability,
    this.eventLoader,
    this.locale,
    this.theme,
    this.itemWidth = 56,
    this.height = 76,
    this.showMonthHeader = true,
    this.enabled = true,
    this.itemBuilder,
  });

  /// Called when a day is tapped.
  final ValueChanged<DateTime> onDateSelected;

  /// Highlighted day (today by default).
  final DateTime? selectedDate;

  /// First day in the strip (today − 30 days by default).
  final DateTime? firstDate;

  /// Last day in the strip (today + 365 days by default).
  final DateTime? lastDate;

  /// Blocked days.
  final DateAvailability? availability;

  /// Events per day (dots).
  final ChronoEventLoader? eventLoader;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// Width of one chip.
  final double itemWidth;

  /// Height of the chip row.
  final double height;

  /// Shows "October 2026" above the strip, following the scroll.
  final bool showMonthHeader;

  /// False freezes the strip.
  final bool enabled;

  /// Fully custom chip.
  final Widget Function(BuildContext context, DateTime day, bool selected, bool enabled)? itemBuilder;

  @override
  State<ChronoWeekStrip> createState() => _ChronoWeekStripState();
}

class _ChronoWeekStripState extends State<ChronoWeekStrip> {
  late ScrollController _scroll;
  late DateTime _visibleMonth;

  DateTime get _first => (widget.firstDate ?? DateTime.now().addDays(-30)).dateOnly;
  DateTime get _last => (widget.lastDate ?? DateTime.now().addDays(365)).dateOnly;
  DateTime get _selected => (widget.selectedDate ?? DateTime.now()).dateOnly;

  @override
  void initState() {
    super.initState();
    final index = _first.daysUntil(_selected).clamp(0, _first.daysUntil(_last));
    _visibleMonth = _selected;
    _scroll = ScrollController(initialScrollOffset: (index - 2).clamp(0, 1 << 30) * widget.itemWidth);
    _scroll.addListener(() {
      final i = (_scroll.offset / widget.itemWidth + 1).floor();
      final m = _first.addDays(i);
      if (!m.isSameMonth(_visibleMonth)) setState(() => _visibleMonth = m);
    });
  }

  @override
  void didUpdateWidget(ChronoWeekStrip old) {
    super.didUpdateWidget(old);
    if (!(old.selectedDate?.isSameDay(widget.selectedDate) ?? widget.selectedDate == null) && _scroll.hasClients) {
      final target = (_first.daysUntil(_selected) - 2).clamp(0, 1 << 30) * widget.itemWidth;
      _scroll.animateTo(target.toDouble().clamp(0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, widget.theme);
    final l = ChronoTheme.localeOf(context, widget.locale);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showMonthHeader)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, bottom: 6),
            child: Text('${l.monthName(_visibleMonth.month)} ${l.localizeDigits('${_visibleMonth.year}')}',
                style: t.headerTextStyle),
          ),
        SizedBox(
          height: widget.height,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            itemExtent: widget.itemWidth,
            itemCount: _first.daysUntil(_last) + 1,
            physics: widget.enabled ? null : const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              final day = _first.addDays(i);
              final selected = day.isSameDay(_selected);
              final enabled = widget.enabled && (widget.availability?.isAvailable(day) ?? true);
              final custom = widget.itemBuilder?.call(context, day, selected, enabled);
              if (custom != null) {
                return GestureDetector(onTap: enabled ? () => widget.onDateSelected(day) : null, child: custom);
              }
              final fg = !enabled
                  ? t.disabledColor
                  : selected
                      ? t.onPrimaryColor
                      : day.isToday
                          ? t.todayColor
                          : t.textColor;
              final dots = widget.eventLoader?.call(day).length ?? 0;
              return Semantics(
                button: enabled,
                selected: selected,
                label: MaterialLocalizations.of(context).formatFullDate(day),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(t.dayRadius + 4),
                    onTap: enabled ? () => widget.onDateSelected(day) : null,
                    child: AnimatedContainer(
                      duration: t.animationDuration,
                      curve: t.animationCurve,
                      decoration: BoxDecoration(
                        color: selected ? t.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(t.dayRadius + 4),
                        border: day.isToday && !selected
                            ? Border.all(color: t.todayColor!, width: t.todayBorderWidth)
                            : Border.all(color: t.borderColor!.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l.weekdayName(day.weekday, style: WeekdayStyle.short),
                              style: t.weekdayTextStyle!.copyWith(color: fg)),
                          const SizedBox(height: 4),
                          Text(l.localizeDigits('${day.day}'),
                              style: t.dayTextStyle!.copyWith(color: fg, fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var k = 0; k < dots.clamp(0, t.maxMarkers); k++)
                                Container(
                                  width: t.markerSize,
                                  height: t.markerSize,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                      color: selected ? t.onPrimaryColor : t.eventColor, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
