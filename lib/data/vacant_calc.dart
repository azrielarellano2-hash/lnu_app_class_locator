import '../models/models.dart';

double vacantHoursBetweenClasses(List<ScheduleSlot> slots, int weekday) {
  final daySlots = slots.where((s) => s.dayOfWeek == weekday).toList();
  if (daySlots.length < 2) return 0;

  int parse(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  daySlots.sort((a, b) => parse(a.startTime).compareTo(parse(b.startTime)));
  var minutes = 0;
  for (var i = 0; i < daySlots.length - 1; i++) {
    final gap = parse(daySlots[i + 1].startTime) - parse(daySlots[i].endTime);
    if (gap > 0) minutes += gap;
  }
  return (minutes / 60.0 * 100).round() / 100;
}

int distinctSubjectCount(List<ScheduleSlot> slots) {
  return slots.map((s) => s.subjectName.trim().toLowerCase()).toSet().length;
}
