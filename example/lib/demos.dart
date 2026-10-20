import 'package:chronoverse/chronoverse.dart';
import 'package:flutter/material.dart';

import 'sample_data.dart';

/// Month calendar that collapses to a week and expands back.
class MonthDemo extends StatefulWidget {
  const MonthDemo({super.key});

  @override
  State<MonthDemo> createState() => _MonthDemoState();
}

class _MonthDemoState extends State<MonthDemo> {
  final _controller = ChronoCalendarController(selectedDay: DateTime.now());
  late final _events = sampleEvents(DateTime.now());

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = _controller.selectedDay ?? DateTime.now();
    final items = _events.on(day);
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: ChronoCalendar(
            controller: _controller,
            events: _events,
            expandable: true,
            showWeekNumbers: false,
            holidayPredicate: (d) => d.month == 12 && d.day == 25,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text(Chrono.format(day, 'EEEE, d MMMM'), style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _controller.showWeekOf(DateTime.now()),
              icon: const Icon(Icons.today),
              label: const Text('This week'),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (items.isEmpty) const ListTile(title: Text('Nothing planned')),
              for (final o in items)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Color(o.event.color ?? 0xFF888888), radius: 6),
                    title: Text(o.event.title),
                    subtitle: Text(o.event.isAllDay
                        ? 'All day'
                        : '${Chrono.format(o.start, 'h:mm a')} – ${Chrono.format(o.end, 'h:mm a')}'),
                    trailing: o.event.isRecurring
                        ? Tooltip(message: o.event.recurrence!.describe(), child: const Icon(Icons.repeat, size: 18))
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hotel-style range booking with prices under each day.
class BookingDemo extends StatefulWidget {
  const BookingDemo({super.key});

  @override
  State<BookingDemo> createState() => _BookingDemoState();
}

class _BookingDemoState extends State<BookingDemo> {
  DateRange? _range;
  final _today = DateTime.now().dateOnly;

  int _price(DateTime d) => d.isWeekend() ? 149 : 99 + (d.day % 4) * 10;

  @override
  Widget build(BuildContext context) {
    final booked = DateRange(_today.addDays(5), _today.addDays(7));
    final availability = DateAvailability(disabledRanges: [booked], disablePast: true);
    final nights = _range == null ? 0 : _range!.lengthInDays - 1;
    final total = _range == null ? 0 : _range!.days.take(nights).fold<int>(0, (s, d) => s + _price(d));
    return Column(
      children: [
        Expanded(
          child: ChronoVerticalCalendar(
            mode: ChronoSelectionMode.range,
            availability: availability,
            lastDay: _today.addMonths(6),
            onRangeSelected: (r) => setState(() => _range = r),
            dayLabelBuilder: (context, d) =>
                availability.isAvailable(d) && !d.isBefore(_today) ? Text('\$${_price(d)}') : null,
          ),
        ),
        Material(
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _range == null
                        ? 'Select check-in and check-out'
                        : '${Chrono.format(_range!.start, 'd MMM')} → ${Chrono.format(_range!.end, 'd MMM')} · $nights nights · \$$total',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilledButton(onPressed: nights > 0 ? () {} : null, child: const Text('Reserve')),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Every picker style.
class PickersDemo extends StatefulWidget {
  const PickersDemo({super.key});

  @override
  State<PickersDemo> createState() => _PickersDemoState();
}

class _PickersDemoState extends State<PickersDemo> {
  String _result = 'Pick something';
  DateTime _wheel = DateTime(1995, 3, 10);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Type or pick', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ChronoDateField(
          decoration: const InputDecoration(
            labelText: 'Due date',
            helperText: 'Try "next friday", "in 3 days" or "25 dec"',
            border: OutlineInputBorder(),
          ),
          onChanged: (d) =>
              setState(() => _result = d == null ? 'Cleared' : 'Field: ${Chrono.format(d, 'EEE, d MMM yyyy')}'),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonal(
            onPressed: () async {
              final d = await showChronoDatePicker(context: context);
              if (d != null) setState(() => _result = 'Date: ${Chrono.format(d, 'd MMM yyyy')}');
            },
            child: const Text('Date dialog'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final r = await showChronoRangePicker(
                context: context,
                presets: ChronoRangePreset.common,
                maxDays: 30,
                presentation: ChronoPresentation.bottomSheet,
              );
              if (r != null) setState(() => _result = 'Range: ${r.lengthInDays} days');
            },
            child: const Text('Range sheet'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final s = await showChronoMultiDatePicker(context: context);
              if (s != null) setState(() => _result = '${s.length} days picked');
            },
            child: const Text('Multi select'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final d = await showChronoWheelPicker(context: context, initialDate: _wheel);
              if (d != null) setState(() => _result = 'Age ${Chrono.age(d)} · ${Chrono.zodiacSign(d)}');
            },
            child: const Text('Wheel sheet'),
          ),
        ]),
        const SizedBox(height: 12),
        Text(_result, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text('Birthday wheels (leap-year aware)', style: Theme.of(context).textTheme.titleMedium),
        ChronoDateWheelPicker(
          initialDate: _wheel,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _wheel = d),
        ),
        Text('Age ${Chrono.age(_wheel)} · next birthday ${Chrono.timeAgo(Chrono.nextAnniversary(_wheel))}'),
        const SizedBox(height: 24),
        Text('Quick month & year', style: Theme.of(context).textTheme.titleMedium),
        ChronoMonthPicker(
          year: DateTime.now().year,
          selectedMonth: DateTime.now(),
          onMonthSelected: (m) => setState(() => _result = 'Month: ${Chrono.format(m, 'MMMM yyyy')}'),
          onYearChanged: (_) {},
        ),
      ],
    );
  }
}

/// Week schedule with drag & resize.
class ScheduleDemo extends StatefulWidget {
  const ScheduleDemo({super.key, this.days = 5});

  final int days;

  @override
  State<ScheduleDemo> createState() => _ScheduleDemoState();
}

class _ScheduleDemoState extends State<ScheduleDemo> {
  late List<CalendarEvent<Object?>> _events = sampleEvents(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final monday = DateTime.now().startOfWeek();
    return ChronoScheduleView(
      date: monday,
      numberOfDays: widget.days,
      events: _events,
      startHour: 7,
      endHour: 21,
      hourHeight: 56,
      initialScrollHour: 8,
      workHours: (9, 18),
      blockedSlots: [
        for (var i = 0; i < widget.days; i++)
          DateRangeTime(monday.addDays(i).atTime(13), monday.addDays(i).atTime(13, 30)),
      ],
      onEventMoved: (o, start, end) => setState(() {
        _events = [
          for (final e in _events)
            if (e.id == o.event.id && !e.isRecurring) e.copyWith(start: start, end: end) else e,
        ];
      }),
      onSlotTap: (t) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('New event at ${Chrono.format(t, 'EEE h:mm a')}'))),
    );
  }
}

