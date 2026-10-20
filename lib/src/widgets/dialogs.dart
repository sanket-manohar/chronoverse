import 'package:flutter/material.dart';

import '../core/chrono_format.dart';
import '../core/date_availability.dart';
import '../core/date_extensions.dart';
import '../core/date_range.dart';
import '../core/natural_date.dart';
import '../l10n/chrono_locale.dart';
import 'calendar.dart';
import 'controller.dart';
import 'theme.dart';
import 'wheel_picker.dart';

/// How a picker is presented.
enum ChronoPresentation {
  /// Centered dialog.
  dialog,

  /// Sheet from the bottom of the screen.
  bottomSheet,
}

/// A labelled quick choice in the range picker ("Last 7 days").
class ChronoRangePreset {
  /// Creates a preset.
  const ChronoRangePreset(this.label, this.range);

  /// Chip label.
  final String label;

  /// Builds the range relative to today.
  final DateRange Function(DateTime today) range;

  /// Common presets (English labels; pass your own for other languages).
  static List<ChronoRangePreset> get common => [
        ChronoRangePreset('Today', (t) => DateRange.day(t)),
        ChronoRangePreset('Last 7 days', (t) => DateRange(t.addDays(-6), t)),
        ChronoRangePreset('Last 30 days', (t) => DateRange(t.addDays(-29), t)),
        ChronoRangePreset('This week', (t) => DateRange.week(t)),
        ChronoRangePreset('This month', (t) => DateRange.month(t)),
        ChronoRangePreset('Last month', (t) => DateRange.month(t.startOfMonth.addMonths(-1))),
        ChronoRangePreset('This year', (t) => DateRange.year(t)),
      ];
}

Future<T?> _present<T>(BuildContext context, ChronoPresentation how, WidgetBuilder builder) {
  if (how == ChronoPresentation.bottomSheet) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
        child: builder(c),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (c) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: builder(c)),
    ),
  );
}

/// Opens a single-date picker. Returns the date, or null when cancelled.
///
/// With [allowTyping], a keyboard button switches to a text box that
/// understands formats like `25/12/2026` and phrases like "next friday".
Future<DateTime?> showChronoDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  DateAvailability? availability,
  ChronoPresentation presentation = ChronoPresentation.dialog,
  bool allowTyping = true,
  String? inputPattern,
  String? title,
  ChronoLocale? locale,
  ChronoThemeData? theme,
}) =>
    _present<DateTime>(
      context,
      presentation,
      (c) => _PickerBody(
        mode: ChronoSelectionMode.single,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        availability: availability,
        allowTyping: allowTyping,
        inputPattern: inputPattern,
        title: title,
        locale: locale,
        theme: theme,
      ),
    );

/// Opens a range picker with optional quick [presets]. Returns the range,
/// or null when cancelled.
Future<DateRange?> showChronoRangePicker({
  required BuildContext context,
  DateRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
  DateAvailability? availability,
  int? maxDays,
  List<ChronoRangePreset>? presets,
  ChronoPresentation presentation = ChronoPresentation.dialog,
  String? title,
  ChronoLocale? locale,
  ChronoThemeData? theme,
}) =>
    _present<DateRange>(
      context,
      presentation,
      (c) => _PickerBody(
        mode: ChronoSelectionMode.range,
        initialRange: initialRange,
        firstDate: firstDate,
        lastDate: lastDate,
        availability: availability,
        maxDays: maxDays,
        presets: presets,
        allowTyping: false,
        title: title,
        locale: locale,
        theme: theme,
      ),
    );

/// Opens a multiple-date picker. Returns the chosen days, or null.
Future<Set<DateTime>?> showChronoMultiDatePicker({
  required BuildContext context,
  Set<DateTime>? initialDates,
  DateTime? firstDate,
  DateTime? lastDate,
  DateAvailability? availability,
  ChronoPresentation presentation = ChronoPresentation.dialog,
  String? title,
  ChronoLocale? locale,
  ChronoThemeData? theme,
}) =>
    _present<Set<DateTime>>(
      context,
      presentation,
      (c) => _PickerBody(
        mode: ChronoSelectionMode.multiple,
        initialDates: initialDates,
        firstDate: firstDate,
        lastDate: lastDate,
        availability: availability,
        allowTyping: false,
        title: title,
        locale: locale,
        theme: theme,
      ),
    );

/// Opens day/month/year wheels (good for birthdays). Returns the date or
/// null.
Future<DateTime?> showChronoWheelPicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  ChronoPresentation presentation = ChronoPresentation.bottomSheet,
  String? title,
  ChronoLocale? locale,
  ChronoThemeData? theme,
}) {
  var value = (initialDate ?? DateTime.now()).dateOnly;
  return _present<DateTime>(context, presentation, (c) {
    final l = ChronoTheme.localeOf(c, locale);
    final t = ChronoTheme.of(c, theme);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title ?? l.strings.selectDate, style: t.headerTextStyle),
          const SizedBox(height: 12),
          ChronoDateWheelPicker(
            initialDate: value,
            firstDate: firstDate,
            lastDate: lastDate,
            locale: locale,
            theme: theme,
            onChanged: (d) => value = d,
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(l.strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, value), child: Text(l.strings.ok)),
          ]),
        ],
      ),
    );
  });
}

