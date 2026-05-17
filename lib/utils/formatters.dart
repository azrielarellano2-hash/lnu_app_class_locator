import 'package:intl/intl.dart';

import '../data/day_codes.dart';

const Map<String, String> eslipDayMap = {
  'MTh': 'Monday and Thursday',
  'W': 'Wednesday',
  'TF': 'Tuesday and Friday',
  'SS': 'Saturday and Sunday',
};

String mapEslipDay(String raw) => eslipDayMap[raw.trim()] ?? raw.trim();

String formatHm(String timeIso) {
  final parts = timeIso.split(':');
  if (parts.length < 2) return timeIso;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final dt = DateTime(2000, 1, 1, h, m);
  return DateFormat.jm().format(dt);
}

/// Human-readable class time range from stored HH:mm strings.
String formatTimeRange(String startIso, String endIso) =>
    '${formatHm(startIso)} – ${formatHm(endIso)}';

/// Short day token for stored weekday index (0 = Monday … 6 = Sunday), LNU-style.
String dayScheduleTokenFromWeekdayIndex(int dayOfWeek) {
  const tokens = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
  if (dayOfWeek < 0 || dayOfWeek >= tokens.length) return '?';
  return tokens[dayOfWeek];
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// LNU e-slip day token → readable label (exact-key lookup only).
String formatReadableDayPattern(String raw) => mapEslipDay(raw);

String formatReadableWeekday(int dayOfWeek) {
  if (dayOfWeek < 0 || dayOfWeek >= _weekdayNames.length) return '—';
  return _weekdayNames[dayOfWeek];
}

final RegExp _ocrScheduleNoise = RegExp(
  r'(\d{1,2})(?::(\d{2}))?\s*-\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)|\b(MTh|MWF|TF|TTH|COMLAB|TBA)\b',
  caseSensitive: false,
);

bool looksLikeRawOcrScheduleLine(String value) =>
    _ocrScheduleNoise.hasMatch(value);

/// Bold card line — course description only; falls back to code when title is missing.
String formatCardDescription({
  String? subjectTitle,
  required String subjectCode,
}) {
  final title = subjectTitle?.trim();
  final cleanTitle = title != null &&
          title.isNotEmpty &&
          title.length <= 120 &&
          !looksLikeRawOcrScheduleLine(title)
      ? title
      : null;
  if (cleanTitle != null) return cleanTitle;

  final code = subjectCode.trim();
  if (code.isNotEmpty && code.toUpperCase() != 'CLASS') return code;
  return '';
}

/// Course line for schedule cards (code + title); never raw OCR schedule text.
String formatCardSubject({
  String? subjectTitle,
  required String subjectCode,
}) {
  final code = subjectCode.trim();
  final title = subjectTitle?.trim();
  final cleanCode =
      code.isNotEmpty && code.toUpperCase() != 'CLASS' ? code : null;
  final cleanTitle = title != null &&
          title.isNotEmpty &&
          title.length <= 120 &&
          !looksLikeRawOcrScheduleLine(title)
      ? title
      : null;

  if (cleanTitle != null && cleanTitle.isNotEmpty) {
    if (cleanCode != null) return '$cleanCode $cleanTitle';
    return cleanTitle;
  }
  if (cleanCode != null) return cleanCode;
  return '';
}

/// Returns null when [raw] is missing or looks like OCR schedule/room noise.
String? sanitizeInstructorForDisplay(String? raw) {
  final name = raw?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (name == null || name.isEmpty) return null;
  if (name.length > 80) return null;
  if (looksLikeRawOcrScheduleLine(name)) return null;
  if (RegExp(
    r'\b(COMLAB|CISCOLAB|TBA\d|CON\d)',
    caseSensitive: false,
  ).hasMatch(name)) {
    return null;
  }
  if (!RegExp(r'^[A-Z]\.\s+[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*')
      .hasMatch(name)) {
    return null;
  }
  return name;
}

/// Removes schedule/time/day/room fragments accidentally merged into titles.
String stripScheduleNoiseFromText(String raw) {
  var s = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) return s;
  s = s.replaceAll(_ocrScheduleNoise, ' ').trim();
  s = s.replaceAll(
    RegExp(r'\b(COMLAB\d+[A-Z]?|TBA\d+[A-Z]?|CISCOLAB|CON\d+[A-Z]?)\b',
        caseSensitive: false),
    ' ',
  ).trim();
  for (final day in eslipDayMap.keys) {
    s = s.replaceAll(RegExp('\\b$day\\b'), ' ').trim();
  }
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String formatInstructorLabel(String instructorName) =>
    'Instructor: ${instructorName.trim()}';

String formatEslipTimeRange(String startTimeRaw, String endTimeRaw) {
  String norm(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return raw.trim();
  }

  return formatTimeRange(norm(startTimeRaw), norm(endTimeRaw));
}

/// Picks a display last name from slip-style strings (e.g. `DELA CRUZ, JUAN`, `Prof. Smith`).
String? formatInstructorLastName(String? raw) {
  if (raw == null) return null;
  var s = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.length < 2) return null;
  s = s.replaceFirst(
    RegExp(r'^(prof\.?|professor|dr\.?|mr\.?|mrs\.?|ms\.?|engr\.?)\s+', caseSensitive: false),
    '',
  ).trim();
  if (s.isEmpty) return null;
  final comma = s.indexOf(',');
  if (comma > 0) {
    return s.substring(0, comma).trim();
  }
  final parts = s.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  final suffix = RegExp(r'^(jr\.?|sr\.?|iii|ii|iv|phd|msc)$', caseSensitive: true);
  while (parts.isNotEmpty && suffix.hasMatch(parts.last.replaceAll('.', ''))) {
    parts.removeLast();
  }
  while (parts.isNotEmpty && RegExp(r'^[A-Z]\.?$', caseSensitive: false).hasMatch(parts.last)) {
    parts.removeLast();
  }
  if (parts.isEmpty) return null;
  return parts.last;
}

