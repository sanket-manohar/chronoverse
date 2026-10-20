<p align="center">
  <img src="https://raw.githubusercontent.com/sanket-manohar/chronoverse/main/doc/brand/banner.jpg" alt="Chronoverse" width="100%">
</p>

<p align="center">
  <b><a href="https://sanket-manohar.github.io/chronoverse/">Website</a></b> ·
  <b><a href="https://pub.dev/packages/chronoverse">pub.dev</a></b> ·
  <b><a href="https://pub.dev/documentation/chronoverse/latest/">API docs</a></b> ·
  <b><a href="https://github.com/sanket-manohar/chronoverse/blob/main/doc/guides/Chronoverse-Installation-Guide.pdf">Install guide</a></b> ·
  <b><a href="https://github.com/sanket-manohar/chronoverse/blob/main/doc/guides/Chronoverse-Integration-Guide.pdf">Integration guide</a></b>
</p>

<p align="center">
  <a href="https://pub.dev/packages/chronoverse"><img src="https://img.shields.io/pub/v/chronoverse?label=pub&color=5B5BD6" alt="pub version"></a>
  <a href="https://pub.dev/packages/chronoverse/score"><img src="https://img.shields.io/pub/points/chronoverse?color=5B5BD6" alt="pub points"></a>
  <img src="https://img.shields.io/badge/dependencies-0-success" alt="zero dependencies">
  <img src="https://img.shields.io/badge/platforms-android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue" alt="platforms">
  <a href="https://github.com/sanket-manohar/chronoverse/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-BSD--3--Clause-lightgrey" alt="BSD 3-Clause license"></a>
</p>

**Chronoverse** is an all-in-one calendar and date toolkit for Flutter. One import gives you
calendars, pickers, schedules, planners and a complete date/time function library, with
**zero third-party dependencies**, full theming and 14 built-in languages.

```dart
import 'package:chronoverse/chronoverse.dart';
```

---

## Contents

