# Chronoverse example gallery

Ten demos covering every Chronoverse widget: month, planner with drag & drop, booking, pickers,
schedule, agenda, year and heatmap, week strip, theming and the Chrono toolbox.

```bash
flutter pub get
flutter run
```

Works on Android, iOS, web, macOS, Windows and Linux.

## Minimal example

```dart
import 'package:chronoverse/chronoverse.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('Chronoverse')),
        body: ChronoCalendar(
          mode: ChronoSelectionMode.range,
          expandable: true,
          onRangeSelected: (range) => debugPrint('$range'),
        ),
      ),
    );
  }
}
```

The full gallery is in [`lib/main.dart`](lib/main.dart) and [`lib/demos.dart`](lib/demos.dart).
