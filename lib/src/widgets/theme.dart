import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../l10n/chrono_locale.dart';

/// Shape of day cells and selection highlights.
enum ChronoDayShape {
  /// Circle.
  circle,

  /// Square with rounded corners ([ChronoThemeData.dayRadius]).
  rounded,

  /// Sharp square.
  square,

  /// Pill shape filling the cell width.
  stadium,
}

/// Every visual knob of Chronoverse widgets: colours, text styles, shapes,
/// sizes and animation.
///
/// Provide it in one of three ways (first found wins):
/// 1. the `theme:` parameter of a widget,
/// 2. a [ChronoTheme] ancestor,
/// 3. `ThemeData(extensions: [ChronoThemeData(...)])` for the whole app.
///
/// Anything left null is derived from the app's [ColorScheme] and
/// [TextTheme], so the calendar matches your app with zero setup.
@immutable
class ChronoThemeData extends ThemeExtension<ChronoThemeData> {
  /// Creates a theme; null fields fall back to the app theme.
  const ChronoThemeData({
    this.primaryColor,
    this.onPrimaryColor,
    this.backgroundColor,
    this.textColor,
    this.mutedTextColor,
    this.todayColor,
    this.rangeColor,
    this.disabledColor,
    this.weekendTextColor,
    this.holidayTextColor,
    this.eventColor,
    this.borderColor,
    this.dayShape = ChronoDayShape.circle,
    this.dayRadius = 10,
    this.todayBorderWidth = 1.2,
    this.cellHeight = 44,
    this.cellPadding = 3,
    this.headerHeight = 52,
    this.weekdayRowHeight = 28,
    this.markerSize = 5,
    this.maxMarkers = 3,
    this.dayTextStyle,
    this.headerTextStyle,
    this.weekdayTextStyle,
    this.weekdayStyle = WeekdayStyle.short,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = Curves.easeOutCubic,
    this.decoration,
  });

  /// Theme derived from a seed colour, like `ColorScheme.fromSeed`.
  factory ChronoThemeData.fromSeed(Color seed,
      {Brightness brightness = Brightness.light, ChronoDayShape dayShape = ChronoDayShape.circle}) {
    final s = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ChronoThemeData(dayShape: dayShape).resolve(s, null);
  }

  /// Selected-day fill and accent colour.
  final Color? primaryColor;

  /// Text on [primaryColor].
  final Color? onPrimaryColor;

  /// Calendar background.
  final Color? backgroundColor;

  /// Default day text colour.
  final Color? textColor;

  /// Outside-month and secondary text colour.
  final Color? mutedTextColor;

  /// Today's ring colour.
  final Color? todayColor;

  /// Background band for days inside a selected range.
  final Color? rangeColor;

  /// Text colour of days that cannot be selected.
  final Color? disabledColor;

  /// Weekend day text colour.
  final Color? weekendTextColor;

  /// Holiday text colour.
  final Color? holidayTextColor;

  /// Default event and marker colour.
  final Color? eventColor;

  /// Grid and divider lines.
  final Color? borderColor;

  /// Shape of day highlights.
  final ChronoDayShape dayShape;

  /// Corner radius for [ChronoDayShape.rounded].
  final double dayRadius;

  /// Width of today's ring.
  final double todayBorderWidth;

  /// Height of one day row.
  final double cellHeight;

  /// Space around each day highlight.
  final double cellPadding;

  /// Height of the month/year header.
  final double headerHeight;

  /// Height of the weekday-name row.
  final double weekdayRowHeight;

  /// Diameter of event dots.
  final double markerSize;

  /// Maximum event dots per day.
  final int maxMarkers;

  /// Day number style.
  final TextStyle? dayTextStyle;

  /// Header title style.
  final TextStyle? headerTextStyle;

  /// Weekday-name style.
  final TextStyle? weekdayTextStyle;

  /// Length of weekday names in the header row.
  final WeekdayStyle weekdayStyle;

  /// Page, expand and selection animation length.
  final Duration animationDuration;

  /// Animation curve.
  final Curve animationCurve;

  /// Decoration around the whole calendar (card look, border, shadow).
  final BoxDecoration? decoration;

