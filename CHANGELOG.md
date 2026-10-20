## 1.0.0

First public release.

### Widgets
* `ChronoCalendar`: month, two-week and week formats with swipe paging, expandable week ↔ month, quick year → month picker, week numbers, keyboard navigation, single / multiple / range selection, freeze, read-only and disabled states.
* Event markers as dots, bars or multicolour cards in five shapes, with drag & drop of events and notes onto any day.
* `ChronoVerticalCalendar`, `ChronoYearView`, `ChronoWeekStrip`, `ChronoScheduleView` (drag to move and resize), `ChronoAgendaView`, `ChronoHeatmap`.
* `ChronoDateField` with input mask, validation and natural-language input.
* `ChronoDateWheelPicker`, `ChronoMonthPicker`, `ChronoYearPicker`.
* Dialogs and bottom sheets: `showChronoDatePicker`, `showChronoRangePicker` (presets, maximum length), `showChronoMultiDatePicker`, `showChronoWheelPicker`.
* `ChronoThemeData` theme extension covering colours, shapes, sizes, text styles and animation.

### Core (pure Dart)
* `Chrono` toolbox with 80+ date and time functions.
* `DateTime` extensions, `DateRange`, `DateDifference`, `DateMath`, `DateAvailability`.
* `ChronoFormat` pattern formatting and parsing, `RelativeTime`, `NaturalDateParser`.
* 14 built-in languages with plural rules, native digits and right-to-left support.
* Calendar conversions: Hijri, Persian, Indian National, Buddhist, Julian, Julian Day, Unix, spreadsheet serial.
* `ChronoTimeZone` with daylight-saving rules, `ZonedDateTime`.
* `CalendarEvent` with attendees, organizer, reminders, status, visibility, availability, event types, meeting links and time zones.
* `RecurrenceRule` (iCalendar RRULE subset) with exceptions and human-readable descriptions.
* `ICalendar` import and export.
* `Schedule` overlap layout, free-slot search and appointment slots.
