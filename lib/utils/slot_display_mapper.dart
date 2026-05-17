import '../models/models.dart';
import '../models/parsed_schedule_display.dart';
import 'formatters.dart';

/// Builds card-ready fields from a stored schedule slot.
ParsedScheduleDisplay parsedScheduleFromSlot(ScheduleSlot slot) {
  final code = slot.subjectName.trim();
  final title = slot.subjectTitle?.trim();
  final instructor = sanitizeInstructorForDisplay(slot.instructorName) ?? '';

  final dayPattern = slot.dayPattern != null && slot.dayPattern!.isNotEmpty
      ? formatReadableDayPattern(slot.dayPattern!)
      : formatReadableWeekday(slot.dayOfWeek);

  return ParsedScheduleDisplay(
    startTime: formatHm(slot.startTime),
    endTime: formatHm(slot.endTime),
    subjectCode: code,
    subjectTitle: title ?? '',
    subjectName: formatCardSubject(
      subjectCode: code,
      subjectTitle: title,
    ),
    roomCode: slot.roomCode.trim(),
    instructor: instructor,
    dayPattern: dayPattern,
    dayToken: slot.dayPattern ?? '',
    startTimeRaw: slot.startTime,
    endTimeRaw: slot.endTime,
  );
}

/// One card per enrolled class block (MTh stored as two rows → one card).
List<ParsedScheduleDisplay> distinctClassBlocksFromSlots(
  List<ScheduleSlot> slots,
) {
  final seen = <String>{};
  final out = <ParsedScheduleDisplay>[];
  final sorted = List<ScheduleSlot>.from(slots)
    ..sort((a, b) {
      final t = a.startTime.compareTo(b.startTime);
      if (t != 0) return t;
      return a.subjectName.compareTo(b.subjectName);
    });

  for (final s in sorted) {
    // One card per class block (ignore weekday row duplicates for MTh/TF).
    final key = [
      s.enrollmentCode?.trim() ?? '',
      s.subjectName.trim(),
      s.startTime,
      s.endTime,
      s.roomCode.trim(),
    ].join('|');
    if (!seen.add(key)) continue;
    out.add(parsedScheduleFromSlot(s));
  }
  return out;
}
