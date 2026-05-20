import 'package:flutter/foundation.dart';

import '../data/day_codes.dart';
import 'parsed_schedule.dart';

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
  final core = parseScheduleString(scheduleRaw);
  if (core == null) return null;

  final parsed = ParsedScheduleField(
    startTime: core.startTime,
    endTime: core.endTime,
    dayToken: core.dayToken,
    dayPattern: readableDayPattern(core.dayToken),
    roomCode: core.room,
    startTimeRaw: core.startTimeRaw,
    endTimeRaw: core.endTimeRaw,
  );

  if (log) _logScheduleParse(scheduleRaw, parsed);
  return parsed;
}
