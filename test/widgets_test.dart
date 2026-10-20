import 'package:chronoverse/chronoverse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {Size? size}) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  final today = DateTime.now().dateOnly;

  group('ChronoCalendar', () {
    testWidgets('selects a day and reports it', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(app(ChronoCalendar(
        initialDate: DateTime(2026, 10, 1),
        onDaySelected: (d) => picked = d,
      )));
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(picked, DateTime(2026, 10, 15));
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('range mode returns a range after two taps', (tester) async {
      DateRange? range;
      await tester.pumpWidget(app(ChronoCalendar(
        initialDate: DateTime(2026, 10, 1),
        mode: ChronoSelectionMode.range,
        onRangeSelected: (r) => range = r,
      )));
      await tester.tap(find.text('20'));
      await tester.pump();
      expect(range, isNull);
      await tester.tap(find.text('12'));
      await tester.pump();
      expect(range, DateRange(DateTime(2026, 10, 12), DateTime(2026, 10, 20)));
    });

    testWidgets('swipes and arrows change the month', (tester) async {
      final c = ChronoCalendarController(focusedDay: DateTime(2026, 10, 1));
      await tester.pumpWidget(app(ChronoCalendar(controller: c)));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      expect(c.focusedDay.month, 10);
    });

    testWidgets('collapses to a programmatic week and expands', (tester) async {
      final c = ChronoCalendarController(focusedDay: DateTime(2026, 10, 1));
      await tester.pumpWidget(app(ChronoCalendar(controller: c, expandable: true)));
      c.showWeekOf(DateTime(2026, 10, 21));
      await tester.pumpAndSettle();
      expect(c.format, ChronoCalendarFormat.week);
      expect(find.text('21'), findsOneWidget);
      expect(find.text('5'), findsNothing);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      expect(c.format, ChronoCalendarFormat.month);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('frozen and blocked days cannot be selected', (tester) async {
      DateTime? picked;
      final c = ChronoCalendarController(focusedDay: DateTime(2026, 10, 1));
      await tester.pumpWidget(app(ChronoCalendar(
        controller: c,
        availability: DateAvailability(disabledDates: [DateTime(2026, 10, 14)]),
        onDaySelected: (d) => picked = d,
      )));
      await tester.tap(find.text('14'));
      await tester.pump();
      expect(picked, isNull);
      c.freeze();
      await tester.pump();
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(picked, isNull);
      c.unfreeze();
      await tester.pump();
      await tester.tap(find.text('15'));
      expect(picked, DateTime(2026, 10, 15));
    });

    testWidgets('quick pickers jump to a year and month', (tester) async {
      final c = ChronoCalendarController(focusedDay: DateTime(2026, 10, 1));
      await tester.pumpWidget(app(ChronoCalendar(controller: c)));
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2027'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();
      expect(c.focusedDay, DateTime(2027, 3, 1));
      expect(find.text('March 2027'), findsOneWidget);
    });

    testWidgets('drops data on a day', (tester) async {
      Object? dropped;
      DateTime? on;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            ChronoCalendar(
              initialDate: DateTime(2026, 10, 1),
              onDrop: (d, data) {
                on = d;
                dropped = data;
              },
            ),
            const ChronoDragItem<String>(data: 'note', longPress: false, child: Text('drag me')),
          ]),
        ),
      ));
      final from = tester.getCenter(find.text('drag me'));
      final to = tester.getCenter(find.text('16'));
      final g = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(dropped, 'note');
      expect(on, DateTime(2026, 10, 16));
    });

    testWidgets('renders in every locale and RTL without errors', (tester) async {
      for (final l in ChronoLocale.builtInLocales) {
        await tester.pumpWidget(app(Directionality(
          textDirection: l.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ChronoCalendar(locale: l, nativeDigits: true, showWeekNumbers: true),
        )));
        expect(tester.takeException(), isNull, reason: l.code);
      }
    });

    testWidgets('chips mode shows event titles', (tester) async {
      await tester.pumpWidget(app(ChronoCalendar(
        initialDate: today,
        markerStyle: ChronoMarkerStyle.chips,
        theme: const ChronoThemeData(cellHeight: 92),
        events: [CalendarEvent.allDay(id: '1', title: 'Launch', start: today)],
      )));
      expect(find.text('Launch'), findsOneWidget);
    });
  });

  group('other widgets', () {
    testWidgets('date field parses typing and natural language', (tester) async {
      DateTime? value;
      await tester.pumpWidget(app(ChronoDateField(pattern: 'dd/MM/yyyy', onChanged: (d) => value = d)));
      await tester.enterText(find.byType(TextField), '25/12/2026');
      expect(value, DateTime(2026, 12, 25));
      await tester.enterText(find.byType(TextField), 'tomorrow');
      expect(value, today.addDays(1));
      await tester.enterText(find.byType(TextField), '31/02/2026');
      await tester.pump();
      expect(find.text('Invalid date'), findsOneWidget);
    });

    testWidgets('date dialog returns the picked date', (tester) async {
      DateTime? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showChronoDatePicker(context: context, initialDate: DateTime(2026, 10, 1)),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 10, 9));
    });

    testWidgets('schedule lays out events and reports slot taps', (tester) async {
      DateTime? slot;
      final day = DateTime(2026, 10, 20);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChronoScheduleView(
            date: day,
            initialScrollHour: 8,
            events: [
              CalendarEvent(id: 'a', title: 'Alpha', start: day.atTime(9), end: day.atTime(10)),
              CalendarEvent(id: 'b', title: 'Beta', start: day.atTime(9, 30), end: day.atTime(11)),
            ],
            onSlotTap: (t) => slot = t,
          ),
        ),
      ));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Beta')).dx, greaterThan(tester.getTopLeft(find.text('Alpha')).dx));
      await tester.tapAt(tester.getCenter(find.text('Alpha')) + const Offset(0, 200));
      expect(slot, isNotNull);
    });

    testWidgets('wheel picker clamps Feb 29 in non-leap years', (tester) async {
      DateTime? value;
      await tester.pumpWidget(app(ChronoDateWheelPicker(
        initialDate: DateTime(2024, 2, 29),
        order: ChronoWheelOrder.dmy,
        onChanged: (d) => value = d,
      )));
      await tester.drag(find.text('2024'), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(value, DateTime(2025, 2, 28));
    });

    testWidgets('strip, vertical, year, heatmap and agenda render', (tester) async {
      final events = [CalendarEvent<Object?>.allDay(id: '1', title: 'Hello', start: today)];
      for (final w in <Widget>[
        ChronoWeekStrip(onDateSelected: (_) {}),
        SizedBox(height: 600, child: ChronoVerticalCalendar(lastDay: today.addMonths(2))),
        SizedBox(height: 900, child: ChronoYearView(year: today.year)),
        ChronoHeatmap(values: {today: 3}),
        SizedBox(height: 400, child: ChronoAgendaView(events: events, range: DateRange.week(today))),
      ]) {
        await tester.pumpWidget(app(w));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
