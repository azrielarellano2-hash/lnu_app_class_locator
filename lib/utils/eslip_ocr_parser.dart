import 'package:flutter/foundation.dart';

import '../data/day_codes.dart';
import '../models/parsed_schedule_display.dart';
import '../models/validated_eslip_row.dart';
import 'formatters.dart';
import 'lnu_slip_patterns.dart';
import 'lnu_slip_preprocess.dart' show preprocessEslipOcrText;
import 'schedule_field_parser.dart';

export 'lnu_slip_preprocess.dart' show preprocessEslipOcrText;

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
    this.year,
    this.semester,
    this.academicYear,
    this.formNumber,
    this.enrolmentDate,
  });

  final String? studentId;
  final String? fullName;
  final String? college;
  final String? course;
  final String? section;
  final String? year;
  final String? semester;
  final String? academicYear;
  final String? formNumber;
  final String? enrolmentDate;
}

class EslipParseOutcome {
  const EslipParseOutcome({
    required this.profile,
    required this.classes,
    required this.warnings,
    required this.validatedRows,
    required this.overallConfidencePercent,
    this.headerDetected = false,
  });

  final EslipParsedProfile profile;
  final List<EslipClassRow> classes;
  final List<String> warnings;
  final List<ValidatedEslipRow> validatedRows;
  final double overallConfidencePercent;
  final bool headerDetected;
}

// --- LNU e-slip patterns (see lnu_slip_patterns.dart) ---

final RegExp _subjectCode = lnuSubjectCodePattern;
final RegExp _scheduleTime = lnuScheduleTimePattern;
final RegExp _roomCode = lnuRoomCodePattern;
final RegExp _sectionCode = lnuSectionCodePattern;
final RegExp _rowCode = lnuEnrollmentCodePattern;

final RegExp _instructorPattern = RegExp(
  r'[A-Z]\.\s+(?:[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)',
);

RegExpMatch? _bestSubjectBeforeTime(String beforeTime) {
  final matches = _subjectCode.allMatches(beforeTime).toList();
  if (matches.isEmpty) return null;

  final filtered = matches.where((m) {
    final g = m.group(0)!.trim();
    if (looksLikeSectionCode(g)) return false;
    if (lnuEnrollmentCodePattern.hasMatch(g) && g.length <= 5) return false;
    return true;
  }).toList();

  if (filtered.isEmpty) return null;
  return filtered.reduce(
    (a, b) => a.group(0)!.length >= b.group(0)!.length ? a : b,
  );
}

String _collapseRowText(String text) =>
    text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