  /// Fills every null colour/style from [scheme] and [textTheme].
  ChronoThemeData resolve(ColorScheme scheme, TextTheme? textTheme) {
    final tt = textTheme ?? Typography.material2021().black;
    return copyWith(
      primaryColor: primaryColor ?? scheme.primary,
      onPrimaryColor: onPrimaryColor ?? scheme.onPrimary,
      backgroundColor: backgroundColor ?? Colors.transparent,
      textColor: textColor ?? scheme.onSurface,
      mutedTextColor: mutedTextColor ?? scheme.onSurface.withValues(alpha: 0.38),
      todayColor: todayColor ?? scheme.primary,
      rangeColor: rangeColor ?? scheme.primary.withValues(alpha: 0.14),
      disabledColor: disabledColor ?? scheme.onSurface.withValues(alpha: 0.24),
      weekendTextColor: weekendTextColor ?? scheme.onSurface,
      holidayTextColor: holidayTextColor ?? scheme.error,
      eventColor: eventColor ?? scheme.tertiary,
      borderColor: borderColor ?? scheme.outlineVariant,
      dayTextStyle: (tt.bodyMedium ?? const TextStyle()).merge(dayTextStyle),
      headerTextStyle:
          (tt.titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w600).merge(headerTextStyle),
      weekdayTextStyle:
          (tt.labelSmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant).merge(weekdayTextStyle),
    );
  }

  /// The decoration for a day highlight in this theme's [dayShape].
  ShapeBorder dayShapeBorder([BorderSide side = BorderSide.none]) => switch (dayShape) {
        ChronoDayShape.circle => CircleBorder(side: side),
        ChronoDayShape.rounded => RoundedRectangleBorder(borderRadius: BorderRadius.circular(dayRadius), side: side),
        ChronoDayShape.square => RoundedRectangleBorder(side: side),
        ChronoDayShape.stadium => StadiumBorder(side: side),
      };

  @override
  ChronoThemeData copyWith({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? mutedTextColor,
    Color? todayColor,
    Color? rangeColor,
    Color? disabledColor,
    Color? weekendTextColor,
    Color? holidayTextColor,
    Color? eventColor,
    Color? borderColor,
    ChronoDayShape? dayShape,
    double? dayRadius,
    double? todayBorderWidth,
    double? cellHeight,
    double? cellPadding,
    double? headerHeight,
    double? weekdayRowHeight,
    double? markerSize,
    int? maxMarkers,
    TextStyle? dayTextStyle,
    TextStyle? headerTextStyle,
    TextStyle? weekdayTextStyle,
    WeekdayStyle? weekdayStyle,
    Duration? animationDuration,
    Curve? animationCurve,
    BoxDecoration? decoration,
  }) =>
      ChronoThemeData(
        primaryColor: primaryColor ?? this.primaryColor,
        onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textColor: textColor ?? this.textColor,
        mutedTextColor: mutedTextColor ?? this.mutedTextColor,
        todayColor: todayColor ?? this.todayColor,
        rangeColor: rangeColor ?? this.rangeColor,
        disabledColor: disabledColor ?? this.disabledColor,
        weekendTextColor: weekendTextColor ?? this.weekendTextColor,
        holidayTextColor: holidayTextColor ?? this.holidayTextColor,
        eventColor: eventColor ?? this.eventColor,
        borderColor: borderColor ?? this.borderColor,
        dayShape: dayShape ?? this.dayShape,
        dayRadius: dayRadius ?? this.dayRadius,
        todayBorderWidth: todayBorderWidth ?? this.todayBorderWidth,
        cellHeight: cellHeight ?? this.cellHeight,
        cellPadding: cellPadding ?? this.cellPadding,
        headerHeight: headerHeight ?? this.headerHeight,
        weekdayRowHeight: weekdayRowHeight ?? this.weekdayRowHeight,
        markerSize: markerSize ?? this.markerSize,
        maxMarkers: maxMarkers ?? this.maxMarkers,
        dayTextStyle: dayTextStyle ?? this.dayTextStyle,
        headerTextStyle: headerTextStyle ?? this.headerTextStyle,
        weekdayTextStyle: weekdayTextStyle ?? this.weekdayTextStyle,
        weekdayStyle: weekdayStyle ?? this.weekdayStyle,
        animationDuration: animationDuration ?? this.animationDuration,
        animationCurve: animationCurve ?? this.animationCurve,
        decoration: decoration ?? this.decoration,
      );

