import 'package:flutter/material.dart';

import 'demos.dart';

void main() => runApp(const ChronoverseGallery());

class _Demo {
  const _Demo(this.title, this.icon, this.builder);
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

final _demos = <_Demo>[
  _Demo('Month', Icons.calendar_month, (_) => const MonthDemo()),
  _Demo('Planner', Icons.drag_indicator, (_) => const PlannerDemo()),
  _Demo('Booking', Icons.hotel, (_) => const BookingDemo()),
  _Demo('Pickers', Icons.touch_app, (_) => const PickersDemo()),
  _Demo('Schedule', Icons.view_week, (_) => const ScheduleDemo()),
  _Demo('Agenda', Icons.view_agenda, (_) => const AgendaDemo()),
  _Demo('Year', Icons.grid_view, (_) => const YearDemo()),
  _Demo('Strip', Icons.view_carousel, (_) => const StripDemo()),
  _Demo('Theming', Icons.palette, (_) => const ThemingDemo()),
  _Demo('Toolbox', Icons.functions, (_) => const ToolboxDemo()),
];

/// The Chronoverse demo gallery.
class ChronoverseGallery extends StatefulWidget {
  const ChronoverseGallery({super.key, this.initialIndex = 0, this.dark = false});

  final int initialIndex;
  final bool dark;

  @override
  State<ChronoverseGallery> createState() => _ChronoverseGalleryState();
}

class _ChronoverseGalleryState extends State<ChronoverseGallery> {
  late int _index = widget.initialIndex;
  late bool _dark = widget.dark;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B5BD6);
    return MaterialApp(
      title: 'Chronoverse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth > 720;
        final body = _demos[_index].builder(context);
        return Scaffold(
          appBar: AppBar(
            title: Text('Chronoverse · ${_demos[_index].title}'),
            actions: [
              IconButton(
                tooltip: 'Toggle dark mode',
                icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => setState(() => _dark = !_dark),
              ),
            ],
          ),
          body: wide
              ? Row(children: [
                  NavigationRail(
                    selectedIndex: _index,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    destinations: [
                      for (final d in _demos) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.title)),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: KeyedSubtree(key: ValueKey(_index), child: body)),
                ])
              : KeyedSubtree(key: ValueKey(_index), child: body),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  destinations: [
                    for (final d in _demos) NavigationDestination(icon: Icon(d.icon), label: d.title),
                  ],
                ),
        );
      }),
    );
  }
}