({int sh, int sm, int eh, int em, String startAp, String endAp})
    _scheduleBoundsFromMatch(RegExpMatch m) {
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

String _toTimeLabel(int hour12, int minute, String ampm) {
  var h = hour12;
  final ap = ampm.toLowerCase();
  if (ap == 'pm' && h != 12) h += 12;
  if (ap == 'am' && h == 12) h = 0;
  return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String? _extractDayToken(String afterTime, String roomMatchText) {
  final roomStart = afterTime.indexOf(roomMatchText);
  if (roomStart < 0) return null;
  var beforeRoom = afterTime.substring(0, roomStart).trim();
  beforeRoom = beforeRoom.replaceAll(RegExp(r'[.,;]+$'), '').trim();
  return matchScheduleDayToken(beforeRoom);
}

RegExpMatch? _locateRoomAfterTime(String afterTime) {
  return _roomCode.firstMatch(afterTime);
}

/// Schedule time range whose trailing text has a day token and room.
/// When OCR glues units to times (e.g. "3 9-10:30 am"), prefer the last valid match.
RegExpMatch? _locateTimeInRow(String collapsed) {
  RegExpMatch? best;
  for (final m in _scheduleTime.allMatches(collapsed)) {
    final after = collapsed.substring(m.end).trim();
    final room = _locateRoomAfterTime(after);
    if (room == null) continue;
    final day = _extractDayToken(after, room.group(0)!);
    if (day == null) continue;
    best = m;
  }
  return best;
}

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
  if (lnuRoomCodePattern.hasMatch(chunk)) {
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
  final dayPattern = readableDayPattern(dayToken);
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

  final enrollMatches = _rowCode.allMatches(collapsed).toList();
  if (enrollMatches.length > 1) return null;

  final timeMatch = _locateTimeInRow(collapsed);
  if (timeMatch == null) return null;

  final beforeTime = collapsed.substring(0, timeMatch.start);
  final codeMatch = _bestSubjectBeforeTime(beforeTime);
  if (codeMatch == null) return null;

  final subjectCode = normalizeSubjectCodeToken(codeMatch.group(0)!);
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

bool _isSubjectMatchSubsumed(String collapsed, RegExpMatch match) {
  final code = match.group(0)!;
  if (code.length >= 8) return false;
  final start = match.start;
  if (start < 4) return false;
  final prefix = collapsed.substring(0, start);
  return RegExp(r'PROF\s+ED-\s*$', caseSensitive: false).hasMatch(prefix);
}

int _nextEnrollmentCodeStart(String collapsed, int afterIndex) {
  for (final m in _rowCode.allMatches(collapsed)) {
    if (m.start > afterIndex) return m.start;
  }
  return collapsed.length;
}

List<String> _segmentsBySubjectCode(String text) {
  final collapsed = _collapseRowText(text);
  final rawMatches = _subjectCode.allMatches(collapsed).toList();
  final matches = rawMatches
      .where((m) => !_isSubjectMatchSubsumed(collapsed, m))
      .toList();
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

    var end =
        i + 1 < matches.length ? matches[i + 1].start : collapsed.length;
    final enrollEnd = _nextEnrollmentCodeStart(collapsed, start);
    if (enrollEnd < end) end = enrollEnd;
    final segment = collapsed.substring(start, end).trim();
    if (segment.length >= 12) segments.add(segment);
  }
  return segments;
}

String _rowKey(EslipClassRow r) {
  final p = r.parsed;
  final code = r.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase() ?? '';
  return '$code|${p.subjectCode}|${p.startTimeRaw}|${p.endTimeRaw}|${p.roomCode}|${p.dayToken}';
}

/// One enrolment row per CODE (A145, A146, …); prevents duplicate cards from multi-pass OCR.
List<EslipClassRow> _dedupeByEnrollmentCode(Iterable<EslipClassRow> rows) {
  final byCode = <String, EslipClassRow>{};
  for (final row in rows) {
    final code = row.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final key = (code != null && code.isNotEmpty) ? code : _rowKey(row);
    final existing = byCode[key];
    if (existing == null) {
      byCode[key] = row;
      continue;
    }
    if (existing.parsed.subjectCode != row.parsed.subjectCode) {
      byCode[_rowKey(row)] = row;
      continue;
    }
    if (_rowKey(existing) == _rowKey(row)) {
      byCode[key] = _mergeRows(existing, row);
      continue;
    }
    byCode[key] = _mergeRows(existing, row);
  }

  final byFingerprint = <String, EslipClassRow>{};
  for (final row in byCode.values) {
    final fp = _rowKey(row);
    final existing = byFingerprint[fp];
    byFingerprint[fp] =
        existing == null ? row : _mergeRows(existing, row);
  }

  final list = byFingerprint.values.toList();
  list.sort((a, b) {
    final ac = a.enrollmentCode ?? '';
    final bc = b.enrollmentCode ?? '';
    return ac.compareTo(bc);
  });
  return list;
}

String _pickNonEmpty(String a, String b) {
  if (a.trim().isNotEmpty) return a;
  return b;
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
    startTime: _pickNonEmpty(pa.startTime, pb.startTime),
    endTime: _pickNonEmpty(pa.endTime, pb.endTime),
    subjectCode: pa.subjectCode,
    subjectTitle: title,
    subjectName: _buildSubjectNameLine(pa.subjectCode, title),
    roomCode: _pickNonEmpty(pa.roomCode, pb.roomCode),
    instructor: ins,
    dayPattern: _pickNonEmpty(pa.dayPattern, pb.dayPattern),
    dayToken: _pickNonEmpty(pa.dayToken, pb.dayToken),
    startTimeRaw: _pickNonEmpty(pa.startTimeRaw, pb.startTimeRaw),
    endTimeRaw: _pickNonEmpty(pa.endTimeRaw, pb.endTimeRaw),
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

  bool isSameClass(EslipClassRow a, EslipClassRow b) {
    final pa = a.parsed;
    final pb = b.parsed;
    return pa.subjectCode == pb.subjectCode &&
        pa.startTimeRaw == pb.startTimeRaw &&
        pa.endTimeRaw == pb.endTimeRaw &&
        pa.roomCode == pb.roomCode &&
        pa.dayToken == pb.dayToken;
  }

  bool alreadyParsed(EslipClassRow row) {
    final code = row.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (code != null && code.isNotEmpty && byKey.containsKey(code)) {
      return true;
    }
    for (final existing in byKey.values) {
      if (isSameClass(existing, row)) return true;
    }
    return false;
  }

  void absorb(EslipClassRow? row) {
    if (row == null || alreadyParsed(row)) return;
    final code = row.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final key = (code != null && code.isNotEmpty) ? code : _rowKey(row);
    final existing = byKey[key];
    byKey[key] = existing == null ? row : _mergeRows(existing, row);
  }

  void absorbSegment(String segment) => absorb(_parseEslipRow(segment));

  final lines = text.split('\n');
  final collapsed = _collapseRowText(text);

  final enrollLineSegments = _segmentsByEnrolmentLines(lines);
  final enrollCodeSegments = _segmentsByEnrolmentCode(collapsed);
  final hasEnrollmentRows = enrollLineSegments.isNotEmpty ||
      enrollCodeSegments.isNotEmpty;
  final hasStrongEnrollRows = enrollLineSegments.length >= 3 ||
      enrollCodeSegments.length >= 3;

  if (kDebugMode) {
    debugPrint('Enrolment rows (multiline): ${enrollLineSegments.length}');
  }

  for (final segment in enrollLineSegments) {
    absorbSegment(segment);
  }

  for (final segment in enrollCodeSegments) {
    absorbSegment(segment);
  }

  if (!hasStrongEnrollRows) {
    for (final segment in _splitRowSegments(collapsed)) {
      absorbSegment(segment);
    }

    if (!hasEnrollmentRows) {
      for (final segment in _segmentsBySubjectCode(text)) {
        if (!_hasCompleteSchedule(segment)) continue;
        absorbSegment(segment);
      }
    }

    for (var i = 0; i < lines.length; i++) {
      if (!_subjectCode.hasMatch(lines[i])) continue;
      final joined = _joinContinuationLines(lines, i);
      if (!_hasCompleteSchedule(joined)) continue;
      if (_rowCode.allMatches(joined).length > 1) continue;
      absorbSegment(joined);
    }
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

  return _dedupeByEnrollmentCode(byKey.values);
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

  final semester = RegExp(
    r'(First|Second)\s+Semester\s+(\d{4}-\d{4})',
    caseSensitive: false,
  ).firstMatch(text);
  final formNo = RegExp(
    r'Form\s*No\.?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();
  final year = RegExp(
    r'Year\s*:?\s*([^\n,]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();
  final date = RegExp(
    r'Date\s*:?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();

  return EslipParsedProfile(
    studentId: studentId,
    fullName: fullName,
    college: college,
    course: course,
    section: section,
    year: year,
    semester: semester?.group(1),
    academicYear: semester?.group(2),
    formNumber: formNo,
    enrolmentDate: date,
  );
}

// --- Multi-pass validation (Pass 1–4) ---

final RegExp _headerRowPattern = RegExp(
  r'CODE\s+SUBJECT\s+DESCRIPTION',
  caseSensitive: false,
);

bool detectEslipTableHeader(String text) => _headerRowPattern.hasMatch(text);

/// Keywords and subject-code density for enrolment / assessment forms.
bool isEslipDocument(String raw) {
  final normalized = raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

  const keywords = [
    'ENROLMENT AND ASSESSMENT',
    'ENROLLMENT AND ASSESSMENT',
    'UNITS LAB',
    'SCHEDULE AND ROOM',
    'TOTAL UNITS',
    'ASSESSMENT DETAILS',
    'TUITION FEE',
    'LEYTE NORMAL UNIVERSITY',
    'CODE SUBJECT DESCRIPTION',
  ];

  var keywordHits = 0;
  for (final k in keywords) {
    if (normalized.contains(k)) keywordHits++;
  }

  if (detectEslipTableHeader(raw)) keywordHits += 2;

  final subjectMatches = lnuSubjectCodePattern.allMatches(normalized).length;

  final enrollCodes = _rowCode.allMatches(raw).length;

  return keywordHits >= 2 ||
      subjectMatches >= 3 ||
      (enrollCodes >= 3 && subjectMatches >= 2);
}

({String units, String lab}) _extractUnitsAndLab(
  String afterCode,
  int timeStart,
) {
  if (timeStart <= 0) return (units: '', lab: '');
  var chunk = afterCode.substring(0, timeStart).trim();
  chunk = chunk.replaceAll(RegExp(r'\s+'), ' ');
  final m = RegExp(r'^(.+?)\s+(\d{1,2})(?:\s+(\d))?\s*$').firstMatch(chunk);
  if (m == null) {
    final tail = RegExp(r'\s+(\d{1,2})(?:\s+(\d))?\s*$').firstMatch(chunk);
    if (tail == null) return (units: '', lab: '');
    return (
      units: tail.group(1) ?? '',
      lab: tail.group(2) ?? '',
    );
  }
  return (
    units: m.group(2) ?? '',
    lab: m.group(3) ?? '',
  );
}

String _buildScheduleRaw(String collapsed) {
  final timeMatch = _locateTimeInRow(collapsed);
  if (timeMatch == null) return '';
  final afterTime = collapsed.substring(timeMatch.end).trim();
  final roomMatch = _locateRoomAfterTime(afterTime);
  if (roomMatch == null) return timeMatch.group(0) ?? '';
  final dayToken = _extractDayToken(afterTime, roomMatch.group(0)!);
  final dayPart = dayToken != null ? ' $dayToken' : '';
  return '${timeMatch.group(0)!}$dayPart ${roomMatch.group(0)!}'.trim();
}

String? _extractSectionFromRow(String collapsed) {
  final m = _sectionCode.firstMatch(collapsed);
  return m?.group(0);
}

RowConfidenceLevel _confidenceLevel(double score) {
  if (score >= 0.85) return RowConfidenceLevel.high;
  if (score >= 0.55) return RowConfidenceLevel.medium;
  return RowConfidenceLevel.low;
}

ValidatedEslipRow _validateParsedRow(String collapsed, EslipClassRow row) {
  final p = row.parsed;
  final issues = <String>[];
  var score = 1.0;

  final timeMatch = _locateTimeInRow(collapsed);
  final beforeTime = timeMatch != null
      ? collapsed.substring(0, timeMatch.start)
      : collapsed;
  final codeMatch = _bestSubjectBeforeTime(beforeTime);
  final afterCode = codeMatch != null
      ? collapsed.substring(codeMatch.end)
      : '';
  final timeOffset = timeMatch != null && codeMatch != null
      ? timeMatch.start - codeMatch.end
      : 0;

  final description = _extractDescription(
        afterCode,
        timeOffset,
        p.subjectCode,
      ) ??
      p.subjectTitle;
  final unitsLab = _extractUnitsAndLab(afterCode, timeOffset);
  final scheduleRaw = _buildScheduleRaw(collapsed);
  final section = _extractSectionFromRow(collapsed) ?? '';

  if (p.subjectCode.trim().isEmpty) {
    issues.add('Missing subject code');
    score -= 0.35;
  }
  if (description.trim().isEmpty) {
    issues.add('Missing description');
    score -= 0.15;
  }
  if (scheduleRaw.isEmpty) {
    issues.add('Missing schedule');
    score -= 0.35;
  }
  if (p.roomCode.trim().isEmpty) {
    issues.add('Missing room');
    score -= 0.2;
  }
  if (p.instructor.trim().isEmpty) {
    issues.add('Missing instructor');
    score -= 0.1;
  }
  if (section.isEmpty) {
    issues.add('Missing section');
    score -= 0.05;
  }

  final fieldParse = scheduleRaw.isNotEmpty
      ? parseScheduleField(scheduleRaw, log: false)
      : null;
  if (fieldParse == null && scheduleRaw.isNotEmpty) {
    issues.add('Could not parse schedule time/days/room');
    score -= 0.25;
  }

  score = score.clamp(0.0, 1.0);
  final level = _confidenceLevel(score);

  return ValidatedEslipRow(
    enrollmentCode: row.enrollmentCode,
    subjectCode: p.subjectCode,
    description: description.trim(),
    units: unitsLab.units,
    lab: unitsLab.lab,
    scheduleRaw: scheduleRaw,
    section: section,
    instructor: p.instructor,
    parsed: p,
    confidence: level,
    confidenceScore: score,
    fieldIssues: issues,
  );
}

String? _segmentForClass(String text, EslipClassRow row) {
  final collapsed = _collapseRowText(text);
  final code = row.enrollmentCode?.replaceAll(RegExp(r'\s+'), '');
  final segments = <String>{
    ..._segmentsByEnrolmentLines(text.split('\n')),
    ..._segmentsByEnrolmentCode(collapsed),
    ..._splitRowSegments(collapsed),
  }.where((s) => s.length >= 12);

  if (code != null && code.isNotEmpty) {
    for (final s in segments) {
      if (s.replaceAll(RegExp(r'\s+'), '').toUpperCase().contains(code.toUpperCase())) {
        return s;
      }
    }
  }
  for (final s in segments) {
    if (s.contains(row.parsed.subjectCode)) return s;
  }
  return null;
}

List<ValidatedEslipRow> _buildValidatedRows(
  String text,
  List<EslipClassRow> classes,
  List<String> warnings,
) {
  return classes
      .map((row) => _validateParsedRow(_segmentForClass(text, row) ?? '', row))
      .toList();
}

double _overallConfidence(List<ValidatedEslipRow> rows) {
  if (rows.isEmpty) return 0;
  final sum = rows.fold<double>(0, (a, r) => a + r.confidenceScore);
  return (sum / rows.length * 100).roundToDouble();
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

  final headerDetected = detectEslipTableHeader(text);
  if (!headerDetected) {
    dedupedWarnings.insert(
      0,
      'Table header not detected — verify column alignment in the photo.',
    );
  }

  final validatedRows = _buildValidatedRows(text, classes, dedupedWarnings);
  final overallConfidence = _overallConfidence(validatedRows);

  return EslipParseOutcome(
    profile: _parseProfile(text),
    classes: classes,
    warnings: _dedupeWarnings(dedupedWarnings),
    validatedRows: validatedRows,
    overallConfidencePercent: overallConfidence,
    headerDetected: headerDetected,
  );
}

typedef EslipParsedClass = EslipClassRow;
