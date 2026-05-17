import 'package:flutter/foundation.dart';

import 'formatters.dart';

/// Parsed components of an e-slip SCHEDULE column value.
class ParsedScheduleField {
  const ParsedScheduleField({
    required this.startTime,
    required this.endTime,
    required this.dayToken,
    required this.dayPattern,
    required this.roomCode,
    required this.startTimeRaw,
    required this.endTimeRaw,
  });

  final String startTime;
  final String endTime;
  final String dayToken;
  final String dayPattern;
  final String roomCode;
  final String startTimeRaw;
  final String endTimeRaw;
}

final RegExp _scheduleTime = RegExp(
  r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*-\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
  caseSensitive: false,
);

final RegExp _roomCode = RegExp(
  r'(COMLAB\d+[A-Z]?|TBA\d+[A-Z]?|CISCOLAB|CON\d+[A-Z]?)',
  caseSensitive: false,
);

String? _dayTokenBeforeRoom(String beforeRoom) {
  final chunk = beforeRoom.trim();
  if (chunk.isEmpty) return null;
  for (final key in const ['MTh', 'TF', 'SS', 'W']) {
    if (chunk == key || chunk.endsWith(' $key')) return key;
  }
  final joined = chunk.replaceAll(RegExp(r'\s+'), '');
  for (final key in eslipDayMap.keys) {
    if (joined == key || joined.endsWith(key)) return key;
  }
  return null;
}

String _normalizeScheduleRaw(String raw) {
  return raw
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\bp\.m\.', caseSensitive: false), 'pm')
      .replaceAll(RegExp(r'\ba\.m\.', caseSensitive: false), 'am')
      .trim();
}

({int sh, int sm, int eh, int em, String startAp, String endAp})
    _boundsFromMatch(RegExpMatch m) {
  final endAp = m.group(6)!.toLowerCase();
  final startAp = m.group(3)?.toLowerCase() ?? endAp;
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

void _logScheduleParse(String scheduleRaw, ParsedScheduleField parsed) {
  debugPrint('--- Schedule Parse ---');
  debugPrint('Raw:        $scheduleRaw');
  debugPrint('Start:      ${parsed.startTime}');
  debugPrint('End:        ${parsed.endTime}');
  debugPrint('Room:       ${parsed.roomCode}');
  debugPrint('Day token:  ${parsed.dayToken}');
  debugPrint('Day mapped: ${parsed.dayPattern}');
  debugPrint('----------------------');
}

/// Splits `"8-9 am MTh COMLAB2A"` into time, day, and room for cards and storage.
ParsedScheduleField? parseScheduleField(
  String scheduleRaw, {
  bool log = true,
}) {
  final text = _normalizeScheduleRaw(scheduleRaw);
  if (text.isEmpty) return null;

  final roomMatch = _roomCode.firstMatch(text);
  if (roomMatch == null) return null;

  final roomCode = roomMatch.group(1)!.toUpperCase();
  final beforeRoom = text.substring(0, roomMatch.start).trim();
  if (beforeRoom.isEmpty) return null;

  final dayToken = _dayTokenBeforeRoom(beforeRoom);
  if (dayToken == null) return null;

  final roomSuffix = beforeRoom.substring(
    beforeRoom.lastIndexOf(dayToken),
  );
  final timePart = beforeRoom
      .substring(0, beforeRoom.length - roomSuffix.length)
      .trim();
  if (timePart.isEmpty) return null;

  final timeMatch = _scheduleTime.firstMatch(timePart);
  if (timeMatch == null || timeMatch.start != 0) return null;

  final bounds = _boundsFromMatch(timeMatch);
  final startTimeRaw = _to24h(bounds.sh, bounds.sm, bounds.startAp);
  final endTimeRaw = _to24h(bounds.eh, bounds.em, bounds.endAp);

  final parsed = ParsedScheduleField(
    startTime: formatHm(startTimeRaw),
    endTime: formatHm(endTimeRaw),
    dayToken: dayToken,
    dayPattern: mapEslipDay(dayToken),
    roomCode: roomCode,
    startTimeRaw: startTimeRaw,
    endTimeRaw: endTimeRaw,
  );

  if (log) _logScheduleParse(scheduleRaw, parsed);
  return parsed;
}
