import 'package:flutter/material.dart';

import '../core/calendar_event.dart';
import '../core/date_extensions.dart';
import '../core/date_range.dart';
import '../l10n/chrono_locale.dart';
import 'theme.dart';

/// A scrolling list of upcoming events grouped by day, the "schedule" or
/// "agenda" layout.
class ChronoAgendaView extends StatelessWidget {
  /// Creates an agenda for [range].
  const ChronoAgendaView({
    super.key,
    required this.events,
    required this.range,
    this.onEventTap,
    this.showEmptyDays = false,
    this.eventBuilder,
    this.dayHeaderBuilder,
    this.emptyBuilder,
    this.locale,
    this.theme,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Events (repeating events are expanded).
  final List<CalendarEvent<Object?>> events;

  /// Days to list.
  final DateRange range;

  /// Tap on an event.
  final ValueChanged<EventOccurrence<Object?>>? onEventTap;

  /// Also list days with no events.
  final bool showEmptyDays;

  /// Custom event row.
  final Widget Function(BuildContext context, EventOccurrence<Object?> occurrence)? eventBuilder;

  /// Custom day header.
  final Widget Function(BuildContext context, DateTime day)? dayHeaderBuilder;

  /// Shown when there is nothing at all.
  final WidgetBuilder? emptyBuilder;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// List padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, theme);
    final l = ChronoTheme.localeOf(context, locale);
    final grouped = events.groupByDay(range);
    final days = showEmptyDays ? range.days.toList() : (grouped.keys.toList()..sort());
    if (days.isEmpty) {
      return emptyBuilder?.call(context) ??
          Center(child: Text(l.strings.noEvents, style: t.dayTextStyle!.copyWith(color: t.mutedTextColor)));
    }
    final ml = MaterialLocalizations.of(context);
    return ListView.builder(
      padding: padding,
      itemCount: days.length,
      itemBuilder: (context, i) {
        final d = days[i];
        final items = grouped[d] ?? const [];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: dayHeaderBuilder?.call(context, d) ??
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(children: [
                      Text(l.weekdayName(d.weekday, style: WeekdayStyle.short),
                          style: t.weekdayTextStyle!.copyWith(color: d.isToday ? t.todayColor : null)),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration:
                            ShapeDecoration(color: d.isToday ? t.primaryColor : null, shape: t.dayShapeBorder()),
                        child: Text(l.localizeDigits('${d.day}'),
                            style: t.headerTextStyle!.copyWith(color: d.isToday ? t.onPrimaryColor : t.textColor)),
                      ),
                    ]),
                  ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(l.strings.noEvents, style: t.dayTextStyle!.copyWith(color: t.mutedTextColor)),
                      ),
                    for (final o in items)
                      eventBuilder?.call(context, o) ??
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: (o.event.color != null ? Color(o.event.color!) : t.eventColor!)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(t.dayRadius),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(t.dayRadius),
                                onTap: onEventTap == null ? null : () => onEventTap!(o),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: BorderDirectional(
                                      start: BorderSide(
                                          width: 4,
                                          color: o.event.color != null ? Color(o.event.color!) : t.eventColor!),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.event.title,
                                          style: t.dayTextStyle!.copyWith(
                                              fontWeight: FontWeight.w600,
                                              decoration: o.event.status == EventStatus.cancelled
                                                  ? TextDecoration.lineThrough
                                                  : null)),
                                      const SizedBox(height: 2),
                                      Text(
                                        o.event.isAllDay
                                            ? l.strings.allDay
                                            : '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(o.start))} – ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(o.end))}',
                                        style: t.weekdayTextStyle,
                                      ),
                                      if (o.event.location != null) Text(o.event.location!, style: t.weekdayTextStyle),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
