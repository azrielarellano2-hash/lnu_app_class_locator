import '../models/models.dart';
import 'formatters.dart';

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Whether [dayPattern] (MTh, TF, …) includes the given weekday name.
bool dayPatternContainsWeekday(String? dayPattern, int weekdayIndex) {
  if (weekdayIndex < 0 || weekdayIndex >= weekdayNames.length) return false;
  final token = dayPattern?.trim();
  if (token == null || token.isEmpty) return false;
  return formatReadableDayPattern(token).contains(weekdayNames[weekdayIndex]);
}

/// True when this slot should appear on the selected weekday tab.
bool scheduleSlotOnWeekday(ScheduleSlot slot, int weekdayIndex) {
  if (dayPatternContainsWeekday(slot.dayPattern, weekdayIndex)) {
    return true;
  }
  return slot.dayOfWeek == weekdayIndex;
}

/// One card per class block (MTh stored as two DB rows → one card per day).
List<ScheduleSlot> dedupeScheduleSlotsForDisplay(List<ScheduleSlot> slots) {
  final seen = <String>{};
  final out = <ScheduleSlot>[];
  for (final s in slots) {
    final key =
        '${s.subjectName}|${s.startTime}|${s.endTime}|${s.roomCode}';
    if (seen.add(key)) out.add(s);
  }
  return out;
}

List<ScheduleSlot> filterSlotsForWeekday(
  List<ScheduleSlot> all,
  int weekdayIndex,
) {
  final filtered = all
      .where((s) => scheduleSlotOnWeekday(s, weekdayIndex))
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return dedupeScheduleSlotsForDisplay(filtered);
}
