/// A moment in time viewed at a fixed UTC offset, such as `+05:30`.
///
/// Dart's [DateTime] only knows UTC and the device's local zone. This class
/// adds "what time is it in another offset" without bundling the 400 KB
/// IANA database. For named zones with daylight-saving rules, pass the
/// offset you get from a tz package or your backend.
class ZonedDateTime implements Comparable<ZonedDateTime> {
  /// The [instant] seen at [offset].
  ZonedDateTime(DateTime instant, this.offset) : utc = instant.toUtc();

  /// Builds from wall-clock fields at [offset].
  factory ZonedDateTime.wall(
    Duration offset,
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) =>
      ZonedDateTime(
        DateTime.utc(year, month, day, hour, minute, second).subtract(offset),
        offset,
      );

  /// Parses an ISO-8601 string with an offset, e.g.
  /// `2026-10-20T09:00:00+05:30` or `...Z`.
  static ZonedDateTime? tryParse(String input) {
    final m = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').firstMatch(input.trim());
    final dt = DateTime.tryParse(input.trim());
    if (dt == null) return null;
    if (m == null) return ZonedDateTime(dt, dt.timeZoneOffset);
    return ZonedDateTime(dt, parseOffset(m.group(1)!)!);
  }

  /// Parses `+05:30`, `-0800`, `+02` or `Z`.
  static Duration? parseOffset(String text) {
    if (text == 'Z' || text == 'z') return Duration.zero;
    final m = RegExp(r'^([+-])(\d{2}):?(\d{2})?$').firstMatch(text);
    if (m == null) return null;
    final d = Duration(hours: int.parse(m.group(2)!), minutes: int.parse(m.group(3) ?? '0'));
    return m.group(1) == '-' ? -d : d;
  }

  /// The instant, in UTC.
  final DateTime utc;

  /// Offset from UTC.
  final Duration offset;

  /// Wall-clock time at [offset], as a UTC-flagged [DateTime] whose fields
  /// read as local time in that offset (use it for display only).
  DateTime get wallTime => utc.add(offset);

  /// Year at [offset].
  int get year => wallTime.year;

  /// Month at [offset].
  int get month => wallTime.month;

  /// Day at [offset].
  int get day => wallTime.day;

  /// Hour at [offset].
  int get hour => wallTime.hour;

  /// Minute at [offset].
  int get minute => wallTime.minute;

  /// The same instant at another [offset].
  ZonedDateTime withOffset(Duration offset) => ZonedDateTime(utc, offset);

  /// The same instant in the device's local zone.
  DateTime toLocal() => utc.toLocal();

  /// Adds a fixed [duration].
  ZonedDateTime add(Duration duration) => ZonedDateTime(utc.add(duration), offset);

  /// ISO-8601 text with offset, e.g. `2026-10-20T09:00:00+05:30`.
  String toIso8601String() {
    final w = wallTime;
    String p(int v, [int n = 2]) => v.toString().padLeft(n, '0');
    final sign = offset.isNegative ? '-' : '+';
    final m = offset.inMinutes.abs();
    return '${p(w.year, 4)}-${p(w.month)}-${p(w.day)}T${p(w.hour)}:${p(w.minute)}:${p(w.second)}'
        '$sign${p(m ~/ 60)}:${p(m % 60)}';
  }

  @override
  int compareTo(ZonedDateTime other) => utc.compareTo(other.utc);

  @override
  bool operator ==(Object other) => other is ZonedDateTime && utc == other.utc && offset == other.offset;

  @override
  int get hashCode => Object.hash(utc, offset);

  @override
  String toString() => toIso8601String();
}
