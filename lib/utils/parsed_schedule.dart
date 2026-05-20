import '../data/day_codes.dart';
import 'formatters.dart';
import 'lnu_slip_patterns.dart';

/// Parsed schedule column: time, expanded weekdays, room.
class ParsedSchedule {
  const ParsedSchedule({
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.room,
    required this.dayToken,
    required this.startTimeRaw,
    required this.endTimeRaw,
  });

  final String startTime;
  final String endTime;
  final List<String> days;
  final String room;
  final String dayToken;
  final String startTimeRaw;
  final String endTimeRaw;
}

final RegExp _scheduleTime = lnuScheduleTimePattern;
final RegExp _roomCode = lnuRoomCodePattern;

String normalizeScheduleOcr(String raw) {
  return raw
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[’‘`]'), "'")
      .replaceAll(RegExp(r'\bMth\b'), 'MTh')
      .replaceAll(RegExp(r'\bMTH\b'), 'MTh')
      .replaceAll(RegExp(r'\bNTh\b'), 'MTh')
      .replaceAll(RegExp(r'\bTth\b', caseSensitive: false), 'TF')
      .replaceAll(RegExp(r'\bTTH\b'), 'TF')
      .replaceAll(RegExp(r'\bWed\b', caseSensitive: false), 'W')
      .replaceAll(RegExp(r'\bp\.m\.', caseSensitive: false), 'pm')
      .replaceAll(RegExp(r'\ba\.m\.', caseSensitive: false), 'am')
      .trim();
}

({int sh, int sm, int eh, int em, String startAp, String endAp}) _bounds(
  RegExpMatch m,
) {
  final endAp = m.group(6)!.toLowerCase();
  var startAp = m.group(3)?.toLowerCase() ?? '';
  if (startAp.isEmpty) {
    final sh = int.parse(m.group(1)!);
    final eh = int.parse(m.group(4)!);
    startAp = sh > eh ? 'am' : endAp;
  }
  return (
    sh: int.parse(m.group(1)!),
    sm: int.tryParse(m.group(2) ?? '0') ?? 0,
    eh: int.parse(m.group(4)!),
    em: int.tryParse(m.group(5) ?? '0') ?? 0,
    startAp: startAp,
    endAp: endAp,
  );
}

String _to24h(int hour12, int minute, String ampm) {
  var h = hour12;
  final ap = ampm.toLowerCase();
  if (ap == 'pm' && h != 12) h += 12;
  if (ap == 'am' && h == 12) h = 0;
  return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Parses `"9-10:30 am MTh COMLAB4A"` → structured schedule.
ParsedSchedule? parseScheduleString(String scheduleRaw) {
  final text = normalizeScheduleOcr(scheduleRaw);
  if (text.isEmpty) return null;

  final roomMatch = _roomCode.firstMatch(text);
  if (roomMatch == null) return null;

  final room = roomMatch.group(1)!.toUpperCase();
  final beforeRoom = text.substring(0, roomMatch.start).trim();
  if (beforeRoom.isEmpty) return null;

  final dayToken = matchScheduleDayToken(beforeRoom);
  if (dayToken == null) return null;

  final dayIdx = beforeRoom.lastIndexOf(dayToken);
  final timePart = beforeRoom.substring(0, dayIdx).trim();
  if (timePart.isEmpty) return null;

  final timeMatch = _scheduleTime.firstMatch(timePart);
  if (timeMatch == null || timeMatch.start != 0) return null;

  final b = _bounds(timeMatch);
  final startRaw = _to24h(b.sh, b.sm, b.startAp);
  final endRaw = _to24h(b.eh, b.em, b.endAp);
  final dayNames = weekdayNamesForToken(dayToken);

  return ParsedSchedule(
    startTime: formatHm(startRaw),
    endTime: formatHm(endRaw),
    days: dayNames,
    room: room,
    dayToken: dayToken,
    startTimeRaw: startRaw,
    endTimeRaw: endRaw,
  );
}
