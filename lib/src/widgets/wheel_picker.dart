import 'package:flutter/material.dart';

import '../core/date_extensions.dart';
import '../l10n/chrono_locale.dart';
import 'theme.dart';

/// Order of the wheels in [ChronoDateWheelPicker].
enum ChronoWheelOrder {
  /// Day, month, year.
  dmy,

  /// Month, day, year.
  mdy,

  /// Year, month, day.
  ymd,
}

/// Scrolling wheels for day, month and year: ideal for birthdays
/// and any date far from today.
///
/// The day wheel always matches the month's real length, so Feb 29 only
/// appears in leap years, and min/max dates are enforced while scrolling.
class ChronoDateWheelPicker extends StatefulWidget {
  /// Creates a wheel picker.
  const ChronoDateWheelPicker({
    super.key,
    required this.onChanged,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.order,
    this.locale,
    this.theme,
    this.itemExtent = 40,
    this.visibleItems = 5,
    this.showMonthNames = true,
    this.enabled = true,
    this.looping = false,
  });

  /// Called whenever the date changes.
  final ValueChanged<DateTime> onChanged;

  /// Starting date (today by default).
  final DateTime? initialDate;

  /// Earliest date (1 Jan 1900 by default).
  final DateTime? firstDate;

  /// Latest date (31 Dec 2100 by default).
  final DateTime? lastDate;

  /// Wheel order (defaults from the locale's date pattern).
  final ChronoWheelOrder? order;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  /// Row height.
  final double itemExtent;

  /// Visible rows.
  final int visibleItems;

  /// Month names instead of numbers.
  final bool showMonthNames;

  /// False freezes the wheels.
  final bool enabled;

  /// Day and month wheels wrap around.
  final bool looping;

  @override
  State<ChronoDateWheelPicker> createState() => _ChronoDateWheelPickerState();
}

class _ChronoDateWheelPickerState extends State<ChronoDateWheelPicker> {
  late DateTime _date;
  late FixedExtentScrollController _d, _m, _y;

  DateTime get _min => (widget.firstDate ?? DateTime(1900)).dateOnly;
  DateTime get _max => (widget.lastDate ?? DateTime(2100, 12, 31)).dateOnly;

  @override
  void initState() {
    super.initState();
    _date = (widget.initialDate ?? DateTime.now()).dateOnly.clampTo(_min, _max);
    _d = FixedExtentScrollController(initialItem: _date.day - 1);
    _m = FixedExtentScrollController(initialItem: _date.month - 1);
    _y = FixedExtentScrollController(initialItem: _date.year - _min.year);
  }

  @override
  void dispose() {
    _d.dispose();
    _m.dispose();
    _y.dispose();
    super.dispose();
  }

  void _update({int? day, int? month, int? year}) {
    final y = year ?? _date.year;
    final m = month ?? _date.month;
    final d = (day ?? _date.day).clamp(1, daysInMonth(y, m));
    final next = DateTime(y, m, d).clampTo(_min, _max);
    if (next == _date) return;
    setState(() => _date = next);
    // Snap wheels that had to be corrected (Feb 30 → Feb 28, below min...).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void snap(FixedExtentScrollController c, int item, int count) {
        if (!c.hasClients) return;
        final current = widget.looping ? c.selectedItem % count : c.selectedItem;
        if (current != item) {
          c.animateToItem(c.selectedItem - current + item,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      }

      snap(_d, _date.day - 1, daysInMonth(_date.year, _date.month));
      snap(_m, _date.month - 1, 12);
      snap(_y, _date.year - _min.year, _max.year - _min.year + 1);
    });
    widget.onChanged(_date);
  }

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, widget.theme);
    final l = ChronoTheme.localeOf(context, widget.locale);
    final order = widget.order ??
        (l.defaultDatePattern.startsWith('y')
            ? ChronoWheelOrder.ymd
            : l.defaultDatePattern.startsWith('M')
                ? ChronoWheelOrder.mdy
                : ChronoWheelOrder.dmy);
    final dim = daysInMonth(_date.year, _date.month);

    Widget wheel(FixedExtentScrollController c, int count, String Function(int) label, ValueChanged<int> onSelected,
        {int flex = 1, bool Function(int)? enabledAt}) {
      return Expanded(
        flex: flex,
        child: ListWheelScrollView.useDelegate(
          controller: c,
          itemExtent: widget.itemExtent,
          physics: widget.enabled ? const FixedExtentScrollPhysics() : const NeverScrollableScrollPhysics(),
          diameterRatio: 1.6,
          perspective: 0.004,
          overAndUnderCenterOpacity: 0.45,
          onSelectedItemChanged: (i) => onSelected(widget.looping ? i % count : i),
          childDelegate: widget.looping
              ? ListWheelChildLoopingListDelegate(children: [
                  for (var i = 0; i < count; i++) _item(t, label(i), enabledAt?.call(i) ?? true),
                ])
              : ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (_, i) => _item(t, label(i), enabledAt?.call(i) ?? true),
                ),
        ),
      );
    }

    final dayWheel = wheel(_d, dim, (i) => l.localizeDigits('${i + 1}'), (i) => _update(day: i + 1),
        enabledAt: (i) => DateTime(_date.year, _date.month, i + 1).isBetweenDays(_min, _max));
    final monthWheel = wheel(
        _m,
        12,
        (i) => widget.showMonthNames ? l.monthName(i + 1) : l.localizeDigits('${i + 1}'.padLeft(2, '0')),
        (i) => _update(month: i + 1),
        flex: widget.showMonthNames ? 2 : 1,
        enabledAt: (i) => !DateTime(_date.year, i + 2, 0).isBefore(_min) && !DateTime(_date.year, i + 1).isAfter(_max));
    final yearWheel = wheel(_y, _max.year - _min.year + 1, (i) => l.localizeDigits('${_min.year + i}'),
        (i) => _update(year: _min.year + i));

    final wheels = switch (order) {
      ChronoWheelOrder.dmy => [dayWheel, monthWheel, yearWheel],
      ChronoWheelOrder.mdy => [monthWheel, dayWheel, yearWheel],
      ChronoWheelOrder.ymd => [yearWheel, monthWheel, dayWheel],
    };

    return SizedBox(
      height: widget.itemExtent * widget.visibleItems,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: widget.itemExtent,
              decoration: ShapeDecoration(
                color: t.rangeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.dayRadius)),
              ),
            ),
          ),
          Opacity(opacity: widget.enabled ? 1 : 0.5, child: Row(children: wheels)),
        ],
      ),
    );
  }

  Widget _item(ChronoThemeData t, String text, bool enabled) => Center(
        child:
            Text(text, style: t.dayTextStyle!.copyWith(fontSize: 17, color: enabled ? t.textColor : t.disabledColor)),
      );
}
