import 'package:flutter/material.dart';

import '../l10n/chrono_locale.dart';
import 'theme.dart';

class _GridChip extends StatelessWidget {
  const _GridChip({
    required this.text,
    required this.selected,
    required this.current,
    required this.enabled,
    required this.onTap,
    required this.theme,
  });

  final String text;
  final bool selected;
  final bool current;
  final bool enabled;
  final VoidCallback onTap;
  final ChronoThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? theme.disabledColor
        : selected
            ? theme.onPrimaryColor
            : current
                ? theme.todayColor
                : theme.textColor;
    return Semantics(
      button: enabled,
      selected: selected,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: theme.animationDuration,
          margin: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? theme.primaryColor : Colors.transparent,
            shape: StadiumBorder(
              side: current && !selected
                  ? BorderSide(color: theme.todayColor!, width: theme.todayBorderWidth)
                  : BorderSide.none,
            ),
          ),
          child: Text(text,
              style: theme.dayTextStyle!.copyWith(color: color, fontWeight: selected ? FontWeight.w600 : null)),
        ),
      ),
    );
  }
}

/// A 3×4 grid of months for quick month selection.
class ChronoMonthPicker extends StatelessWidget {
  /// Creates a month grid for [year].
  const ChronoMonthPicker({
    super.key,
    required this.year,
    required this.onMonthSelected,
    this.selectedMonth,
    this.firstDay,
    this.lastDay,
    this.locale,
    this.theme,
    this.onYearTap,
    this.onYearChanged,
  });

  /// Year whose months are shown.
  final int year;

  /// Highlighted month (as any date in it).
  final DateTime? selectedMonth;

  /// Earliest allowed month.
  final DateTime? firstDay;

  /// Latest allowed month.
  final DateTime? lastDay;

  /// Called with the first day of the chosen month.
  final ValueChanged<DateTime> onMonthSelected;

  /// Tap on the year title (e.g. to open [ChronoYearPicker]).
  final VoidCallback? onYearTap;

  /// Arrows change the year; null hides them.
  final ValueChanged<int>? onYearChanged;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final t = ChronoTheme.of(context, theme);
    final l = ChronoTheme.localeOf(context, locale);
    final now = DateTime.now();
    bool enabled(int m) {
      final firstOfMonth = DateTime(year, m);
      final lastOfMonth = DateTime(year, m + 1, 0);
      return (firstDay == null || !lastOfMonth.isBefore(DateTime(firstDay!.year, firstDay!.month, firstDay!.day))) &&
          (lastDay == null || !firstOfMonth.isAfter(lastDay!));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: t.headerHeight,
          child: Row(children: [
            if (onYearChanged != null)
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: firstDay != null && year <= firstDay!.year ? null : () => onYearChanged!(year - 1),
              ),
            Expanded(
              child: Center(
                child: TextButton(
                  onPressed: onYearTap,
                  child: Text(l.localizeDigits('$year'), style: t.headerTextStyle),
                ),
              ),
            ),
            if (onYearChanged != null)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: lastDay != null && year >= lastDay!.year ? null : () => onYearChanged!(year + 1),
              ),
          ]),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            for (var m = 1; m <= 12; m++)
              _GridChip(
                text: l.monthName(m, short: true),
                selected: selectedMonth != null && selectedMonth!.year == year && selectedMonth!.month == m,
                current: now.year == year && now.month == m,
                enabled: enabled(m),
                onTap: () => onMonthSelected(DateTime(year, m)),
                theme: t,
              ),
          ],
        ),
      ],
    );
  }
}

/// A scrollable grid of years that opens scrolled to the selected year.
class ChronoYearPicker extends StatefulWidget {
  /// Creates a year grid between [firstYear] and [lastYear].
  const ChronoYearPicker({
    super.key,
    required this.firstYear,
    required this.lastYear,
    required this.onYearSelected,
    this.selectedYear,
    this.columns = 4,
    this.height = 280,
    this.locale,
    this.theme,
  });

  /// First year shown.
  final int firstYear;

  /// Last year shown.
  final int lastYear;

  /// Highlighted year.
  final int? selectedYear;

  /// Called with the chosen year.
  final ValueChanged<int> onYearSelected;

  /// Columns in the grid.
  final int columns;

  /// Height of the scrollable area.
  final double height;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override.
  final ChronoThemeData? theme;

  @override
  State<ChronoYearPicker> createState() => _ChronoYearPickerState();
}

class _ChronoYearPickerState extends State<ChronoYearPicker> {
  late final ScrollController _scroll;
  static const _rowHeight = 52.0;

  @override
  void initState() {
    super.initState();
    final target = (widget.selectedYear ?? DateTime.now().year).clamp(widget.firstYear, widget.lastYear);
    final row = (target - widget.firstYear) ~/ widget.columns;
    _scroll = ScrollController(
        initialScrollOffset: (row * _rowHeight - widget.height / 2 + _rowHeight / 2).clamp(0, double.infinity));
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
    final count = widget.lastYear - widget.firstYear + 1;
    final now = DateTime.now().year;
    return SizedBox(
      height: widget.height,
      child: GridView.builder(
        controller: _scroll,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.columns,
          mainAxisExtent: _rowHeight,
        ),
        itemCount: count,
        itemBuilder: (context, i) {
          final y = widget.firstYear + i;
          return _GridChip(
            text: l.localizeDigits('$y'),
            selected: y == widget.selectedYear,
            current: y == now,
            enabled: true,
            onTap: () => widget.onYearSelected(y),
            theme: t,
          );
        },
      ),
    );
  }
}