/// Agenda list.
class AgendaDemo extends StatelessWidget {
  const AgendaDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().dateOnly;
    return ChronoAgendaView(
      events: sampleEvents(today),
      range: DateRange(today.startOfWeek(), today.addDays(14)),
    );
  }
}

/// Year overview and activity heatmap.
class YearDemo extends StatelessWidget {
  const YearDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final events = sampleEvents(today);
    final index = events.groupByDay(DateRange.year(today));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ChronoHeatmap(values: sampleActivity(today), cellSize: 11, cellSpacing: 2.5),
        ),
        Expanded(
          child: ChronoYearView(
            year: today.year,
            selectedDate: today,
            eventLoader: (d) => index[d] ?? const [],
          ),
        ),
      ],
    );
  }
}

/// Horizontal day strip.
class StripDemo extends StatefulWidget {
  const StripDemo({super.key});

  @override
  State<StripDemo> createState() => _StripDemoState();
}

class _StripDemoState extends State<StripDemo> {
  DateTime _day = DateTime.now();
  final _events = sampleEvents(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final slots = Schedule.slots(
      from: _day.dateOnly.atTime(9),
      to: _day.dateOnly.atTime(17),
      length: const Duration(minutes: 45),
      gap: const Duration(minutes: 15),
      busy: _events.on(_day),
    );
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        ChronoWeekStrip(
          selectedDate: _day,
          availability: const DateAvailability(disabledWeekdays: {DateTime.sunday}),
          eventLoader: (d) => _events.on(d),
          onDateSelected: (d) => setState(() => _day = d),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text('Free appointment slots', style: Theme.of(context).textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in slots)
              ChoiceChip(label: Text(Chrono.format(s.start, 'h:mm a')), selected: false, onSelected: (_) {}),
          ]),
        ),
      ],
    );
  }
}

