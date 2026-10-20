import 'date_extensions.dart';
import 'date_range.dart';
import 'recurrence.dart';
import 'time_zones.dart';

/// An event shown in calendar views. Pure Dart, so it works in models,
/// repositories and server code without Flutter.
///
/// [T] is any payload you want to carry (your own model, an id, a map).
class CalendarEvent<T> {
  /// Creates an event. [end] must not be before [start].
  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.description,
    this.location,
    this.color,
    this.recurrence,
    this.exceptionDates = const [],
    this.additionalDates = const [],
    this.timeZone,
    this.calendarId,
    this.status = EventStatus.confirmed,
    this.visibility = EventVisibility.normal,
    this.showAs = EventShowAs.busy,
    this.type = EventType.normal,
    this.organizer,
    this.attendees = const [],
    this.reminders = const [],
    this.url,
    this.meetingUrl,
    this.data,
  }) : assert(!end.isBefore(start), 'end must not be before start');

  /// An all-day event covering [start] to [end] (inclusive days).
  factory CalendarEvent.allDay({
    required String id,
    required String title,
    required DateTime start,
    DateTime? end,
    String? description,
    String? location,
    int? color,
    RecurrenceRule? recurrence,
    T? data,
  }) =>
      CalendarEvent(
        id: id,
        title: title,
        start: start.dateOnly,
        end: (end ?? start).endOfDay,
        isAllDay: true,
        description: description,
        location: location,
        color: color,
        recurrence: recurrence,
        data: data,
      );

  /// Unique id (also used as the iCalendar UID).
  final String id;

  /// Title.
  final String title;

  /// Start of the first occurrence.
  final DateTime start;

  /// End of the first occurrence.
  final DateTime end;

  /// Whether the event spans whole days.
  final bool isAllDay;

  /// Optional notes.
  final String? description;

  /// Optional location.
  final String? location;

  /// ARGB colour such as `0xFF2196F3`; null uses the theme's event colour.
  final int? color;

  /// Repeat rule; null for one-off events.
  final RecurrenceRule? recurrence;

  /// Dates removed from the series (EXDATE).
  final List<DateTime> exceptionDates;

  /// Extra one-off dates added to the series (RDATE).
  final List<DateTime> additionalDates;

  /// IANA id of the zone [start]/[end] are written in (e.g.
  /// `Europe/Paris`); null means device local time.
  final String? timeZone;

  /// Which calendar (work, personal, holidays...) this event belongs to.
  final String? calendarId;

  /// Confirmed, tentative or cancelled.
  final EventStatus status;

  /// Who may see the details.
  final EventVisibility visibility;

  /// Whether the time counts as busy for free/busy lookups.
  final EventShowAs showAs;

  /// Normal event, out of office, focus time, working location, birthday,
  /// task or reminder.
  final EventType type;

  /// Who owns the event.
  final EventPerson? organizer;

  /// Invited people and their answers.
  final List<EventAttendee> attendees;

  /// Notifications before the event.
  final List<EventReminder> reminders;

  /// Related link.
  final String? url;

  /// Video meeting link.
  final String? meetingUrl;

  /// Your own payload.
  final T? data;

  /// [start] converted to the device's local time (uses [timeZone]).
  DateTime get localStart => _toLocal(start);

  /// [end] converted to the device's local time (uses [timeZone]).
  DateTime get localEnd => _toLocal(end);

  DateTime _toLocal(DateTime d) {
    final zone = timeZone == null ? null : ChronoTimeZone.tryGet(timeZone!);
    if (zone == null || d.isUtc) return d.toLocal();
    return zone.fromWall(d.year, d.month, d.day, d.hour, d.minute).utc.toLocal();
  }

  /// Every reminder's trigger time for the occurrence starting at
  /// [occurrenceStart] (the first one by default).
  List<DateTime> reminderTimes([DateTime? occurrenceStart]) => [
        for (final r in reminders) (occurrenceStart ?? start).subtract(r.before),
      ];

  /// Length of each occurrence.
  Duration get duration => end.difference(start);

  /// Whether this event repeats.
  bool get isRecurring => recurrence != null;

  /// Whether the first occurrence spans more than one calendar day.
  bool get isMultiDay => !start.isSameDay(end);

  /// Every occurrence that touches [range].
  Iterable<EventOccurrence<T>> occurrencesIn(DateRange range) sync* {
    final from = range.start;
    final to = range.end.endOfDay;
    final rule = recurrence;
    if (status == EventStatus.cancelled) return;
    if (rule == null) {
      if (!end.isBefore(from) && !start.isAfter(to)) {
        yield EventOccurrence(this, start, end);
      }
      for (final extra in additionalDates) {
        final e = extra.add(duration);
        if (!e.isBefore(from) && !extra.isAfter(to)) yield EventOccurrence(this, extra, e);
      }
      return;
    }
    final len = duration;
    for (final extra in additionalDates) {
      final e = extra.add(len);
      if (!e.isBefore(from) && !extra.isAfter(to)) yield EventOccurrence(this, extra, e);
    }
    // Start a little early so occurrences that began before the range but
    // are still running are included.
    final lookBack = from.subtract(len);
    for (final s in rule.occurrences(start, exclude: exceptionDates)) {
      if (s.isAfter(to)) break;
      if (s.isBefore(lookBack)) continue;
      final e = s.add(len);
      if (!e.isBefore(from)) yield EventOccurrence(this, s, e);
    }
  }

  /// Copy with some fields replaced.
  CalendarEvent<T> copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    String? description,
    String? location,
    int? color,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    List<DateTime>? exceptionDates,
    List<DateTime>? additionalDates,
    String? timeZone,
    String? calendarId,
    EventStatus? status,
    EventVisibility? visibility,
    EventShowAs? showAs,
    EventType? type,
    EventPerson? organizer,
    List<EventAttendee>? attendees,
    List<EventReminder>? reminders,
    String? url,
    String? meetingUrl,
    T? data,
  }) =>
      CalendarEvent<T>(
        id: id ?? this.id,
        title: title ?? this.title,
        start: start ?? this.start,
        end: end ?? this.end,
        isAllDay: isAllDay ?? this.isAllDay,
        description: description ?? this.description,
        location: location ?? this.location,
        color: color ?? this.color,
        recurrence: clearRecurrence ? null : recurrence ?? this.recurrence,
        exceptionDates: exceptionDates ?? this.exceptionDates,
        additionalDates: additionalDates ?? this.additionalDates,
        timeZone: timeZone ?? this.timeZone,
        calendarId: calendarId ?? this.calendarId,
        status: status ?? this.status,
        visibility: visibility ?? this.visibility,
        showAs: showAs ?? this.showAs,
        type: type ?? this.type,
        organizer: organizer ?? this.organizer,
        attendees: attendees ?? this.attendees,
        reminders: reminders ?? this.reminders,
        url: url ?? this.url,
        meetingUrl: meetingUrl ?? this.meetingUrl,
        data: data ?? this.data,
      );

  @override
  String toString() => 'CalendarEvent($id, $title, $start – $end)';
}

