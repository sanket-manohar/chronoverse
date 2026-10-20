// Renders the demo gallery to PNG files for the README and guides.
//
//   flutter test test/screenshots_test.dart --update-goldens
//
// Put a regular, medium and bold sans-serif font plus the icon font in
// test/fonts first (see loadFonts below); images land in test/goldens.
import 'dart:io';

import 'package:chronoverse_example/demos.dart';
import 'package:chronoverse_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFonts() async {
  final dir = Directory('test/fonts');
  if (!dir.existsSync()) return;
  final text = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  final mono = FontLoader('monospace');
  for (final f in dir.listSync().whereType<File>()) {
    final bytes = Future.value(ByteData.sublistView(f.readAsBytesSync()));
    if (f.path.contains('Icons')) {
      icons.addFont(bytes);
    } else if (f.path.contains('Mono')) {
      mono.addFont(bytes);
    } else {
      text.addFont(bytes);
    }
  }
  await text.load();
  await icons.load();
  await mono.load();
}

Future<void> shoot(WidgetTester tester, String name, Widget app,
    {Size size = const Size(400, 860), Future<void> Function()? after}) async {
  tester.view.physicalSize = size * 2.5;
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  if (after != null) {
    await after();
    await tester.pumpAndSettle();
  }
  await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(loadFonts);

  const scenes = {
    'month': 0,
    'planner': 1,
    'booking': 2,
    'pickers': 3,
    'schedule': 4,
    'agenda': 5,
    'year': 6,
    'strip': 7,
    'theming': 8,
    'toolbox': 9,
  };

  scenes.forEach((name, index) {
    testWidgets(name, (tester) => shoot(tester, name, ChronoverseGallery(initialIndex: index)));
  });

  testWidgets('month_dark', (tester) => shoot(tester, 'month_dark', const ChronoverseGallery(dark: true)));
  testWidgets('schedule_dark',
      (tester) => shoot(tester, 'schedule_dark', const ChronoverseGallery(initialIndex: 4, dark: true)));

  testWidgets('week_collapsed', (tester) async {
    await shoot(tester, 'week_collapsed', const ChronoverseGallery(), after: () async {
      await tester.tap(find.text('This week'));
    });
  });

  testWidgets('quick_picker', (tester) async {
    await shoot(tester, 'quick_picker', const ChronoverseGallery(), after: () async {
      await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
    });
  });

  testWidgets('date_dialog', (tester) async {
    await shoot(tester, 'date_dialog', const ChronoverseGallery(initialIndex: 3), after: () async {
      await tester.tap(find.text('Date dialog'));
    });
  });

  testWidgets('range_sheet', (tester) async {
    await shoot(tester, 'range_sheet', const ChronoverseGallery(initialIndex: 3), after: () async {
      await tester.tap(find.text('Range sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 days'));
    });
  });

  testWidgets('wide_schedule', (tester) async {
    await shoot(tester, 'wide_schedule', const ChronoverseGallery(initialIndex: 4), size: const Size(1200, 760));
  });

  testWidgets('wide_week', (tester) async {
    await shoot(
      tester,
      'wide_week',
      const MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: ScheduleDemo(days: 7))),
      size: const Size(1200, 760),
    );
  });
}
