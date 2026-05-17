import 'package:flutter/foundation.dart';

import '../data/day_codes.dart';
import '../models/parsed_schedule_display.dart';
import 'formatters.dart';
import 'schedule_field_parser.dart';

/// One fully parsed class row from e-slip OCR.
class EslipClassRow {
  const EslipClassRow({
    this.enrollmentCode,
    required this.parsed,
  });

  final String? enrollmentCode;
  final ParsedScheduleDisplay parsed;
}

class EslipParsedProfile {
  const EslipParsedProfile({
    this.studentId,
    this.fullName,
    this.college,
    this.course,
    this.section,
  });

  final String? studentId;
  final String? fullName;
  final String? college;
  final String? course;
  final String? section;
}

class EslipParseOutcome {
  const EslipParseOutcome({
    required this.profile,
    required this.classes,
    required this.warnings,
  });

  final EslipParsedProfile profile;
  final List<EslipClassRow> classes;
  final List<String> warnings;
}

// --- LNU e-slip patterns ---

/// Lab suffix (IT-121L) must be captured before the shorter IT-121 match.
final RegExp _subjectCode =
    RegExp(r'[A-Z]{2,3}-\d{2,4}L|[A-Z]{2,3}-\d{2,4}(?![0-9A-Za-z])');

final RegExp _scheduleTime = RegExp(
  r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*-\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
  caseSensitive: false,
);

final RegExp _roomCode = RegExp(
  r'(COMLAB\d+[A-Z]?|TBA\d+[A-Z]?|CISCOLAB|CON\d+[A-Z]?)',
  caseSensitive: false,
);

final RegExp _instructorPattern = RegExp(
  r'[A-Z]\.\s+(?:[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)',
);

final RegExp _sectionCode = RegExp(r'\b[A-Z]{2}\d{2}\b');

final RegExp _rowCode = RegExp(r'\bA\s?\d{3,4}\b');

String preprocessEslipOcrText(String raw) {
  var s = raw.replaceAll(RegExp(r'\r\n?'), '\n');
  s = s.replaceAll(RegExp(r'[–—−]'), '-');
  s = s.replaceAll(RegExp(r'\bp\.m\.', caseSensitive: false), 'pm');
  s = s.replaceAll(RegExp(r'\ba\.m\.', caseSensitive: false), 'am');
  s = s.replaceAllMapped(
    RegExp(r'\bA\s+(\d{3,4})\b'),
    (m) => 'A${m.group(1)}',
  );
  s = s.replaceAll(
    RegExp(r'(\d)(am|pm)\b', caseSensitive: false),
    r'$1 $2',
  );
  // Common ML Kit spacing / misreads on LNU slips.
  s = s.replaceAll(RegExp(r'COM\s*LAB', caseSensitive: false), 'COMLAB');
  s = s.replaceAll(RegExp(r'CISCO\s*LAB', caseSensitive: false), 'CISCOLAB');
  s = s.replaceAllMapped(
    RegExp(r'\bT\s*BA(\d)', caseSensitive: false),
    (m) => 'TBA${m.group(1)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'\bCON\s*(\d)', caseSensitive: false),
    (m) => 'CON${m.group(1)}',
  );
  s = s.replaceAll(RegExp(r'\bM\s+Th\b', caseSensitive: false), 'MTh');
  s = s.replaceAll(RegExp(r'\bT\s+F\b', caseSensitive: false), 'TF');
  s = s.replaceAllMapped(
    RegExp(r'\bAl(\d{2})\b'),
    (m) => 'AI${m.group(1)}',
  );
  // IT - 122L / IT- 121L → IT-122L (LNU subject prefixes only; skips AI31 section codes)
  s = s.replaceAllMapped(
    RegExp(r'\b([A-Z]{2,3})\s*-\s*(\d{2,4})(L)?\b'),
    (m) {
      final dept = m.group(1)!.toUpperCase();
      // Skip section codes like AI31, not subject departments.
      if (dept == 'AI' && (m.group(2)?.length ?? 0) <= 2) {
        return m.group(0)!;
      }
      return '$dept-${m.group(2)}${m.group(3) ?? ''}';
    },
  );
  // 9 - 10:30 am → 9-10:30 am
  s = s.replaceAllMapped(
    RegExp(r'(\d)\s+-\s+(\d)'),
    (m) => '${m.group(1)}-${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'COMLAB\s*(\d)', caseSensitive: false),
    (m) => 'COMLAB${m.group(1)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'(\d{1,2})\s*:\s*(\d{2})'),
    (m) => '${m.group(1)}:${m.group(2)}',
  );
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  s = s.replaceAllMapped(
    RegExp(r'\b([A-Za-z]{2,3}-\d{2,4}L?)\b'),
    (m) => m.group(1)!.toUpperCase(),
  );
  return s;
}

