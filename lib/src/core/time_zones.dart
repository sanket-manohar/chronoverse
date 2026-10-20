import 'date_extensions.dart';
import 'zoned_date_time.dart';

/// When daylight-saving time starts or ends in a year: the [nth] [weekday]
/// of [month] (negative [nth] counts from the end) at [minutes] past
/// midnight, measured in local standard time, or in UTC when [utc].
class DstTransition {
  /// Creates a transition rule.
  const DstTransition(this.month, this.nth, this.weekday, this.minutes, {this.utc = false});

  /// Month.
  final int month;

  /// Week position (1..4, or -1 for last).
  final int nth;

  /// Weekday.
  final int weekday;

  /// Minutes after midnight.
  final int minutes;

  /// Whether [minutes] is in UTC (EU rules) instead of local standard time.
  final bool utc;

  /// The UTC instant of this transition in [year] for a zone whose standard
  /// offset is [standard] and whose offset before the change is [before].
  DateTime instant(int year, Duration before) {
    final day = nthWeekdayOf(year, month, nth, weekday, utc: true)!;
    final at = day.add(Duration(minutes: minutes));
    return utc ? at : at.subtract(before);
  }
}

/// A daylight-saving rule: when it [starts], when it [ends] and how much
/// clocks move ([save]).
class DstRule {
  /// Creates a rule.
  const DstRule(this.starts, this.ends, {this.save = const Duration(hours: 1)});

  /// When summer time begins.
  final DstTransition starts;

  /// When summer time ends.
  final DstTransition ends;

  /// Clock change (one hour almost everywhere).
  final Duration save;

  /// US & Canada: 2nd Sunday of March 02:00 → 1st Sunday of November 02:00.
  static const northAmerica = DstRule(
    DstTransition(3, 2, DateTime.sunday, 120),
    DstTransition(11, 1, DateTime.sunday, 120),
  );

  /// European Union & UK: last Sunday of March → last Sunday of October,
  /// both at 01:00 UTC.
  static const europe = DstRule(
    DstTransition(3, -1, DateTime.sunday, 60, utc: true),
    DstTransition(10, -1, DateTime.sunday, 60, utc: true),
  );

  /// South-east Australia: 1st Sunday of October 02:00 → 1st Sunday of
  /// April 03:00 (local daylight time, i.e. 02:00 standard).
  static const australia = DstRule(
    DstTransition(10, 1, DateTime.sunday, 120),
    DstTransition(4, 1, DateTime.sunday, 120),
  );

  /// New Zealand: last Sunday of September → 1st Sunday of April.
  static const newZealand = DstRule(
    DstTransition(9, -1, DateTime.sunday, 120),
    DstTransition(4, 1, DateTime.sunday, 120),
  );
}

/// A named time zone with a standard offset and an optional DST rule.
///
/// Chronoverse ships the current rules for the most used IANA zones (about
/// 60, a few KB) instead of the full 400 KB database. Historical rule
/// changes are not modelled; if you need them, register zones built from a
/// full time-zone database with [ChronoTimeZone.register].
class ChronoTimeZone {
  /// Creates a zone.
  const ChronoTimeZone(this.id, this.standardOffset, {this.dst, this.label});

  /// IANA id such as `Asia/Kolkata`.
  final String id;

  /// Offset in winter / without DST.
  final Duration standardOffset;

  /// Daylight-saving rule, null when the zone has none.
  final DstRule? dst;

  /// Friendly name, e.g. "India Standard Time".
  final String? label;

  /// Whether DST applies at [instant].
  bool isDst(DateTime instant) {
    final rule = dst;
    if (rule == null) return false;
    final u = instant.toUtc();
    final start = rule.starts.instant(u.year, standardOffset);
    final end = rule.ends.instant(u.year, standardOffset + rule.save);
    // Southern hemisphere zones have DST over the new year.
    return start.isBefore(end) ? !u.isBefore(start) && u.isBefore(end) : !u.isBefore(start) || u.isBefore(end);
  }

  /// UTC offset in effect at [instant].
  Duration offsetAt(DateTime instant) => isDst(instant) ? standardOffset + dst!.save : standardOffset;

  /// [instant] as wall-clock time in this zone.
  ZonedDateTime at(DateTime instant) => ZonedDateTime(instant, offsetAt(instant));