/// One line: TIME&DAY, ROOM, INSTRUCTOR (as stored — matches slip initials style).
String formatScheduleScanLine({
  required String roomCode,
  required String startTime,
  required String endTime,
  required String scheduleToken,
  String? instructorName,
}) {
  final timeDay = '${formatTimeRange(startTime, endTime)}&$scheduleToken';
  final ins = instructorName?.trim();
  if (ins != null && ins.isNotEmpty) {
    return '$timeDay, $roomCode, $ins';
  }
  return '$timeDay, $roomCode';
}

int _hourFromIso(String iso) => int.parse(iso.split(':').first);
int _minuteFromIso(String iso) => int.parse(iso.split(':')[1]);

bool _isPmHour(int hour24) => hour24 >= 12;

String _slipClockToken(int hour24, int minute) {
  var h12 = hour24 % 12;
  if (h12 == 0) h12 = 12;
  if (minute == 0) return h12.toString();
  return '$h12:${minute.toString().padLeft(2, '0')}';
}

/// SCHEDULE column on the LNU form (e.g. `8-9 am MTh COMLAB2A`).
String formatEslipScheduleColumn({
  required String dayPattern,
  required String startTimeRaw,
  required String endTimeRaw,
  required String roomCode,
}) {
  final sh = _hourFromIso(startTimeRaw);
  final sm = _minuteFromIso(startTimeRaw);
  final eh = _hourFromIso(endTimeRaw);
  final em = _minuteFromIso(endTimeRaw);
  final startPm = _isPmHour(sh);
  final endPm = _isPmHour(eh);

  final startTok = _slipClockToken(sh, sm);
  final endTok = _slipClockToken(eh, em);

  final String timePart;
  if (startPm == endPm) {
    final ap = startPm ? 'pm' : 'am';
    timePart = '$startTok-$endTok $ap';
  } else {
    final sap = startPm ? 'pm' : 'am';
    final eap = endPm ? 'pm' : 'am';
    timePart = '$startTok $sap-$endTok $eap';
  }

  return '$timePart $dayPattern $roomCode';
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime mondayOfWeekContaining(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}
