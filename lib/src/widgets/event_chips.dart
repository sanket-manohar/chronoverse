import 'package:flutter/material.dart';

import '../core/calendar_event.dart';
import 'day_cell.dart';
import 'theme.dart';

/// How a day shows its events.
enum ChronoMarkerStyle {
  /// Small coloured dots under the number.
  dots,

  /// Thin coloured bars under the number.
  bars,

  /// Coloured cards with titles inside the cell (planner look). Use a
  /// taller [ChronoThemeData.cellHeight], e.g. 96.
  chips,
}

/// Shape of event cards in [ChronoMarkerStyle.chips].
enum ChronoChipShape {
  /// Rounded rectangle.
  rounded,

  /// Fully rounded ends.
  pill,

  /// Sharp corners.
  square,

  /// Tinted card with a solid colour bar on the leading edge.
  accentBar,

  /// Outlined card.
  outlined,
}

/// Look of one event card.
class ChronoChipStyle {
  /// Creates a chip style.
  const ChronoChipStyle({
    this.shape = ChronoChipShape.rounded,
    this.height = 16,
    this.radius = 4,
    this.fontSize = 10,
    this.spacing = 2,
  });

  /// Card shape.
  final ChronoChipShape shape;

  /// Card height.
  final double height;

  /// Corner radius for [ChronoChipShape.rounded] and others.
  final double radius;

  /// Title font size.
  final double fontSize;

  /// Gap between cards.
  final double spacing;
}

/// The text shown on a chip for an item returned by an event loader.
String chronoItemLabel(Object? item) => switch (item) {
      EventOccurrence(:final event) => event.title,
      CalendarEvent(:final title) => title,
      null => '',
      _ => item.toString(),
    };

/// One coloured event card. Use it on its own (e.g. as drag feedback or in
/// a side panel) or let the calendar draw it.
class ChronoEventChip extends StatelessWidget {
  /// Creates a chip.
  const ChronoEventChip({
    super.key,
    required this.label,
    required this.color,
    this.style = const ChronoChipStyle(),
    this.icon,
    this.width,
  });

  /// Title.
  final String label;

  /// Card colour.
  final Color color;

  /// Shape and size.
  final ChronoChipStyle style;

  /// Optional leading icon.
  final IconData? icon;

  /// Fixed width (fills the cell by default).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black87;
    final radius = switch (style.shape) {
      ChronoChipShape.pill => BorderRadius.circular(style.height),
      ChronoChipShape.square => BorderRadius.zero,
      _ => BorderRadius.circular(style.radius),
    };
    final tinted = style.shape == ChronoChipShape.accentBar || style.shape == ChronoChipShape.outlined;
    final fg = tinted ? color : onColor;
    return Container(
      width: width,
      height: style.height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: style.shape == ChronoChipShape.outlined
            ? null
            : tinted
                ? color.withValues(alpha: 0.16)
                : color,
        borderRadius: radius,
        border: switch (style.shape) {
          ChronoChipShape.outlined => Border.all(color: color, width: 1),
          ChronoChipShape.accentBar => BorderDirectional(start: BorderSide(color: color, width: 3)),
          _ => null,
        },
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: style.fontSize + 2, color: fg), const SizedBox(width: 2)],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: style.fontSize, color: fg, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
      ]),
    );
  }
}

/// A day cell that lists its items as coloured cards (planner style), with
/// "+2" when they do not fit. Items can be dragged to other days.
class ChronoChipsDayCell extends StatelessWidget {
  /// Creates the cell.
  const ChronoChipsDayCell({
    super.key,
    required this.state,
    required this.theme,
    required this.text,
    this.chipStyle = const ChronoChipStyle(),
    this.labelFor = chronoItemLabel,
    this.draggable = false,
    this.onItemTap,
  });

  /// Day state (its [ChronoDayState.items] are drawn).
  final ChronoDayState state;

  /// Resolved theme.
  final ChronoThemeData theme;

  /// Localised day number.
  final String text;