/// One concrete occurrence of a (possibly repeating) [CalendarEvent].
class EventOccurrence<T> {
  /// Creates an occurrence.
  const EventOccurrence(this.event, this.start, this.end);

  /// The event this occurrence belongs to.
  final CalendarEvent<T> event;

  /// Start of this occurrence.
  final DateTime start;

  /// End of this occurrence.
  final DateTime end;

  /// Whether this occurrence touches [day].
  bool coversDay(DateTime day) =>
      !end.isBefore(day.dateOnly) &&
      !start.isAfter(day.endOfDay) &&
      // An event ending exactly at midnight does not cover the next day.
      !(end == day.dateOnly && start.isBefore(end));

  /// Whether this occurrence overlaps [other] in time.
  bool overlaps(EventOccurrence<Object?> other) => start.isBefore(other.end) && other.start.isBefore(end);

  @override
  bool operator ==(Object other) => other is EventOccurrence && identical(other.event, event) && other.start == start;

  @override
  int get hashCode => Object.hash(event.id, start);
}

/// Queries over a list of events.
extension CalendarEventList<T> on Iterable<CalendarEvent<T>> {
  /// All occurrences touching [range], sorted by start time.
  List<EventOccurrence<T>> occurrencesIn(DateRange range) =>
      [for (final e in this) ...e.occurrencesIn(range)]..sort((a, b) => a.start.compareTo(b.start));

  /// Occurrences on [day], all-day events first.
  List<EventOccurrence<T>> on(DateTime day) => occurrencesIn(DateRange.day(day)).where((o) => o.coversDay(day)).toList()
    ..sort((a, b) {
      if (a.event.isAllDay != b.event.isAllDay) return a.event.isAllDay ? -1 : 1;
      return a.start.compareTo(b.start);
    });