/// Live theme, shape and language switcher.
class ThemingDemo extends StatefulWidget {
  const ThemingDemo({super.key});

  @override
  State<ThemingDemo> createState() => _ThemingDemoState();
}

class _ThemingDemoState extends State<ThemingDemo> {
  Color _seed = const Color(0xFF7C3AED);
  ChronoDayShape _shape = ChronoDayShape.rounded;
  String _lang = 'en';
  bool _native = false;
  bool _frozen = false;

  @override
  Widget build(BuildContext context) {
    final locale = ChronoLocale.of(_lang);
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Theme.of(context).brightness);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(spacing: 8, children: [
          for (final c in const [
            Color(0xFF7C3AED),
            Color(0xFF0EA5E9),
            Color(0xFF10B981),
            Color(0xFFF43F5E),
            Color(0xFFF59E0B)
          ])
            GestureDetector(
              onTap: () => setState(() => _seed = c),
              child: CircleAvatar(
                backgroundColor: c,
                radius: 14,
                child: _seed == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
            ),
        ]),
        const SizedBox(height: 8),
        SegmentedButton<ChronoDayShape>(
          segments: const [
            ButtonSegment(value: ChronoDayShape.circle, label: Text('Circle')),
            ButtonSegment(value: ChronoDayShape.rounded, label: Text('Rounded')),
            ButtonSegment(value: ChronoDayShape.square, label: Text('Square')),
          ],
          selected: {_shape},
          onSelectionChanged: (s) => setState(() => _shape = s.first),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final code in ChronoLocale.supportedCodes)
            ChoiceChip(label: Text(code), selected: _lang == code, onSelected: (_) => setState(() => _lang = code)),
        ]),
        SwitchListTile(
          title: const Text('Native digits'),
          value: _native,
          onChanged: (v) => setState(() => _native = v),
        ),
        SwitchListTile(
          title: const Text('Freeze calendar'),
          value: _frozen,
          onChanged: (v) => setState(() => _frozen = v),
        ),
        Directionality(
          textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Card(
            child: ChronoCalendar(
              mode: ChronoSelectionMode.range,
              locale: locale,
              nativeDigits: _native,
              enabled: !_frozen,
              showWeekNumbers: true,
              formatToggle: true,
              theme: ChronoThemeData(
                dayShape: _shape,
                primaryColor: scheme.primary,
                onPrimaryColor: scheme.onPrimary,
                todayColor: scheme.primary,
                rangeColor: scheme.primaryContainer,
                eventColor: scheme.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The function toolbox in action.
class ToolboxDemo extends StatelessWidget {
  const ToolboxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final india = ChronoTimeZone.get('Asia/Kolkata');
    final rows = <(String, String)>[
      ('Chrono.format(now, "EEEE, do MMMM yyyy")', Chrono.format(now, 'EEEE, do MMMM yyyy')),
      (
        'Chrono.format(now, "EEEE d MMMM yyyy", locale: "fr")',
        Chrono.format(now, 'EEEE d MMMM yyyy', locale: 'fr'),
      ),
      ('Chrono.parseNatural("next friday")', Chrono.format(Chrono.parseNatural('next friday')!, 'EEE d MMM')),
      ('Chrono.isLeapYear(2028)', '${Chrono.isLeapYear(2028)}'),
      ('Chrono.weekNumber(now)', '${Chrono.weekNumber(now)}'),
      ('Chrono.difference(DateTime(2000, 2, 29), now)', '${Chrono.difference(DateTime(2000, 2, 29), now)}'),
      ('Chrono.addBusinessDays(now, 10)', Chrono.format(Chrono.addBusinessDays(now, 10), 'EEE d MMM')),
      ('Chrono.toHijri(now)', '${Chrono.toHijri(now)}'),
      ('Chrono.toPersian(now)', '${Chrono.toPersian(now)}'),
      ('Chrono.toIndianNational(now)', '${Chrono.toIndianNational(now)}'),
      ('Chrono.toSpreadsheetSerial(now)', Chrono.toSpreadsheetSerial(now).toStringAsFixed(4)),
      (
        'Chrono.timeAgo(now - 3 days, locale: "es")',
        Chrono.timeAgo(now.subtract(const Duration(days: 3)), locale: 'es')
      ),
      ('India 19:30 → New York', india.convert(now.atTime(19, 30), ChronoTimeZone.get('America/New_York')).toString()),
      (
        'RecurrenceRule.parse("FREQ=MONTHLY;BYDAY=-1FR").describe()',
        RecurrenceRule.parse('FREQ=MONTHLY;BYDAY=-1FR').describe()
      ),
      ('Chrono.moonPhaseName(now)', Chrono.moonPhaseName(now)),
      ('Chrono.easter(${now.year})', Chrono.format(Chrono.easter(now.year), 'd MMMM')),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (context, i) => const Divider(height: 1),
      itemBuilder: (context, i) => ListTile(
        dense: true,
        title: Text(rows[i].$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        subtitle: Text(rows[i].$2, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

/// Planner month with coloured cards and drag & drop from a notes tray.
class PlannerDemo extends StatefulWidget {
  const PlannerDemo({super.key});

  @override
  State<PlannerDemo> createState() => _PlannerDemoState();
}

class _PlannerDemoState extends State<PlannerDemo> {
  late List<CalendarEvent<Object?>> _events = sampleEvents(DateTime.now());
  ChronoChipShape _shape = ChronoChipShape.rounded;
  final _notes = const [
    ('Pay rent', 0xFFEF4444),
    ('Dentist', 0xFF06B6D4),
    ('Book flights', 0xFF8B5CF6),
    ('Call bank', 0xFFF59E0B),
  ];
  var _counter = 0;

  void _drop(DateTime day, Object data) {
    setState(() {
      if (data is EventOccurrence) {
        // Move the dragged event (whole series for repeating ones) by the
        // number of days it travelled.
        final shift = data.start.daysUntil(day);
        _events = [
          for (final e in _events)
            if (e.id == data.event.id) e.copyWith(start: e.start.addDays(shift), end: e.end.addDays(shift)) else e,
        ];
      } else if (data is (String, int)) {
        _events = [
          ..._events,
          CalendarEvent.allDay(id: 'note-${_counter++}', title: data.$1, start: day, color: data.$2),
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        SegmentedButton<ChronoChipShape>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ChronoChipShape.rounded, label: Text('Rounded')),
            ButtonSegment(value: ChronoChipShape.pill, label: Text('Pill')),
            ButtonSegment(value: ChronoChipShape.accentBar, label: Text('Accent')),
            ButtonSegment(value: ChronoChipShape.outlined, label: Text('Outline')),
          ],
          selected: {_shape},
          onSelectionChanged: (s) => setState(() => _shape = s.first),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ChronoCalendar(
            events: _events,
            markerStyle: ChronoMarkerStyle.chips,
            chipStyle: ChronoChipStyle(shape: _shape),
            mode: ChronoSelectionMode.none,
            theme: const ChronoThemeData(cellHeight: 92, dayShape: ChronoDayShape.square, cellPadding: 0),
            onDrop: _drop,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child:
              Text('Long-press a note or a card and drop it on a day', style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final n in _notes)
            ChronoDragItem<(String, int)>(
              data: n,
              child: Chip(
                avatar: CircleAvatar(backgroundColor: Color(n.$2), radius: 6),
                label: Text(n.$1),
              ),
            ),
        ]),
      ],
    );
  }
}