  /// The instant for a wall-clock time in this zone. Times in the
  /// spring-forward gap move forward; ambiguous autumn times use the
  /// first (daylight) occurrence.
  ZonedDateTime fromWall(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0]) {
    final naive = DateTime.utc(year, month, day, hour, minute);
    final summer = naive.subtract(standardOffset + (dst?.save ?? Duration.zero));
    final winter = naive.subtract(standardOffset);
    bool valid(DateTime u, Duration o) => offsetAt(u) == o;
    // Ambiguous autumn hour: prefer the first (daylight) occurrence.
    if (dst != null && valid(summer, standardOffset + dst!.save)) {
      return ZonedDateTime(summer, offsetAt(summer));
    }
    // Normal time, or a spring-forward gap, which moves forward.
    return ZonedDateTime(winter, offsetAt(winter));
  }

  /// Converts wall-clock [time] in this zone to wall-clock time in [other].
  ZonedDateTime convert(DateTime time, ChronoTimeZone other) =>
      other.at(fromWall(time.year, time.month, time.day, time.hour, time.minute).utc);

  /// `+05:30` style text for the offset at [instant] (now by default).
  String offsetLabel([DateTime? instant]) {
    final o = offsetAt(instant ?? DateTime.now());
    final m = o.inMinutes.abs();
    return 'UTC${o.isNegative ? '-' : '+'}${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  @override
  String toString() => id;

  static final Map<String, ChronoTimeZone> _zones = {for (final z in _builtIn) z.id: z};

  /// Every known zone id.
  static Iterable<String> get ids => _zones.keys;

  /// Every known zone.
  static Iterable<ChronoTimeZone> get all => _zones.values;

  /// Looks up an IANA id (also accepts `UTC`, `GMT`, `Z` and `+05:30`).
  static ChronoTimeZone? tryGet(String id) {
    final z = _zones[id];
    if (z != null) return z;
    if (id == 'Z' || id == 'GMT') return utc;
    final offset = ZonedDateTime.parseOffset(id);
    return offset == null ? null : ChronoTimeZone(id, offset);
  }

  /// Like [tryGet] but throws for unknown ids.
  static ChronoTimeZone get(String id) => tryGet(id) ?? (throw ArgumentError.value(id, 'id', 'Unknown time zone'));

  /// Adds or replaces a zone.
  static void register(ChronoTimeZone zone) => _zones[zone.id] = zone;

  /// UTC.
  static const utc = ChronoTimeZone('UTC', Duration.zero, label: 'Coordinated Universal Time');

  static const _builtIn = <ChronoTimeZone>[
    utc,
    // Americas
    ChronoTimeZone('America/New_York', Duration(hours: -5), dst: DstRule.northAmerica, label: 'Eastern Time'),
    ChronoTimeZone('America/Chicago', Duration(hours: -6), dst: DstRule.northAmerica, label: 'Central Time'),
    ChronoTimeZone('America/Denver', Duration(hours: -7), dst: DstRule.northAmerica, label: 'Mountain Time'),
    ChronoTimeZone('America/Phoenix', Duration(hours: -7), label: 'Mountain Time (Arizona)'),
    ChronoTimeZone('America/Los_Angeles', Duration(hours: -8), dst: DstRule.northAmerica, label: 'Pacific Time'),
    ChronoTimeZone('America/Anchorage', Duration(hours: -9), dst: DstRule.northAmerica, label: 'Alaska Time'),
    ChronoTimeZone('Pacific/Honolulu', Duration(hours: -10), label: 'Hawaii Time'),
    ChronoTimeZone('America/Toronto', Duration(hours: -5), dst: DstRule.northAmerica, label: 'Eastern Time (Toronto)'),
    ChronoTimeZone('America/Vancouver', Duration(hours: -8),
        dst: DstRule.northAmerica, label: 'Pacific Time (Vancouver)'),
    ChronoTimeZone('America/Halifax', Duration(hours: -4), dst: DstRule.northAmerica, label: 'Atlantic Time'),
    ChronoTimeZone('America/Mexico_City', Duration(hours: -6), label: 'Mexico City'),
    ChronoTimeZone('America/Bogota', Duration(hours: -5), label: 'Colombia'),
    ChronoTimeZone('America/Lima', Duration(hours: -5), label: 'Peru'),
    ChronoTimeZone('America/Caracas', Duration(hours: -4), label: 'Venezuela'),
    ChronoTimeZone('America/Sao_Paulo', Duration(hours: -3), label: 'Brasília Time'),
    ChronoTimeZone('America/Argentina/Buenos_Aires', Duration(hours: -3), label: 'Argentina'),
    // Europe & Africa
    ChronoTimeZone('Europe/London', Duration.zero, dst: DstRule.europe, label: 'UK Time'),
    ChronoTimeZone('Europe/Dublin', Duration.zero, dst: DstRule.europe, label: 'Ireland'),
    ChronoTimeZone('Europe/Lisbon', Duration.zero, dst: DstRule.europe, label: 'Portugal'),
    ChronoTimeZone('Europe/Paris', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Berlin', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Madrid', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Rome', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Amsterdam', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Stockholm', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Warsaw', Duration(hours: 1), dst: DstRule.europe, label: 'Central European Time'),
    ChronoTimeZone('Europe/Athens', Duration(hours: 2), dst: DstRule.europe, label: 'Eastern European Time'),
    ChronoTimeZone('Europe/Helsinki', Duration(hours: 2), dst: DstRule.europe, label: 'Eastern European Time'),
    ChronoTimeZone('Europe/Kyiv', Duration(hours: 2), dst: DstRule.europe, label: 'Eastern European Time'),
    ChronoTimeZone('Europe/Istanbul', Duration(hours: 3), label: 'Turkey Time'),
    ChronoTimeZone('Europe/Moscow', Duration(hours: 3), label: 'Moscow Time'),
    ChronoTimeZone('Africa/Lagos', Duration(hours: 1), label: 'West Africa Time'),
    ChronoTimeZone('Africa/Cairo', Duration(hours: 2), label: 'Egypt'),
    ChronoTimeZone('Africa/Johannesburg', Duration(hours: 2), label: 'South Africa'),
    ChronoTimeZone('Africa/Nairobi', Duration(hours: 3), label: 'East Africa Time'),
    // Asia & Middle East
    ChronoTimeZone('Asia/Dubai', Duration(hours: 4), label: 'Gulf Standard Time'),
    ChronoTimeZone('Asia/Riyadh', Duration(hours: 3), label: 'Arabia Standard Time'),
    ChronoTimeZone('Asia/Tehran', Duration(hours: 3, minutes: 30), label: 'Iran'),
    ChronoTimeZone('Asia/Karachi', Duration(hours: 5), label: 'Pakistan'),
    ChronoTimeZone('Asia/Kolkata', Duration(hours: 5, minutes: 30), label: 'India Standard Time'),
    ChronoTimeZone('Asia/Colombo', Duration(hours: 5, minutes: 30), label: 'Sri Lanka'),
    ChronoTimeZone('Asia/Kathmandu', Duration(hours: 5, minutes: 45), label: 'Nepal'),
    ChronoTimeZone('Asia/Dhaka', Duration(hours: 6), label: 'Bangladesh'),
    ChronoTimeZone('Asia/Bangkok', Duration(hours: 7), label: 'Indochina Time'),
    ChronoTimeZone('Asia/Jakarta', Duration(hours: 7), label: 'Western Indonesia'),
    ChronoTimeZone('Asia/Singapore', Duration(hours: 8), label: 'Singapore'),
    ChronoTimeZone('Asia/Kuala_Lumpur', Duration(hours: 8), label: 'Malaysia'),
    ChronoTimeZone('Asia/Manila', Duration(hours: 8), label: 'Philippines'),
    ChronoTimeZone('Asia/Shanghai', Duration(hours: 8), label: 'China Standard Time'),
    ChronoTimeZone('Asia/Hong_Kong', Duration(hours: 8), label: 'Hong Kong'),
    ChronoTimeZone('Asia/Taipei', Duration(hours: 8), label: 'Taipei'),
    ChronoTimeZone('Asia/Seoul', Duration(hours: 9), label: 'Korea Standard Time'),
    ChronoTimeZone('Asia/Tokyo', Duration(hours: 9), label: 'Japan Standard Time'),
    // Oceania
    ChronoTimeZone('Australia/Perth', Duration(hours: 8), label: 'Western Australia'),
    ChronoTimeZone('Australia/Brisbane', Duration(hours: 10), label: 'Queensland'),
    ChronoTimeZone('Australia/Adelaide', Duration(hours: 9, minutes: 30),
        dst: DstRule.australia, label: 'Central Australia'),
    ChronoTimeZone('Australia/Sydney', Duration(hours: 10), dst: DstRule.australia, label: 'Eastern Australia'),
    ChronoTimeZone('Australia/Melbourne', Duration(hours: 10), dst: DstRule.australia, label: 'Eastern Australia'),
    ChronoTimeZone('Pacific/Auckland', Duration(hours: 12), dst: DstRule.newZealand, label: 'New Zealand'),
  ];
}