  /// Occurrences grouped by day for [range] (keys are midnight dates).
  /// Built in one pass, so it is cheap to call once per visible page and
  /// then look up days in O(1).
  Map<DateTime, List<EventOccurrence<T>>> groupByDay(DateRange range) {
    final out = <DateTime, List<EventOccurrence<T>>>{};
    for (final o in occurrencesIn(range)) {
      final first = maxDate(o.start.dateOnly, range.start);
      final last = minDate(o.end.dateOnly, range.end);
      for (var d = first; !d.isAfter(last); d = d.addDays(1)) {
        if (o.coversDay(d)) (out[DateTime(d.year, d.month, d.day)] ??= []).add(o);
      }
    }
    for (final list in out.values) {
      list.sort((a, b) {
        if (a.event.isAllDay != b.event.isAllDay) return a.event.isAllDay ? -1 : 1;
        return a.start.compareTo(b.start);
      });
    }
    return out;
  }
}

/// Free/busy and overlap helpers.
abstract final class Schedule {
  /// Places overlapping timed occurrences side by side: returns, for each
  /// occurrence, its column and the number of columns in its cluster.
  static Map<EventOccurrence<T>, ({int column, int columns})> layoutColumns<T>(List<EventOccurrence<T>> items) {
    final sorted = [...items]..sort((a, b) {
        final c = a.start.compareTo(b.start);
        return c != 0 ? c : b.end.compareTo(a.end);
      });
    final result = <EventOccurrence<T>, ({int column, int columns})>{};
    var cluster = <EventOccurrence<T>>[];
    var columnEnds = <DateTime>[];
    final columnOf = <EventOccurrence<T>, int>{};
    DateTime? clusterEnd;

    void flush() {
      for (final o in cluster) {
        result[o] = (column: columnOf[o]!, columns: columnEnds.length);
      }
      cluster = [];
      columnEnds = [];
    }

    for (final o in sorted) {
      if (clusterEnd != null && !o.start.isBefore(clusterEnd)) {
        flush();
        clusterEnd = null;
      }
      var col = columnEnds.indexWhere((e) => !e.isAfter(o.start));
      if (col < 0) {
        col = columnEnds.length;
        columnEnds.add(o.end);
      } else {
        columnEnds[col] = o.end;
      }
      columnOf[o] = col;
      cluster.add(o);
      clusterEnd = clusterEnd == null ? o.end : maxDate(clusterEnd, o.end);
    }
    flush();
    return result;
  }

  /// Free slots of at least [minLength] between [from] and [to], given
  /// busy [occurrences]. Useful for booking and meeting finders.
  static List<DateRangeTime> freeSlots(
    Iterable<EventOccurrence<Object?>> occurrences, {
    required DateTime from,
    required DateTime to,
    Duration minLength = const Duration(minutes: 15),
  }) {
    final busy = occurrences
        .where((o) => o.event.showAs == EventShowAs.busy && o.end.isAfter(from) && o.start.isBefore(to))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final out = <DateRangeTime>[];
    var cursor = from;
    for (final o in busy) {
      if (o.start.difference(cursor) >= minLength) {
        out.add(DateRangeTime(cursor, o.start));
      }
      if (o.end.isAfter(cursor)) cursor = o.end;
    }
    if (to.difference(cursor) >= minLength) out.add(DateRangeTime(cursor, to));
    return out;
  }

  /// Splits [from]..[to] into back-to-back slots of [length] (e.g. 30-minute
  /// appointment slots), skipping any that overlap [busy].
  static List<DateRangeTime> slots({
    required DateTime from,
    required DateTime to,
    required Duration length,
    Duration gap = Duration.zero,
    Iterable<EventOccurrence<Object?>> busy = const [],
  }) {
    final out = <DateRangeTime>[];
    for (var s = from; !s.add(length).isAfter(to); s = s.add(length + gap)) {
      final e = s.add(length);
      if (!busy.any((o) => o.start.isBefore(e) && s.isBefore(o.end))) {
        out.add(DateRangeTime(s, e));
      }
    }
    return out;
  }
}

/// A time span with exact start and end instants (unlike [DateRange],
/// which is whole days).
class DateRangeTime {
  /// Creates a span.
  const DateRangeTime(this.start, this.end);

  /// Start instant.
  final DateTime start;

  /// End instant (exclusive).
  final DateTime end;

  /// Length.
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) => other is DateRangeTime && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRangeTime($start – $end)';
}

/// Event status.
enum EventStatus {
  /// Happening.
  confirmed,

  /// Not yet certain.
  tentative,

  /// Cancelled (hidden from views and free/busy).
  cancelled,
}

/// Who can see the event details.
enum EventVisibility {
  /// The calendar's default.
  normal,

  /// Everyone.
  public,

  /// Only the owner; others just see "busy".
  private,
}

/// Whether the event blocks time.
enum EventShowAs {
  /// Blocks time in free/busy.
  busy,

