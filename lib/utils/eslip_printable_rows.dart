import '../data/day_codes.dart';
import '../models/models.dart';
import '../models/validated_eslip_row.dart';
import '../utils/slot_display_mapper.dart';
import 'formatters.dart';

/// Resolves slip token (MTh, TF, W) for one enrolment row from DB slots.
String resolveEslipDayToken(ScheduleSlot slot, List<ScheduleSlot> allSlots) {
  final code = slot.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (code != null && code.isNotEmpty) {
    final group = allSlots.where(
      (s) =>
          s.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase() == code,
    );
    for (final s in group) {
      final c = canonicalizeEslipDayToken(s.dayPattern ?? '');
      if (c != null) return c;
    }
    final days = group.map((s) => s.dayOfWeek).toSet();
    final inferred = dayTokenFromWeekdayIndices(days);
    if (inferred != null) return inferred;
  }

  final direct = canonicalizeEslipDayToken(slot.dayPattern ?? '');
  if (direct != null) return direct;

  return dayTokenFromWeekdayIndices({slot.dayOfWeek}) ?? '';
}

/// One enrolment row per CODE (MTh/TF classes → one row with TF/MTh in schedule column).
List<ValidatedEslipRow> buildPrintableRowsFromSlots(
  List<ScheduleSlot> slots, {
  String? defaultSection,
}) {
  final byKey = <String, ScheduleSlot>{};

  for (final slot in slots) {
    final code = slot.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final key = (code != null && code.isNotEmpty)
        ? code
        : [
            slot.subjectName.trim(),
            resolveEslipDayToken(slot, slots),
            slot.startTime,
            slot.endTime,
            slot.roomCode.trim(),
          ].join('|');

    if (!byKey.containsKey(key)) {
      byKey[key] = slot;
    }
  }

  final rows = <ValidatedEslipRow>[];
  for (final slot in byKey.values) {
    final dayToken = resolveEslipDayToken(slot, slots);
    final p = parsedScheduleFromSlot(slot, dayToken: dayToken);

    rows.add(
      ValidatedEslipRow(
        enrollmentCode: slot.enrollmentCode,
        subjectCode: p.subjectCode,
        description: p.subjectTitle.isNotEmpty ? p.subjectTitle : p.subjectName,
        units: slot.units?.trim() ?? '',
        lab: slot.lab?.trim() ?? '',
        scheduleRaw: formatEslipScheduleColumn(
          dayPattern: dayToken,
          startTimeRaw: slot.startTime,
          endTimeRaw: slot.endTime,
          roomCode: slot.roomCode,
        ),
        section: slot.section?.trim().isNotEmpty == true
            ? slot.section!
            : (defaultSection ?? ''),
        instructor: p.instructor,
        parsed: p,
        confidence: RowConfidenceLevel.high,
        confidenceScore: 1,
        fieldIssues: const [],
      ),
    );
  }

  sortEslipRowsByCode(rows);
  return rows;
}

void sortEslipRowsByCode(List<ValidatedEslipRow> rows) {
  rows.sort((a, b) {
    final ac = a.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase() ?? '';
    final bc = b.enrollmentCode?.replaceAll(RegExp(r'\s+'), '').toUpperCase() ?? '';
    if (ac.isNotEmpty && bc.isNotEmpty) return ac.compareTo(bc);
    if (ac.isNotEmpty) return -1;
    if (bc.isNotEmpty) return 1;
    return a.subjectCode.compareTo(b.subjectCode);
  });
}

String eslipScheduleCell(ValidatedEslipRow row) {
  final raw = row.scheduleRaw.trim();
  if (raw.isNotEmpty) {
    final m = RegExp(
      r'^(.+?)\s+(MTh|TF|SS|MWF|MW|W|M|T|Th|F|S)\s+(\S+)\s*$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (m != null) {
      final tok = canonicalizeEslipDayToken(m.group(2)!) ?? m.group(2)!;
      return '${m.group(1)} $tok ${m.group(3)}';
    }
    return raw;
  }
  final p = row.parsed;
  if (p == null) return '';
  final token = canonicalizeEslipDayToken(p.dayToken) ??
      canonicalizeEslipDayToken(p.dayPattern) ??
      p.dayToken.trim();
  if (token.isEmpty) return '';
  return formatEslipScheduleColumn(
    dayPattern: token,
    startTimeRaw: p.startTimeRaw,
    endTimeRaw: p.endTimeRaw,
    roomCode: p.roomCode,
  );
}

String eslipLabCell(String lab) {
  final n = int.tryParse(lab.trim());
  if (n == null || n == 0) return '';
  return lab.trim();
}

(int, int) eslipUnitTotals(List<ValidatedEslipRow> rows) {
  var units = 0;
  var lab = 0;
  for (final r in rows) {
    units += int.tryParse(r.units.trim()) ?? 0;
    lab += int.tryParse(r.lab.trim()) ?? 0;
  }
  return (units, lab);
}