  @override
  ChronoThemeData lerp(ChronoThemeData? other, double t) {
    if (other == null) return this;
    Color? c(Color? a, Color? b) => Color.lerp(a, b, t);
    double d(double a, double b) => lerpDouble(a, b, t)!;
    return ChronoThemeData(
      primaryColor: c(primaryColor, other.primaryColor),
      onPrimaryColor: c(onPrimaryColor, other.onPrimaryColor),
      backgroundColor: c(backgroundColor, other.backgroundColor),
      textColor: c(textColor, other.textColor),
      mutedTextColor: c(mutedTextColor, other.mutedTextColor),
      todayColor: c(todayColor, other.todayColor),
      rangeColor: c(rangeColor, other.rangeColor),
      disabledColor: c(disabledColor, other.disabledColor),
      weekendTextColor: c(weekendTextColor, other.weekendTextColor),
      holidayTextColor: c(holidayTextColor, other.holidayTextColor),
      eventColor: c(eventColor, other.eventColor),
      borderColor: c(borderColor, other.borderColor),
      dayShape: t < 0.5 ? dayShape : other.dayShape,
      dayRadius: d(dayRadius, other.dayRadius),
      todayBorderWidth: d(todayBorderWidth, other.todayBorderWidth),
      cellHeight: d(cellHeight, other.cellHeight),
      cellPadding: d(cellPadding, other.cellPadding),
      headerHeight: d(headerHeight, other.headerHeight),
      weekdayRowHeight: d(weekdayRowHeight, other.weekdayRowHeight),
      markerSize: d(markerSize, other.markerSize),
      maxMarkers: t < 0.5 ? maxMarkers : other.maxMarkers,
      dayTextStyle: TextStyle.lerp(dayTextStyle, other.dayTextStyle, t),
      headerTextStyle: TextStyle.lerp(headerTextStyle, other.headerTextStyle, t),
      weekdayTextStyle: TextStyle.lerp(weekdayTextStyle, other.weekdayTextStyle, t),
      weekdayStyle: t < 0.5 ? weekdayStyle : other.weekdayStyle,
      animationDuration: t < 0.5 ? animationDuration : other.animationDuration,
      animationCurve: t < 0.5 ? animationCurve : other.animationCurve,
      decoration: BoxDecoration.lerp(decoration, other.decoration, t),
    );
  }
}

/// Applies a [ChronoThemeData] (and optionally a [ChronoLocale]) to every
/// Chronoverse widget below it.
class ChronoTheme extends InheritedWidget {
  /// Creates a theme scope.
  const ChronoTheme({super.key, this.data, this.locale, required super.child});

  /// Theme for descendants.
  final ChronoThemeData? data;

  /// Locale for descendants; null follows the app's `Localizations`.
  final ChronoLocale? locale;

  /// Resolved theme for [context], with [override] taking priority.
  static ChronoThemeData of(BuildContext context, [ChronoThemeData? override]) {
    final theme = Theme.of(context);
    final base = override ??
        context.dependOnInheritedWidgetOfExactType<ChronoTheme>()?.data ??
        theme.extension<ChronoThemeData>() ??
        const ChronoThemeData();
    return base.resolve(theme.colorScheme, theme.textTheme);
  }

  /// Locale for [context]: [override], then a [ChronoTheme] ancestor, then
  /// the app's current locale, then English.
  static ChronoLocale localeOf(BuildContext context, [ChronoLocale? override]) {
    if (override != null) return override;
    final scoped = context.dependOnInheritedWidgetOfExactType<ChronoTheme>()?.locale;
    if (scoped != null) return scoped;
    final app = Localizations.maybeLocaleOf(context);
    return ChronoLocale.of(app?.toLanguageTag());
  }

  @override
  bool updateShouldNotify(ChronoTheme oldWidget) => data != oldWidget.data || locale != oldWidget.locale;
}