  /// Does not block time.
  free,
}

/// Kind of event.
enum EventType {
  /// A regular event.
  normal,

  /// Away; may auto-decline invitations.
  outOfOffice,

  /// Do-not-disturb work block.
  focusTime,

  /// Where someone works that day (home, office...).
  workingLocation,

  /// A birthday or anniversary.
  birthday,

  /// A to-do with a due date.
  task,

  /// A simple reminder.
  reminder,
}

/// An attendee's answer.
enum AttendeeResponse {
  /// Not answered yet.
  needsAction,

  /// Going.
  accepted,

  /// Not going.
  declined,

  /// Maybe.
  tentative,
}

/// A person attached to an event.
class EventPerson {
  /// Creates a person.
  const EventPerson({required this.email, this.name});

  /// Email address.
  final String email;

  /// Display name.
  final String? name;

  @override
  bool operator ==(Object other) => other is EventPerson && other.email == email && other.name == name;

  @override
  int get hashCode => Object.hash(email, name);
}

/// An invited person.
class EventAttendee extends EventPerson {
  /// Creates an attendee.
  const EventAttendee({
    required super.email,
    super.name,
    this.response = AttendeeResponse.needsAction,
    this.optional = false,
    this.isResource = false,
  });

  /// Their answer.
  final AttendeeResponse response;

  /// Optional attendee.
  final bool optional;

  /// A room or piece of equipment rather than a person.
  final bool isResource;

  /// Copy with a new [response].
  EventAttendee withResponse(AttendeeResponse response) =>
      EventAttendee(email: email, name: name, response: response, optional: optional, isResource: isResource);
}

/// How a reminder is delivered.
enum ReminderMethod {
  /// In-app or push notification.
  notification,

  /// Email.
  email,
}

/// A reminder some time before an event.
class EventReminder {
  /// Creates a reminder.
  const EventReminder(Duration before, {this.method = ReminderMethod.notification})
      : _before = before,
        _minutes = 0;

  /// Minutes-before shortcut.
  const EventReminder.minutes(int minutes, {this.method = ReminderMethod.notification})
      : _before = null,
        _minutes = minutes;

  final Duration? _before;
  final int _minutes;

  /// How long before the start.
  Duration get before => _before ?? Duration(minutes: _minutes);

  /// Delivery method.
  final ReminderMethod method;

  @override
  bool operator ==(Object other) => other is EventReminder && other.before == before && other.method == method;

  @override
  int get hashCode => Object.hash(before, method);
}

/// One calendar in a multi-calendar app (Work, Personal, Holidays...).
class CalendarSource {
  /// Creates a calendar source.
  const CalendarSource({
    required this.id,
    required this.name,
    this.color,
    this.isVisible = true,
    this.isReadOnly = false,
    this.timeZone,
    this.description,
  });

  /// Id referenced by [CalendarEvent.calendarId].
  final String id;

  /// Display name.
  final String name;

  /// ARGB colour for its events.
  final int? color;

  /// Whether its events are shown.
  final bool isVisible;

  /// Whether its events can be edited.
  final bool isReadOnly;

  /// Default time zone.
  final String? timeZone;

  /// Notes.
  final String? description;

  /// Copy with some fields replaced.
  CalendarSource copyWith({String? name, int? color, bool? isVisible, bool? isReadOnly, String? timeZone}) =>
      CalendarSource(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        isVisible: isVisible ?? this.isVisible,
        isReadOnly: isReadOnly ?? this.isReadOnly,
        timeZone: timeZone ?? this.timeZone,
        description: description,
      );
}

/// Multi-calendar helpers.
extension CalendarEventFiltering<T> on Iterable<CalendarEvent<T>> {
  /// Only events whose calendar is visible in [sources] (events without a
  /// calendar are kept).
  Iterable<CalendarEvent<T>> visibleIn(Iterable<CalendarSource> sources) {
    final hidden = {
      for (final s in sources)
        if (!s.isVisible) s.id
    };
    return where((e) => e.calendarId == null || !hidden.contains(e.calendarId));
  }

  /// Events where [email] is the organizer or an attendee.
  Iterable<CalendarEvent<T>> involving(String email) =>
      where((e) => e.organizer?.email == email || e.attendees.any((a) => a.email == email));

  /// Simple text search in title, description and location.
  Iterable<CalendarEvent<T>> search(String query) {
    final q = query.toLowerCase();
    return where((e) =>
        e.title.toLowerCase().contains(q) ||
        (e.description?.toLowerCase().contains(q) ?? false) ||
        (e.location?.toLowerCase().contains(q) ?? false));
  }
}