- [Why Chronoverse](#why-chronoverse)
- [Showcase](#showcase)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Widgets](#widgets)
- [The Chrono toolbox](#the-chrono-toolbox)
- [Events, recurrence and time zones](#events-recurrence-and-time-zones)
- [Theming](#theming)
- [Languages](#languages)
- [Freeze, enable, disable](#freeze-enable-disable)
- [Problems this package solves](#problems-this-package-solves)
- [Guides (PDF)](#guides-pdf)
- [Disclaimer and policies](#disclaimer-and-policies)
- [Author](#author)

---

## Why Chronoverse

| | |
|---|---|
| **Every calendar style** | Month with swipe, expandable week ↔ month, two-week, vertical scrolling (booking), year overview, week strip, day/week schedule, agenda list, activity heatmap. |
| **Every selection style** | Single, multiple, range (with max length and presets), or none. Freeze, read-only, and disabled states. |
| **Type or pick** | Masked text field with validation and natural language ("next friday", "in 3 days", "25 dec"). Dialogs, bottom sheets, wheels, quick year/month grids. |
| **Planner** | Multicolour event cards in 5 shapes, long-press drag of notes and events onto any day. |
| **Schedule** | Day / 3-day / week time grid, overlap layout, drag to move, drag edge to resize, work hours, blocked slots, now line. |
| **Toolbox** | 80+ ready functions in `Chrono`: date math, business days, age, leap years, ISO weeks, formatting, parsing, relative time, calendar conversions, time zones, moon phase and more. |
| **Events** | Attendees, organizer, reminders, status, visibility, busy/free, event types, meeting link, time zone, recurrence with exceptions, iCalendar (`.ics`) import/export. |
| **Calendars** | Gregorian, Hijri, Persian (Solar Hijri), Indian National (Saka), Buddhist, Julian; Julian Day, Unix and spreadsheet serial numbers. |
| **Lightweight** | Pure Dart core (`package:chronoverse/core.dart`) usable without Flutter UI. No dependencies at all. |
| **Cross-platform** | Android, iOS, web, macOS, Windows and Linux. Developed and tested on macOS and Windows as well as Linux. |

## Showcase

<p align="center">
  <img src="https://raw.githubusercontent.com/sanket-manohar/chronoverse/main/doc/screenshots/showcase1.jpg" alt="Month, planner, booking and pickers" width="100%">
  <img src="https://raw.githubusercontent.com/sanket-manohar/chronoverse/main/doc/screenshots/showcase2.jpg" alt="Schedule, agenda, year and strip" width="100%">
  <img src="https://raw.githubusercontent.com/sanket-manohar/chronoverse/main/doc/screenshots/showcase3.jpg" alt="Dialogs, sheets, quick picker, dark mode" width="100%">
  <img src="https://raw.githubusercontent.com/sanket-manohar/chronoverse/main/doc/screenshots/showcase4.jpg" alt="Theming, toolbox, collapsed week, dark schedule" width="100%">
</p>

The [`example`](https://github.com/sanket-manohar/chronoverse/tree/main/example) app contains every screen above. Run it with `cd example && flutter run`.

## Installation

```bash
flutter pub add chronoverse
```

or add it to `pubspec.yaml`:

```yaml
dependencies:
  chronoverse: ^0.1.0
```

No platform setup, no localization delegates, no initialization call. It works the same on
macOS, Windows and Linux development machines. Step-by-step instructions for each platform are in the
[Installation Guide (PDF)](https://github.com/sanket-manohar/chronoverse/blob/main/doc/guides/Chronoverse-Installation-Guide.pdf).

## Quick start

```dart
ChronoCalendar(
  onDaySelected: (day) => print(day),
)
```

A range picker that collapses to a week and shows events:

```dart
final controller = ChronoCalendarController();

ChronoCalendar(
  controller: controller,
  mode: ChronoSelectionMode.range,
  expandable: true,                    // drag the handle or tap to expand/collapse
  events: myEvents,                    // List<CalendarEvent>
  availability: DateAvailability(disablePast: true, disabledWeekdays: {DateTime.sunday}),
  maxRangeDays: 14,
  onRangeSelected: (range) => print(range), // null while only the start is picked
);

// Drive it from code
controller.showWeekOf(DateTime(2026, 12, 21)); // collapse to that week
controller.expand();                          // back to the full month
controller.jumpTo(DateTime(2027, 3));          // any month
controller.freeze();                          // look but don't touch
```

## Widgets

| Widget | What it is |
|---|---|
| `ChronoCalendar` | Month / two-week / week calendar, swipe between pages, expandable, quick year→month picker in the header, keyboard arrows, week numbers, markers or chips, drag & drop target. |
| `ChronoVerticalCalendar` | Continuous vertical months, ideal for bookings; `dayLabelBuilder` puts prices or notes under each day. |
| `ChronoYearView` | Twelve mini months with event shading. |
| `ChronoWeekStrip` | Horizontal scrolling day strip. |
| `ChronoScheduleView` | Time grid for 1–7 days with drag to move and resize. |
| `ChronoAgendaView` | Grouped list of upcoming events. |
| `ChronoHeatmap` | Activity heatmap over weeks. |
| `ChronoDateField` | Text field with mask, validation, natural language and a picker button. |
| `ChronoDateWheelPicker` | Day / month / year wheels in any order, leap-year aware. |
| `ChronoMonthPicker`, `ChronoYearPicker` | Quick month and year grids. |
| `showChronoDatePicker` | Date dialog or bottom sheet with a "type it" mode. |
| `showChronoRangePicker` | Range dialog or sheet with presets ("Last 7 days", "This month"…) and a maximum length. |
| `showChronoMultiDatePicker` | Pick any set of days. |
| `showChronoWheelPicker` | Wheels in a bottom sheet. |

### Typed input

```dart
ChronoDateField(
  pattern: 'dd/MM/yyyy',          // mask and validation follow the pattern
  firstDate: DateTime(2000),
  lastDate: DateTime(2030),
  onChanged: (date) => print(date), // null while invalid
);
```

Accepts `25/12/2026`, `25-12-2026`, `25.12.26`, `today`, `tomorrow`, `next friday`, `in 3 weeks`,
`2 days ago`, `end of month`, `25 dec`, `5th of march` and more.

### Planner: cards and drag & drop

```dart
ChronoCalendar(
  events: events,
  markerStyle: ChronoMarkerStyle.chips,                      // dots, bars or chips
  chipStyle: const ChronoChipStyle(shape: ChronoChipShape.pill),
  theme: const ChronoThemeData(cellHeight: 92),
  onDrop: (day, data) { /* add a note or move an event */ },
);

// Anything can be dragged onto a day:
ChronoDragItem<String>(data: 'Pay rent', child: Chip(label: Text('Pay rent')));
```

Event cards inside the calendar are draggable too: drop them on another day to reschedule.
Chip shapes: `rounded`, `pill`, `square`, `accentBar`, `outlined`. Each event has its own colour.

### Schedule

```dart
ChronoScheduleView(
  date: DateTime.now().startOfWeek(),
  numberOfDays: 7,
  events: events,
  startHour: 7,
  endHour: 21,
  workHours: (9, 18),
  snap: const Duration(minutes: 15),
  onEventMoved: (occurrence, start, end) { /* save */ },
  onSlotTap: (time) { /* create */ },
);
```

### Custom cells

Every cell can be replaced or decorated:

```dart
ChronoCalendar(
  dayBuilder: (context, state) => state.isWeekend ? MyWeekendCell(state) : null, // null = default
  dayLabelBuilder: (context, day) => Text('\$${price(day)}'),
);
```

## The Chrono toolbox

All functions are static on `Chrono`, and also available as extension methods on `DateTime`.
Import `package:chronoverse/core.dart` to use them without any widgets.

```dart
Chrono.isLeapYear(2028);                         // true
Chrono.daysInMonth(2024, 2);                     // 29
Chrono.addMonths(DateTime(2024, 1, 31), 1);      // 2024-02-29 (clamped, never overflows into March)
Chrono.age(DateTime(2000, 2, 29));               // correct for leap-day birthdays
Chrono.difference(a, b);                         // 3y 2m 5d
Chrono.addBusinessDays(DateTime.now(), 10, holidays: myHolidays);
Chrono.weekNumber(DateTime.now());               // ISO 8601 week
Chrono.format(DateTime.now(), 'EEEE, do MMMM yyyy', locale: 'fr');
Chrono.parse('25/12/2026', 'dd/MM/yyyy');
Chrono.parseNatural('next friday');
Chrono.timeAgo(someDate, locale: 'es');          // "hace 3 días"
Chrono.countdown(launchDate);                    // (days: 12, hours: 4, minutes: 10, seconds: 55, …)
Chrono.toHijri(DateTime.now());                  // and toPersian, toIndianNational, toBuddhist…
Chrono.toUnix(DateTime.now());
Chrono.toSpreadsheetSerial(DateTime.now());
Chrono.easter(2027);
Chrono.moonPhaseName(DateTime.now());
```

<details>
<summary>Full list of toolbox functions</summary>

**Now and basics** · `now` `today` `tomorrow` `yesterday` `isLeapYear` `daysInMonth` `daysInYear`
`weekNumber` `weeksInYear` `quarter` `dayOfYear` `isWeekend` `isPast` `isFuture` `isSameDay`
`isValidDate` `isValidYmd`

**Arithmetic** · `addDays` `addWeeks` `addMonths` `addYears` `addBusinessDays` `businessDaysBetween`
`daysBetween` `weeksBetween` `monthsBetween` `yearsBetween` `difference` `age` `nextAnniversary`
`datesBetween` `monthMatrix` `easter` `nthWeekday`

**Format and parse** · `format` `parse` `parseNatural` `timeAgo` `formatDuration` `formatHms`
`countdown` `monthNames` `weekdayNames`

**Conversions** · `toHijri` `toPersian` `toIndianNational` `toBuddhist` `toJulianCalendar`
`fromCalendar` `toJulianDay` `toUnix` `fromUnix` `toUnixMillis` `fromUnixMillis`
`toSpreadsheetSerial` `fromSpreadsheetSerial` `atOffset` `convertOffset` `toIso` `fromIso`

**Time of day** · `minutesOfDay` `isTimeBetween` (works across midnight) `roundTime` `partOfDay`

**Fun extras** · `zodiacSign` `chineseZodiac` `moonPhase` `moonPhaseName`

**DateTime extensions** · `dateOnly` `endOfDay` `isToday` `isSameMonth` `startOfWeek` `endOfMonth`
`startOfQuarter` `nextWeekday` `nthWeekdayOfMonth` `daysUntil` `clampTo` `atTime` `isoWeekNumber` and more.

**Classes** · `DateRange` `DateDifference` `DateMath` `DateAvailability` `ChronoFormat`
`RelativeTime` `NaturalDateParser` `CalendarConverter` `ZonedDateTime` `ChronoTimeZone`
`RecurrenceRule` `CalendarEvent` `Schedule` `ICalendar`

</details>

## Events, recurrence and time zones

```dart
final standup = CalendarEvent(
  id: 'standup',
  title: 'Stand-up',
  start: DateTime(2026, 10, 19, 9, 30),
  end: DateTime(2026, 10, 19, 9, 45),
  timeZone: 'Europe/London',
  recurrence: RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
  exceptionDates: [DateTime(2026, 12, 25)],
  attendees: [const EventAttendee(email: 'sam@example.com', name: 'Sam', response: AttendeeResponse.accepted)],
  reminders: [const EventReminder.minutes(10), const EventReminder.minutes(60, method: ReminderMethod.email)],
  meetingUrl: 'https://example.com/room/42',
  color: 0xFF5B5BD6,
);

standup.recurrence!.describe();                      // "Every week on weekdays"
events.occurrencesIn(DateRange.month(DateTime.now()));
Schedule.freeSlots(events.on(today), from: today.atTime(9), to: today.atTime(17), minLength: const Duration(minutes: 30));

final ics = ICalendar.encode(events);                // export .ics
final imported = ICalendar.decode(icsText);          // import .ics

final kolkata = ChronoTimeZone.get('Asia/Kolkata');
kolkata.convert(DateTime(2026, 10, 20, 19, 30), ChronoTimeZone.get('America/New_York'));
```

Time zones include daylight-saving rules for North America, Europe, Australia and New Zealand,
with correct handling of the skipped and repeated hours. You can register any extra zone with
`ChronoTimeZone.register`.

## Theming

Everything is themeable: colours, day shape (circle, rounded, square, stadium), radius, cell size,
padding, header height, text styles, marker size, animations. Set it once for the whole app:

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: Colors.indigo,
    extensions: const [ChronoThemeData(dayShape: ChronoDayShape.rounded, cellHeight: 48)],
  ),
);
```

or per widget with `theme:`. Light and dark mode follow your app automatically.
`ChronoThemeData.fromSeed(color)` builds a full palette from one colour.

## Languages

Built in: English, Spanish, French, German, Italian, Portuguese, Russian, Arabic (RTL), Hindi,
Marathi, Chinese, Japanese, Korean and Turkish. Each locale knows its month and weekday names,
first day of week, weekend days, date order, plural rules and native digits.

```dart
ChronoCalendar(locale: ChronoLocale.of('ar'), nativeDigits: true);
```

Add your own language with `ChronoLocale.register(...)`. Nothing to set up in `MaterialApp`.

## Freeze, enable, disable

| Need | How |
|---|---|
| Temporarily lock all interaction | `controller.freeze()` / `controller.unfreeze()` |
| Show but don't allow changes | `readOnly: true` |
| Disable the whole widget (greyed out) | `enabled: false` |
| Disable specific days | `availability: DateAvailability(disabledDates: [...], disabledRanges: [...], disabledWeekdays: {...})` |
| Only allow some days | `DateAvailability(enabledDates: [...])` |
| No past / no future | `DateAvailability(disablePast: true)` |
| Any custom rule | `selectableDayPredicate: (day) => ...` |
| Limit range length | `maxRangeDays: 14` |
| Limit navigation | `firstDay:` / `lastDay:` |

## Problems this package solves

Common complaints with calendar widgets, and what Chronoverse does about them:

- **Month arithmetic overflows** (Jan 31 + 1 month = March 3). Chronoverse clamps to the last valid day.
- **Daylight-saving bugs** (a day that is 23 hours long breaks "add one day"). All date math is calendar-based, not duration-based.
- **Leap years** (Feb 29 birthdays, Feb 29 + 1 year). Handled everywhere, including the wheels and age.
- **No quick way to jump years.** Tap the header to pick a year, then a month.
- **Can't control the visible week from code.** `showWeekOf`, `expand`, `collapse`, `jumpTo`.
- **Calendar height jumps between months.** `sixWeekMonths: true` keeps it fixed.
- **Localization needs extra setup.** It doesn't: 14 languages work with one parameter.
- **Slow with many events.** Events are indexed per day once, not filtered on every cell build.
- **Range picker accepts blocked days in the middle.** Ranges that cross unavailable days are rejected.
- **Hard to customise one cell.** Builders return `null` to keep the default, so you only override what you need.
- **Broken in right-to-left, large text, or keyboard use.** RTL, text scaling, arrow-key navigation and screen-reader labels are built in.
- **Dependency conflicts.** There are none to conflict with.

## Guides (PDF)

- [Installation Guide](https://github.com/sanket-manohar/chronoverse/blob/main/doc/guides/Chronoverse-Installation-Guide.pdf): requirements, macOS and Windows setup, adding the package, verifying, troubleshooting.
- [Integration Guide](https://github.com/sanket-manohar/chronoverse/blob/main/doc/guides/Chronoverse-Integration-Guide.pdf): every widget and function with code, theming, languages, events, time zones and best practices.

API reference: [pub.dev/documentation/chronoverse](https://pub.dev/documentation/chronoverse/latest/).

## Disclaimer and policies

Chronoverse is provided **"as is", without warranty of any kind**. Date, time, time-zone, calendar
conversion, recurrence and every other calculation may contain errors. **You are solely responsible
for verifying all results** before relying on them, especially for legal, financial, medical,
religious, safety-critical or time-critical purposes. The authors and contributors accept no
liability for any loss or damage arising from its use.

Please read the full documents before use:

- [DISCLAIMER](https://github.com/sanket-manohar/chronoverse/blob/main/DISCLAIMER.md)
- [TERMS OF USE](https://github.com/sanket-manohar/chronoverse/blob/main/TERMS_OF_USE.md)
- [PRIVACY POLICY](https://github.com/sanket-manohar/chronoverse/blob/main/PRIVACY.md)
- [SECURITY POLICY](https://github.com/sanket-manohar/chronoverse/blob/main/SECURITY.md)
- [LICENSE (BSD 3-Clause)](https://github.com/sanket-manohar/chronoverse/blob/main/LICENSE)

By using this package you agree to these documents.

## Author

Chronoverse is designed and developed by **Sanket Santosh Vidya Manohar**.

- Website: [sanketmanohar.com](https://sanketmanohar.com/)
- GitHub: [@sanket-manohar](https://github.com/sanket-manohar)
- More packages: [pub.dev/publishers/sanketmanohar.com](https://pub.dev/publishers/sanketmanohar.com/packages)

Found a bug or have an idea? [Open an issue](https://github.com/sanket-manohar/chronoverse/issues).

Copyright (c) 2026, Sanket Manohar. Released under the [BSD 3-Clause License](https://github.com/sanket-manohar/chronoverse/blob/main/LICENSE).