  /// Card look.
  final ChronoChipStyle chipStyle;

  /// Title for each item.
  final String Function(Object? item) labelFor;

  /// Long-press an item to drag it to another day.
  final bool draggable;

  /// Tap on an item.
  final ValueChanged<Object?>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final t = theme;
    final selected = s.isSelected || s.isRangeStart || s.isRangeEnd;
    final numberColor = selected
        ? t.onPrimaryColor
        : s.isToday
            ? t.todayColor
            : s.isDisabled
                ? t.disabledColor
                : s.isOutside
                    ? t.mutedTextColor
                    : s.isHoliday
                        ? t.holidayTextColor
                        : t.textColor;
    return LayoutBuilder(builder: (context, box) {
      final numberH = 22.0;
      final room = box.maxHeight - numberH - 2;
      final per = chipStyle.height + chipStyle.spacing;
      var fit = (room / per).floor().clamp(0, s.items.length);
      if (fit < s.items.length && fit > 0) fit--; // keep a row for "+n"
      return Container(
        decoration: BoxDecoration(
          color: s.isInRange ? t.rangeColor : null,
          border: Border(
            top: BorderSide(color: t.borderColor!.withValues(alpha: 0.5), width: 0.5),
            left: BorderSide(color: t.borderColor!.withValues(alpha: 0.5), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Container(
                height: numberH - 2,
                constraints: BoxConstraints(minWidth: numberH - 2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: selected ? t.primaryColor : null,
                  shape: StadiumBorder(
                    side: s.isToday && !selected ? BorderSide(color: t.todayColor!) : BorderSide.none,
                  ),
                ),
                child: Text(text,
                    style: t.dayTextStyle!.copyWith(
                        fontSize: 12, color: numberColor, fontWeight: s.isToday || selected ? FontWeight.w700 : null)),
              ),
            ),
            const SizedBox(height: 2),
            for (var i = 0; i < fit; i++)
              Padding(
                padding: EdgeInsets.only(bottom: chipStyle.spacing),
                child: _chip(context, s.items[i], s.markerColors[i]),
              ),
            if (fit < s.items.length)
              Text('+${s.items.length - fit}',
                  style: t.weekdayTextStyle!.copyWith(fontSize: chipStyle.fontSize, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    });
  }

  Widget _chip(BuildContext context, Object? item, Color color) {
    final chip = ChronoEventChip(label: labelFor(item), color: color, style: chipStyle);
    final tappable = onItemTap == null ? chip : GestureDetector(onTap: () => onItemTap!(item), child: chip);
    if (!draggable || item == null) return tappable;
    return LongPressDraggable<Object>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: ChronoEventChip(
          label: labelFor(item),
          color: color,
          width: 140,
          style: ChronoChipStyle(shape: chipStyle.shape, height: 26, fontSize: 12, radius: chipStyle.radius),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: tappable,
    );
  }
}

/// Wrap any widget (a note, a task, a contact) to drag it onto a calendar
/// day. The calendar's `onDrop` receives [data].
class ChronoDragItem<T extends Object> extends StatelessWidget {
  /// Creates a draggable item.
  const ChronoDragItem({
    super.key,
    required this.data,
    required this.child,
    this.feedback,
    this.longPress = true,
  });

  /// Payload delivered to the drop target.
  final T data;

  /// The widget shown in place.
  final Widget child;

  /// What follows the finger (a translucent copy of [child] by default).
  final Widget? feedback;

  /// Start dragging on long press (true) or immediately (false, desktop).
  final bool longPress;

  @override
  Widget build(BuildContext context) {
    final fb = Material(
      color: Colors.transparent,
      child: Opacity(
          opacity: 0.9,
          child: feedback ?? ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: child)),
    );
    return longPress
        ? LongPressDraggable<T>(
            data: data, feedback: fb, childWhenDragging: Opacity(opacity: 0.4, child: child), child: child)
        : Draggable<T>(data: data, feedback: fb, childWhenDragging: Opacity(opacity: 0.4, child: child), child: child);
  }
}