class _PickerBody extends StatefulWidget {
  const _PickerBody({
    required this.mode,
    this.initialDate,
    this.initialRange,
    this.initialDates,
    this.firstDate,
    this.lastDate,
    this.availability,
    this.maxDays,
    this.presets,
    this.allowTyping = true,
    this.inputPattern,
    this.title,
    this.locale,
    this.theme,
  });

  final ChronoSelectionMode mode;
  final DateTime? initialDate;
  final DateRange? initialRange;
  final Set<DateTime>? initialDates;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateAvailability? availability;
  final int? maxDays;
  final List<ChronoRangePreset>? presets;
  final bool allowTyping;
  final String? inputPattern;
  final String? title;
  final ChronoLocale? locale;
  final ChronoThemeData? theme;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late final ChronoCalendarController _c = ChronoCalendarController(
    mode: widget.mode,
    focusedDay: widget.initialDate ?? widget.initialRange?.start ?? widget.initialDates?.firstOrNull,
    selectedDay: widget.initialDate,
    selectedRange: widget.initialRange,
    selectedDays: widget.initialDates,
  );
  bool _typing = false;
  final _text = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _text.dispose();
    super.dispose();
  }

  Object? get _result => switch (widget.mode) {
        ChronoSelectionMode.single => _c.selectedDay,
        ChronoSelectionMode.range => _c.selectedRange,
        ChronoSelectionMode.multiple => _c.selectedDays.isEmpty ? null : _c.selectedDays,
        ChronoSelectionMode.none => null,
      };

  String _summary(ChronoLocale l) {
    final f = ChronoFormat('EEE, d MMM yyyy', locale: l);
    final short = ChronoFormat('d MMM', locale: l);
    return switch (widget.mode) {
      ChronoSelectionMode.single => _c.selectedDay == null ? '—' : f.format(_c.selectedDay!),
      ChronoSelectionMode.range => _c.rangeStart == null
          ? '—'
          : '${short.format(_c.rangeStart!)} – ${_c.rangeEnd == null ? '…' : short.format(_c.rangeEnd!)}'
              '${_c.selectedRange == null ? '' : '  (${l.unit(ChronoUnit.day, _c.selectedRange!.lengthInDays)})'}',
      ChronoSelectionMode.multiple => l.unit(ChronoUnit.day, _c.selectedDays.length),
      ChronoSelectionMode.none => '',
    };
  }

  void _submitText(ChronoLocale l) {
    final pattern = widget.inputPattern ?? l.defaultDatePattern;
    final d = NaturalDateParser(locale: l, patterns: [pattern], firstDayOfWeek: l.firstDayOfWeek).parse(_text.text);
    final first = widget.firstDate, last = widget.lastDate;
    if (d == null) {
      setState(() => _error = l.strings.invalidDate);
    } else if ((first != null && d.isBefore(first.dateOnly)) ||
        (last != null && d.isAfter(last)) ||
        !(widget.availability?.isAvailable(d) ?? true)) {
      setState(() => _error = l.strings.outOfRange);
    } else {
      setState(() {
        _error = null;
        _typing = false;
      });
      _c.select(d);
      _c.jumpTo(d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ChronoTheme.localeOf(context, widget.locale);
    final t = ChronoTheme.of(context, widget.theme);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                      widget.title ??
                          (widget.mode == ChronoSelectionMode.range ? l.strings.selectRange : l.strings.selectDate),
                      style: t.weekdayTextStyle),
                  const SizedBox(height: 4),
                  Text(_summary(l), style: t.headerTextStyle!.copyWith(fontSize: 20)),
                ]),
              ),
              if (widget.allowTyping)
                IconButton(
                  tooltip: _typing ? l.strings.selectDate : l.strings.enterDate,
                  icon: Icon(_typing ? Icons.calendar_month_outlined : Icons.keyboard_outlined),
                  onPressed: () => setState(() => _typing = !_typing),
                ),
            ]),
          ),
          if (widget.presets != null && widget.presets!.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final p in widget.presets!)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(p.label),
                        onPressed: () => _c.selectRange(p.range(DateTime.now().dateOnly)),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          if (_typing)
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _text,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l.strings.enterDate,
                  hintText: (widget.inputPattern ?? l.defaultDatePattern).toLowerCase(),
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submitText(l),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ChronoCalendar(
                controller: _c,
                firstDay: widget.firstDate,
                lastDay: widget.lastDate,
                availability: widget.availability,
                maxRangeDays: widget.maxDays,
                sixWeekMonths: true,
                showTodayButton: false,
                locale: widget.locale,
                theme: widget.theme,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 12),
            child: Row(children: [
              TextButton(onPressed: _c.clearSelection, child: Text(l.strings.clear)),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l.strings.cancel)),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _typing
                    ? () => _submitText(l)
                    : _result == null
                        ? null
                        : () => Navigator.pop(context, _result),
                child: Text(l.strings.ok),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