String _collapseRowText(String text) =>
    text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

({int sh, int sm, int eh, int em, String startAp, String endAp})
    _scheduleBoundsFromMatch(RegExpMatch m) {
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

String _toTimeLabel(int hour12, int minute, String ampm) {
  var h = hour12;
  final ap = ampm.toLowerCase();
  if (ap == 'pm' && h != 12) h += 12;
  if (ap == 'am' && h == 12) h = 0;
  return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const Map<String, String> _dayTokenAliases = {
  'MT': 'MTh',
  'MTH': 'MTh',
  'TTH': 'TF',
  'TUTH': 'TF',
  'WED': 'W',
};

String? _extractDayToken(String afterTime, String roomMatchText) {
  final roomStart = afterTime.indexOf(roomMatchText);
  if (roomStart < 0) return null;
  var beforeRoom = afterTime.substring(0, roomStart).trim();
  beforeRoom = beforeRoom.replaceAll(RegExp(r'[.,;]+$'), '').trim();
  if (beforeRoom.isEmpty) return null;

  if (eslipDayMap.containsKey(beforeRoom)) return beforeRoom;
  final joined = beforeRoom.replaceAll(RegExp(r'\s+'), '');
  if (eslipDayMap.containsKey(joined)) return joined;
  final alias = _dayTokenAliases[joined.toUpperCase()];
  if (alias != null) return alias;

  for (final key in const ['MTh', 'TF', 'SS', 'W']) {
    if (beforeRoom == key || beforeRoom.endsWith(' $key')) return key;
  }
  for (final key in eslipDayMap.keys) {
    if (joined == key || joined.endsWith(key)) return key;
  }
  return null;
}

RegExpMatch? _locateRoomAfterTime(String afterTime) {
  final matches = _roomCode.allMatches(afterTime).toList();
  if (matches.isEmpty) return null;
  return matches.last;
}

RegExpMatch? _bestSubjectBeforeTime(String beforeTime) {
  final matches = _subjectCode.allMatches(beforeTime).toList();
  if (matches.isEmpty) return null;
  return matches.reduce(
    (a, b) => a.group(0)!.length >= b.group(0)!.length ? a : b,
  );
}

RegExpMatch? _locateTimeInRow(String collapsed) =>
    _scheduleTime.firstMatch(collapsed);

String _buildSubjectNameLine(String code, String? description) {
  return formatCardSubject(
    subjectCode: code,
    subjectTitle: description,
  );
}

String? _extractDescription(String afterCode, int timeStart, String subjectCode) {
  if (timeStart <= 0) return null;
  var chunk = afterCode.substring(0, timeStart).trim();
  chunk = chunk.replaceAll(RegExp(r'\s+'), ' ');
  // UNITS and optional LAB columns before the schedule time.
  chunk = chunk.replaceAll(RegExp(r'\s+\d{1,2}(?:\s+\d)?\s*$'), '').trim();
  chunk = chunk.replaceAll(_sectionCode, '').trim();
  chunk = chunk.replaceAll(_rowCode, '').trim();
  chunk = stripScheduleNoiseFromText(chunk);
  if (chunk.isEmpty) return null;
  if (looksLikeRawOcrScheduleLine(chunk)) return null;
  if (RegExp(r'\b(COMLAB|TBA|CISCOLAB|CON\d)', caseSensitive: false)
      .hasMatch(chunk)) {
    return null;
  }
  if (chunk.toUpperCase() == subjectCode.toUpperCase()) return null;
  return chunk;
}

String? _extractInstructor(String line) {
  final section = _sectionCode.firstMatch(line);
  if (section != null) {
    final after = line.substring(section.end);
    final match = _instructorPattern.firstMatch(after);
    if (match != null) {
      return _cleanInstructor(match.group(0)!);
    }
  }
  final matches = _instructorPattern.allMatches(line).toList();
  for (var i = matches.length - 1; i >= 0; i--) {
    final clean = _cleanInstructor(matches[i].group(0)!);
    if (clean != null) return clean;
  }
  return null;
}

String? _cleanInstructor(String raw) {
  final name = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (name.isEmpty) return null;
  if (looksLikeRawOcrScheduleLine(name)) return null;
  if (_roomCode.hasMatch(name)) return null;
  return sanitizeInstructorForDisplay(name);
}

ParsedScheduleDisplay? _buildParsedDisplay({
  required String subjectCode,
  required String? description,
  required String timeText,
  required String afterTime,
  required String roomMatchText,
  required String instructor,
}) {
  final roomMatch = _roomCode.firstMatch(afterTime);
  if (roomMatch == null || roomMatch.group(0) != roomMatchText) return null;

  final roomCode = roomMatch.group(1)!.toUpperCase();
  final dayToken = _extractDayToken(afterTime, roomMatchText);
  if (dayToken == null) return null;

  final timeMatch = _scheduleTime.firstMatch(timeText);
  if (timeMatch == null) return null;

  final bounds = _scheduleBoundsFromMatch(timeMatch);
  final startTimeRaw = _toTimeLabel(bounds.sh, bounds.sm, bounds.startAp);
  final endTimeRaw = _toTimeLabel(bounds.eh, bounds.em, bounds.endAp);

  try {
    expandEslipDayToken(dayToken);
    normalizeTimeString(startTimeRaw);
    normalizeTimeString(endTimeRaw);
  } on FormatException {
    return null;
  }

  final startTime = formatHm(startTimeRaw);
  final endTime = formatHm(endTimeRaw);
  final dayPattern = mapEslipDay(dayToken);
  final title = stripScheduleNoiseFromText(description?.trim() ?? '');

  return ParsedScheduleDisplay(
    startTime: startTime,
    endTime: endTime,
    subjectCode: subjectCode,
    subjectTitle: title,
    subjectName: _buildSubjectNameLine(subjectCode, title.isEmpty ? null : title),
    roomCode: roomCode,
    instructor: instructor,
    dayPattern: dayPattern,
    dayToken: dayToken,
    startTimeRaw: startTimeRaw,
    endTimeRaw: endTimeRaw,
  );
}

EslipClassRow? _parseEslipRow(String line) {
  final collapsed = _collapseRowText(line);
  if (collapsed.length < 12) return null;
  if (!_hasCompleteSchedule(collapsed)) return null;

  final timeMatch = _locateTimeInRow(collapsed);
  if (timeMatch == null) return null;

  final beforeTime = collapsed.substring(0, timeMatch.start);
  final codeMatch = _bestSubjectBeforeTime(beforeTime);
  if (codeMatch == null) return null;

  final subjectCode = codeMatch.group(0)!;
  String? enrollmentCode;
  final enrollMatch = _rowCode.firstMatch(beforeTime);
  if (enrollMatch != null) {
    enrollmentCode =
        enrollMatch.group(0)!.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  final afterCodeFull = collapsed.substring(codeMatch.end);
  final timeOffsetInAfter = timeMatch.start - codeMatch.end;
  final description =
      _extractDescription(afterCodeFull, timeOffsetInAfter, subjectCode);
  final timeText = timeMatch.group(0)!;
  final afterTime = collapsed.substring(timeMatch.end).trim();
  final roomMatch = _locateRoomAfterTime(afterTime);
  if (roomMatch == null) return null;

  final instructor = _extractInstructor(collapsed) ?? '';
  final parsed = _buildParsedDisplay(
    subjectCode: subjectCode,
    description: description,
    timeText: timeText,
    afterTime: afterTime,
    roomMatchText: roomMatch.group(0)!,
    instructor: instructor,
  );

  if (parsed == null) return null;

  return EslipClassRow(
    enrollmentCode: enrollmentCode,
    parsed: parsed,
  );
}

List<String> _splitRowSegments(String text) {
  final starts = _rowCode.allMatches(text).toList();
  if (starts.isEmpty) return [];
  final segments = <String>[];
  for (var i = 0; i < starts.length; i++) {
    final begin = starts[i].start;
    final end = i + 1 < starts.length ? starts[i + 1].start : text.length;
    segments.add(text.substring(begin, end).trim());
  }
  return segments;
}

String _joinContinuationLines(List<String> lines, int startIndex) {
  final buf = StringBuffer(lines[startIndex].trim());
  var i = startIndex;
  while (i + 1 < lines.length) {
    final next = lines[i + 1].trim();
    if (next.isEmpty) {
      i++;
      continue;
    }
    final current = buf.toString();
    final complete =
        _hasCompleteSchedule(current);
    // New enrolment row — stop (schedule must be complete on previous row).
    if (_rowCode.hasMatch(next) && i > startIndex) {
      if (complete) break;
    }
    if (complete && _rowCode.hasMatch(next)) break;
    // Without enrolment codes, each subject line is its own row.
    if (complete &&
        _subjectCode.hasMatch(next) &&
        _hasCompleteSchedule(next)) {
      break;
    }
    buf.write(' ');
    buf.write(next);
    i++;
    if (i - startIndex > 16) break;
  }
  return _collapseRowText(buf.toString());
}

List<String> _segmentsByEnrolmentLines(List<String> lines) {
  final segments = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (!_rowCode.hasMatch(lines[i])) continue;
    final joined = _joinContinuationLines(lines, i);
    if (joined.length >= 12) segments.add(joined);
  }
  return segments;
}

List<String> _segmentsBySubjectCode(String text) {
  final collapsed = _collapseRowText(text);
  final matches = _subjectCode.allMatches(collapsed).toList();
  if (matches.isEmpty) return [];

  final segments = <String>[];
  for (var i = 0; i < matches.length; i++) {
    var start = matches[i].start;
    final before = collapsed.substring(0, start);
    final rowBefore = _rowCode.allMatches(before).toList();
    if (rowBefore.isNotEmpty) {
      final last = rowBefore.last;
      if (start - last.start < 60) start = last.start;
    } else if (i > 0) {
      start = matches[i - 1].end;
    }

    final end =
        i + 1 < matches.length ? matches[i + 1].start : collapsed.length;
    final segment = collapsed.substring(start, end).trim();
    if (segment.length >= 12) segments.add(segment);
  }
  return segments;
}

String _rowKey(EslipClassRow r) {
  final p = r.parsed;
  return '${p.subjectCode}|${p.startTimeRaw}|${p.endTimeRaw}|${p.roomCode}|${p.dayToken}';
}

EslipClassRow _mergeRows(EslipClassRow a, EslipClassRow b) {
  final pa = a.parsed;
  final pb = b.parsed;
  final titleA = pa.subjectTitle.trim();
  final titleB = pb.subjectTitle.trim();
  String pickTitle() {
    if (titleA.isNotEmpty && titleB.isEmpty) return titleA;
    if (titleB.isNotEmpty && titleA.isEmpty) return titleB;
    if (titleA.isNotEmpty && titleB.isNotEmpty) {
      return titleA.length >= titleB.length ? titleA : titleB;
    }
    return '';
  }

  final title = pickTitle();
  final ins = pa.instructor.trim().isNotEmpty
      ? pa.instructor
      : pb.instructor.trim().isNotEmpty
          ? pb.instructor
          : '';

  final merged = ParsedScheduleDisplay(
    startTime: pa.startTime,
    endTime: pa.endTime,
    subjectCode: pa.subjectCode,
    subjectTitle: title,
    subjectName: _buildSubjectNameLine(pa.subjectCode, title),
    roomCode: pa.roomCode,
    instructor: ins,
    dayPattern: pa.dayPattern,
    dayToken: pa.dayToken,
    startTimeRaw: pa.startTimeRaw,
    endTimeRaw: pa.endTimeRaw,
  );

  return EslipClassRow(
    enrollmentCode: a.enrollmentCode ?? b.enrollmentCode,
    parsed: merged,
  );
}

bool _hasCompleteSchedule(String chunk) =>
    _scheduleTime.hasMatch(chunk) && _roomCode.hasMatch(chunk);

List<String> _segmentsByEnrolmentCode(String collapsed) {
  final matches = _rowCode.allMatches(collapsed).toList();
  if (matches.isEmpty) return [];
  final segments = <String>[];
  for (var i = 0; i < matches.length; i++) {
    final begin = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : collapsed.length;
    segments.add(collapsed.substring(begin, end).trim());
  }
  return segments;
}

List<EslipClassRow> _parseScheduleRows(
  String text, {
  required List<String> warnings,
}) {
  final byKey = <String, EslipClassRow>{};

  void absorb(EslipClassRow? row) {
    if (row == null) return;
    final key = _rowKey(row);
    final existing = byKey[key];
    byKey[key] = existing == null ? row : _mergeRows(existing, row);
  }

  final lines = text.split('\n');
  final collapsed = _collapseRowText(text);

  final enrollLineSegments = _segmentsByEnrolmentLines(lines);
  if (kDebugMode) {
    debugPrint('Enrolment rows (multiline): ${enrollLineSegments.length}');
  }
  for (final segment in enrollLineSegments) {
    absorb(_parseEslipRow(segment));
  }

  for (final segment in _segmentsByEnrolmentCode(collapsed)) {
    absorb(_parseEslipRow(segment));
  }

  for (final segment in _splitRowSegments(collapsed)) {
    absorb(_parseEslipRow(segment));
  }

  for (final segment in _segmentsBySubjectCode(text)) {
    if (!_hasCompleteSchedule(segment)) continue;
    absorb(_parseEslipRow(segment));
  }

  for (var i = 0; i < lines.length; i++) {
    if (!_subjectCode.hasMatch(lines[i])) continue;
    final joined = _joinContinuationLines(lines, i);
    if (!_hasCompleteSchedule(joined)) continue;
    absorb(_parseEslipRow(joined));
  }

  for (final segment in enrollLineSegments) {
    final row = _parseEslipRow(segment);
    if (row != null) continue;
    final collapsedSeg = _collapseRowText(segment);
    final code = _bestSubjectBeforeTime(collapsedSeg);
    if (code == null) continue;
    final subjectCode = code.group(0)!;
    if (byKey.values.any((r) => r.parsed.subjectCode == subjectCode)) {
      continue;
    }
    if (_locateTimeInRow(collapsedSeg) == null) {
      warnings.add('No time range on row with $subjectCode');
    } else {
      warnings.add('Could not structure schedule for $subjectCode');
    }
  }

  return byKey.values.toList();
}

EslipParsedProfile _parseProfile(String text) {
  final studentId = RegExp(
    r'ID\s*No\.?\s*:?\s*(\d{5,})',
    caseSensitive: false,
  ).firstMatch(text)?.group(1);

  String? fullName;
  final nameLine = RegExp(
    r'Name\s*:?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (nameLine != null) {
    final rawName = nameLine.group(1)?.trim();
    if (rawName != null && rawName.isNotEmpty) {
      fullName = rawName.split(RegExp(r'\s{2,}')).first.trim();
    }
  }

  final college = RegExp(
    r'College\s*:?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();

  final course = RegExp(
    r'Course\s*:?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();

  final section = RegExp(
    r'Section\s*:?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();

  return EslipParsedProfile(
    studentId: studentId,
    fullName: fullName,
    college: college,
    course: course,
    section: section,
  );
}

List<String> _dedupeWarnings(List<String> warnings) {
  final seen = <String>{};
  final out = <String>[];
  for (final w in warnings) {
    if (seen.add(w)) out.add(w);
  }
  return out;
}

EslipParseOutcome parseEslipOcrText(String raw) {
  final text = preprocessEslipOcrText(raw);
  final warnings = <String>[];

  final classes = _parseScheduleRows(text, warnings: warnings)
    ..sort((a, b) {
      final ea = a.enrollmentCode ?? '';
      final eb = b.enrollmentCode ?? '';
      final c = ea.compareTo(eb);
      if (c != 0) return c;
      return a.parsed.subjectCode.compareTo(b.parsed.subjectCode);
    });

  debugPrint('Total classes parsed: ${classes.length}');
  for (final c in classes) {
    final p = c.parsed;
    debugPrint(
      'Row: ${p.subjectCode} | ${p.startTime} | ${p.dayPattern}',
    );
  }

  final dedupedWarnings = _dedupeWarnings(warnings);

  if (classes.isEmpty) {
    if (!_scheduleTime.hasMatch(text)) {
      dedupedWarnings.insert(
        0,
        'No schedule times found. Try a clearer photo or better lighting.',
      );
    } else if (dedupedWarnings.isEmpty) {
      dedupedWarnings.add(
        'Could not match class rows. Ensure the enrolment table is fully visible.',
      );
    }
  }

  return EslipParseOutcome(
    profile: _parseProfile(text),
    classes: classes,
    warnings: dedupedWarnings,
  );
}

typedef EslipParsedClass = EslipClassRow;
