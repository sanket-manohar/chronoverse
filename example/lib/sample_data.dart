import 'package:chronoverse/chronoverse.dart';

/// Demo events relative to [today].
List<CalendarEvent<Object?>> sampleEvents(DateTime today) {
  final d = today.dateOnly;
  final monday = d.startOfWeek();
  return [
    CalendarEvent(
      id: 'standup',
      title: 'Team stand-up',
      start: monday.atTime(9, 30),
      end: monday.atTime(9, 45),
      color: 0xFF3B82F6,
      recurrence: RecurrenceRule.weekdays,
      reminders: const [EventReminder.minutes(5)],
    ),
    CalendarEvent(
      id: 'design',
      title: 'Design review',
      location: 'Room 4B',
      start: monday.addDays(1).atTime(11),
      end: monday.addDays(1).atTime(12, 30),
      color: 0xFF8B5CF6,
      attendees: const [EventAttendee(email: 'sam@example.com', name: 'Sam', response: AttendeeResponse.accepted)],
    ),
    CalendarEvent(
      id: 'lunch',
      title: 'Lunch with Priya',
      start: monday.addDays(1).atTime(12),
      end: monday.addDays(1).atTime(13),
      color: 0xFF10B981,
    ),
    CalendarEvent(
      id: 'focus',
      title: 'Focus time',
      type: EventType.focusTime,
      start: monday.addDays(2).atTime(14),
      end: monday.addDays(2).atTime(16),
      color: 0xFFF59E0B,
    ),
    CalendarEvent(
      id: 'gym',
      title: 'Gym',
      start: monday.atTime(18),
      end: monday.atTime(19),
      color: 0xFFEF4444,
      recurrence: const RecurrenceRule(
        frequency: Frequency.weekly,
        byWeekdays: [ByWeekday(DateTime.monday), ByWeekday(DateTime.thursday)],
      ),
    ),
    CalendarEvent(
      id: 'call',
      title: 'Client call',
      status: EventStatus.tentative,
      start: monday.addDays(3).atTime(10),
      end: monday.addDays(3).atTime(11),
      color: 0xFF06B6D4,
    ),
    CalendarEvent.allDay(
      id: 'trip',
      title: 'Conference trip',
      start: monday.addDays(4),
      end: monday.addDays(6),
      color: 0xFFEC4899,
    ),
    CalendarEvent.allDay(
      id: 'bday',
      title: "Mom's birthday",
      start: d.addDays(9),
      color: 0xFFF97316,
      recurrence: RecurrenceRule.yearly,
    ),
    CalendarEvent(
      id: 'payday',
      title: 'Payday',
      start: d.startOfMonth.atTime(9),
      end: d.startOfMonth.atTime(9, 30),
      color: 0xFF22C55E,
      recurrence: RecurrenceRule.parse('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1'),
    ),
  ];
}

/// Demo heatmap values.
Map<DateTime, num> sampleActivity(DateTime today) {
  final out = <DateTime, num>{};
  var seed = 7;
  for (var i = 0; i < 365; i++) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    final v = seed % 9 - 2;
    if (v > 0) out[today.addDays(-i)] = v;
  }
  return out;
}
