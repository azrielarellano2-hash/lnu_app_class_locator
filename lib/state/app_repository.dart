import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/day_codes.dart';
import '../data/vacant_calc.dart';
import '../models/models.dart';
import '../models/parsed_schedule_display.dart';
import '../models/schedule_item.dart';
import '../models/student_profile.dart';
import '../models/teacher.dart';
import '../models/validated_eslip_row.dart';
import '../utils/eslip_ocr_parser.dart';
import '../utils/formatters.dart';
import '../utils/schedule_day_filter.dart';
import '../utils/schedule_field_parser.dart' show parseScheduleField;
import '../utils/slot_display_mapper.dart';

const _kOfflineEmail = 'offline@lnu.smartpath';

/// Local SQLite storage — no network; app works fully offline.
class AppRepository extends ChangeNotifier {
  Database? _db;
  UserProfile? _profileCache;

  Future<void> init() async {
    _db = await AppDatabase.instance.database;
    _profileCache = await _loadProfile();
    notifyListeners();
  }

  Database get _requireDb {
    final d = _db;
    if (d == null) {
      throw StateError('AppRepository not initialized. Call init() first.');
    }
    return d;
  }

  UserProfile? get profile => _profileCache;

  Future<UserProfile> _loadProfile() async {
    final rows = await _requireDb.query('profile', where: 'id = ?', whereArgs: [1]);
    final row = rows.isEmpty ? <String, dynamic>{} : rows.first;
    return UserProfile(
      id: 1,
      email: _kOfflineEmail,
      studentId: row['student_id'] as String?,
      fullName: row['full_name'] as String?,
      college: row['college'] as String?,
      course: row['course'] as String?,
      section: row['section'] as String?,
      timezone: 'Asia/Manila',
    );
  }

  Future<void> saveProfile({
    String? studentId,
    String? fullName,
    String? college,
    String? course,
    String? section,
  }) async {
    await _requireDb.update(
      'profile',
      {
        'student_id': studentId,
        'full_name': fullName,
        'college': college,
        'course': course,
        'section': section,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
    _profileCache = await _loadProfile();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _profileCache = await _loadProfile();
    notifyListeners();
  }

  Future<DashboardSummary> dashboardSummary() async {
    final slots = await _allSlots();
    final now = DateTime.now();
    final todayWd = now.weekday - DateTime.monday;
    final free = vacantHoursBetweenClasses(slots, todayWd);
    final subjects = distinctSubjectCount(slots);

    final reminders = await _allReminders();
    final cutoff = now.add(const Duration(hours: 48));
    var dueSoon = 0;
    for (final r in reminders) {
      if (r.isCompleted) continue;
      final due = _reminderDateTime(r);
      if (!due.isBefore(now) && !due.isAfter(cutoff)) {
        dueSoon++;
      }
    }

    final greeting = DateFormat('EEEE, MMMM d, y').format(now);
    return DashboardSummary(
      subjectCount: subjects,
      freeHoursToday: free,
      dueSoonCount: dueSoon,
      greetingDateLocal: greeting,
    );
  }

  DateTime _reminderDateTime(Reminder r) {
    final dp = r.dueDate.split('-');
    final y = int.parse(dp[0]);
    final mo = int.parse(dp[1]);
    final da = int.parse(dp[2]);
    if (r.dueTime == null || r.dueTime!.isEmpty) {
      return DateTime(y, mo, da, 23, 59);
    }
    final p = r.dueTime!.split(':');
    return DateTime(y, mo, da, int.parse(p[0]), int.parse(p[1]));
  }

  Future<List<ScheduleSlot>> _allSlots() async {
    final rows = await _requireDb.query('schedule_slots');
    return rows.map(_slotFromRow).toList();
  }

  ScheduleSlot _slotFromRow(Map<String, Object?> row) {
    return ScheduleSlot(
      id: row['id'] as int,
      enrollmentCode: row['enrollment_code'] as String?,
      subjectName: row['subject_name'] as String,
      roomCode: row['room_code'] as String,
      dayOfWeek: row['day_of_week'] as int,
      startTime: row['start_time'] as String,
      endTime: row['end_time'] as String,
      dayPattern: row['day_pattern'] as String?,
      subjectTitle: row['subject_title'] as String?,
      instructorName: row['instructor_name'] as String?,
      section: row['section'] as String?,
      units: row['units'] as String?,
      lab: row['lab'] as String?,
    );
  }

  Future<List<ScheduleSlot>> allScheduleSlots() => _allSlots();

  Future<List<ScheduleSlot>> scheduleToday() async {
    final wd = DateTime.now().weekday - DateTime.monday;
    final all = await _allSlots();
    return filterSlotsForWeekday(all, wd);
  }

  /// Every unique class block from the saved schedule (e.g. 12 e-slip rows).
  Future<List<ParsedScheduleDisplay>> allDistinctClasses() async {
    final slots = await _allSlots();
    return distinctClassBlocksFromSlots(slots);
  }

  static const _labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  Future<WeeklySchedule> scheduleWeekly({String? weekStart}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    DateTime anchor;
    if (weekStart != null && weekStart.isNotEmpty) {
      anchor = DateTime.parse(weekStart);
    } else {
      anchor = mondayOfWeekContaining(todayDate);
    }

    final slots = await _allSlots();
    final days = <WeeklyDay>[];
    for (var i = 0; i < 7; i++) {
      final d = anchor.add(Duration(days: i));
      final wd = d.weekday - DateTime.monday;
      final daySlots = filterSlotsForWeekday(slots, wd);
      days.add(
        WeeklyDay(
          dateIso: isoDate(d),
          weekdayIndex: wd,
          label: _labels[wd],
          slots: daySlots,
        ),
      );
    }
    return WeeklySchedule(weekStart: isoDate(anchor), days: days);
  }

  Future<void> resetEslip() async {
    final db = _requireDb;
    await db.delete('schedule_slots');
    await db.update(
      'profile',
      {
        'student_id': null,
        'full_name': null,
        'college': null,
        'course': null,
        'section': null,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
    _profileCache = await _loadProfile();
    notifyListeners();
  }

  /// Removes all schedule rows; profile is unchanged. Use before replacing schedule from a new e-slip.
  Future<void> clearScheduleSlots() async {
    await _requireDb.delete('schedule_slots');
    notifyListeners();
  }

  Future<List<MyScheduleRoomRow>> roomsFromSchedule() async {
    final rc = await _requireDb.rawQuery(
      'SELECT DISTINCT room_code FROM schedule_slots ORDER BY room_code',
    );
    final out = <MyScheduleRoomRow>[];
    for (final row in rc) {
      final code = row['room_code'] as String;
      final rooms = await _requireDb.query(
        'campus_rooms',
        where: 'code = ?',
        whereArgs: [code],
      );
      final campus = rooms.isEmpty
          ? null
          : CampusRoom(
              id: rooms.first['id'] as int,
              code: rooms.first['code'] as String,
              building: rooms.first['building'] as String,
              floor: rooms.first['floor'] as String?,
              description: rooms.first['description'] as String?,
              latitude: (rooms.first['latitude'] as num?)?.toDouble(),
              longitude: (rooms.first['longitude'] as num?)?.toDouble(),
            );
      out.add(MyScheduleRoomRow(roomCode: code, room: campus));
    }
    return out;
  }

  Future<List<CampusRoom>> searchRooms({String? q}) async {
    List<Map<String, Object?>> rows;
    if (q == null || q.trim().isEmpty) {
      rows = await _requireDb.query('campus_rooms', orderBy: 'code');
    } else {
      final term = '%${q.trim()}%';
      rows = await _requireDb.query(
        'campus_rooms',
        where: 'code LIKE ? OR building LIKE ?',
        whereArgs: [term, term],
        orderBy: 'code',
      );
    }
    return rows
        .map(
          (r) => CampusRoom.fromJson({
            'id': r['id'] as int,
            'code': r['code'] as String,
            'building': r['building'] as String,
            'floor': r['floor'] as String?,
            'description': r['description'] as String?,
            'latitude': r['latitude'] as num?,
            'longitude': r['longitude'] as num?,
          }),
        )
        .toList();
  }

  Future<List<Reminder>> listReminders() async {
    final rows = await _requireDb.query('reminders', orderBy: 'due_date ASC, due_time ASC');
    return rows.map(_reminderFromRow).toList();
  }

  Reminder _reminderFromRow(Map<String, Object?> row) {
    return Reminder(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      dueDate: row['due_date'] as String,
      dueTime: row['due_time'] as String?,
      isCompleted: (row['is_completed'] as int) != 0,
      reminderType: row['reminder_type'] as String,
    );
  }

  Future<List<Reminder>> _allReminders() async {
    final rows = await _requireDb.query('reminders');
    return rows.map(_reminderFromRow).toList();
  }

  Future<Reminder> createReminder(Map<String, dynamic> body) async {
    final id = await _requireDb.insert('reminders', {
      'title': body['title'] as String,
      'description': body['description'] as String?,
      'due_date': body['due_date'] as String,
      'due_time': body['due_time'] as String?,
      'is_completed': 0,
      'reminder_type': (body['reminder_type'] as String?) ?? 'assignment',
    });
    notifyListeners();
    final rows = await _requireDb.query('reminders', where: 'id = ?', whereArgs: [id]);
    return _reminderFromRow(rows.first);
  }

  Future<Reminder> updateReminder(int id, Map<String, dynamic> patch) async {
    final data = <String, Object?>{};
    if (patch.containsKey('title')) data['title'] = patch['title'] as String;
    if (patch.containsKey('description')) data['description'] = patch['description'] as String?;
    if (patch.containsKey('due_date')) data['due_date'] = patch['due_date'] as String;
    if (patch.containsKey('due_time')) data['due_time'] = patch['due_time'] as String?;
    if (patch.containsKey('is_completed')) {
      data['is_completed'] = (patch['is_completed'] as bool) ? 1 : 0;
    }
    if (patch.containsKey('reminder_type')) {
      data['reminder_type'] = patch['reminder_type'] as String;
    }
    if (data.isNotEmpty) {
      await _requireDb.update('reminders', data, where: 'id = ?', whereArgs: [id]);
    }
    notifyListeners();
    final rows = await _requireDb.query('reminders', where: 'id = ?', whereArgs: [id]);
    return _reminderFromRow(rows.first);
  }

  Future<void> deleteReminder(int id) async {
    await _requireDb.delete('reminders', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  /// Insert schedule rows from LNU day pattern + times (e.g. MTh 8:00–9:30).
  Future<int> addScheduleClass({
    String? enrollmentCode,
    required String subjectName,
    required String roomCode,
    required String dayPattern,
    required String startTimeRaw,
    required String endTimeRaw,
    String? instructorName,
    String? subjectTitle,
    String? section,
    String? units,
    String? lab,
  }) async {
    final days = expandEslipDayToken(dayPattern);
    final start = normalizeTimeString(startTimeRaw);
    final end = normalizeTimeString(endTimeRaw);
    final db = _requireDb;
    final ins = sanitizeInstructorForDisplay(instructorName);
    var subTitle = subjectTitle?.trim();
    if (subTitle != null && looksLikeRawOcrScheduleLine(subTitle)) {
      subTitle = null;
    }
    var code = subjectName.trim();
    if (code.toUpperCase() == 'CLASS' &&
        subTitle != null &&
        subTitle.isNotEmpty) {
      final m = RegExp(
        r'^([A-Za-z]{2,})\s*[- ]?\s*(\d{1,}[A-Za-z]?)',
      ).firstMatch(subTitle);
      if (m != null) {
        code = '${m.group(1)}-${m.group(2)}';
      }
    }
    final ec = enrollmentCode?.trim();
    final sec = section?.trim();
    var n = 0;
    final dayToken = dayPattern.trim();
    for (final d in days) {
      await db.insert('schedule_slots', {
        'enrollment_code': ec != null && ec.isNotEmpty ? ec : null,
        'subject_name': code,
        'room_code': roomCode.trim(),
        'day_of_week': d,
        'start_time': start,
        'end_time': end,
        'day_pattern': dayToken.isNotEmpty ? dayToken : null,
        'instructor_name': ins != null && ins.isNotEmpty ? ins : null,
        'subject_title': subTitle != null && subTitle.isNotEmpty ? subTitle : null,
        'section': sec != null && sec.isNotEmpty ? sec : null,
        'units': units?.trim().isNotEmpty == true ? units!.trim() : null,
        'lab': lab?.trim().isNotEmpty == true ? lab!.trim() : null,
      });
      n++;
    }
    notifyListeners();
    return n;
  }

  /// Imports multiple rows from e-slip OCR (each row may expand to several weekday slots).
  static const _defaultStudentId = 'default';
  final _uuid = const Uuid();

  String _teacherIdFromName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  Future<Teacher?> getTeacherByName(String name) async {
    final id = _teacherIdFromName(name);
    final rows = await _requireDb.query('teachers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Teacher.fromRow(rows.first);
  }

  Future<Teacher> upsertTeacherFromInstructor(
    String instructorName, {
    String? subjectCode,
  }) async {
    final trimmed = instructorName.trim();
    final id = _teacherIdFromName(trimmed);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getTeacherByName(trimmed);
    var subjects = existing?.subjectsTaught ?? <String>[];
    if (subjectCode != null &&
        subjectCode.isNotEmpty &&
        !subjects.contains(subjectCode)) {
      subjects = [...subjects, subjectCode];
    }
    final teacher = Teacher(
      id: id,
      name: trimmed,
      position: existing?.position,
      department: existing?.department,
      college: existing?.college ?? _profileCache?.college,
      email: existing?.email,
      contactNumber: existing?.contactNumber,
      profilePhotoPath: existing?.profilePhotoPath,
      bio: existing?.bio,
      yearsOfService: existing?.yearsOfService,
      officeHours: existing?.officeHours,
      officeRoom: existing?.officeRoom,
      subjectsTaught: subjects,
      socialLinks: existing?.socialLinks ?? {},
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _requireDb.insert(
      'teachers',
      teacher.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
    return teacher;
  }

  Future<Teacher> updateTeacher(Teacher teacher) async {
    final updated = teacher.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _requireDb.update(
      'teachers',
      updated.toRow(),
      where: 'id = ?',
      whereArgs: [teacher.id],
    );
    notifyListeners();
    return updated;
  }

  Future<List<Teacher>> listTeachers() async {
    final rows = await _requireDb.query('teachers', orderBy: 'name ASC');
    return rows.map(Teacher.fromRow).toList();
  }

  Future<StudentProfile> getStudentProfile() async {
    final rows = await _requireDb.query(
      'students',
      where: 'id = ?',
      whereArgs: [_defaultStudentId],
    );
    if (rows.isEmpty) {
      await _requireDb.insert('students', {'id': _defaultStudentId});
      return const StudentProfile(id: _defaultStudentId);
    }
    return StudentProfile.fromRow(rows.first);
  }

  Future<StudentProfile> saveStudentProfile(StudentProfile profile) async {
    await _requireDb.insert(
      'students',
      profile.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
    return profile;
  }

  Future<StudentProfile> syncStudentFromEslip(EslipParsedProfile p) async {
    final current = await getStudentProfile();
    final merged = current.copyWith(
      idNumber: p.studentId ?? current.idNumber,
      name: p.fullName ?? current.name,
      college: p.college ?? current.college,
      course: p.course ?? current.course,
      section: p.section ?? current.section,
      year: p.year ?? current.year,
      semester: p.semester ?? current.semester,
      academicYear: p.academicYear ?? current.academicYear,
      formNumber: p.formNumber ?? current.formNumber,
    );
    return saveStudentProfile(merged);
  }

  Future<List<ScheduleItem>> listScheduleItemsForSubject(String subjectId) async {
    final rows = await _requireDb.query(
      'schedule_items',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'due_date ASC, due_time ASC',
    );
    return rows.map(ScheduleItem.fromRow).toList();
  }

  Future<List<ScheduleItem>> listAllScheduleItems() async {
    final rows = await _requireDb.query(
      'schedule_items',
      orderBy: 'due_date ASC, due_time ASC',
    );
    return rows.map(ScheduleItem.fromRow).toList();
  }

  Future<ScheduleItem> saveScheduleItem(ScheduleItem item) async {
    await _requireDb.insert(
      'schedule_items',
      item.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
    return item;
  }

  Future<void> deleteScheduleItem(String id) async {
    await _requireDb.delete('schedule_items', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  ScheduleItem newScheduleItem({
    required String subjectId,
    required ScheduleItemType type,
    required String title,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ScheduleItem(
      id: _uuid.v4(),
      subjectId: subjectId,
      type: type,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<int> importValidatedEslipRows(List<ValidatedEslipRow> rows) async {
    var imported = 0;
    for (final v in rows) {
      final rebuilt = _rebuildClassRowFromValidated(v);
      if (rebuilt == null) continue;
      final p = rebuilt.parsed;
      try {
        await addScheduleClass(
          enrollmentCode: rebuilt.enrollmentCode,
          subjectName: p.subjectCode,
          roomCode: p.roomCode,
          dayPattern: p.dayToken,
          startTimeRaw: p.startTimeRaw,
          endTimeRaw: p.endTimeRaw,
          instructorName: p.instructor.isNotEmpty ? p.instructor : null,
          subjectTitle: p.subjectTitle.isNotEmpty ? p.subjectTitle : null,
          section: v.section.isNotEmpty ? v.section : null,
          units: v.units.isNotEmpty ? v.units : null,
          lab: v.lab.isNotEmpty ? v.lab : null,
        );
        imported++;
      } on FormatException catch (e) {
        debugPrint('Skipped ${p.subjectCode}: ${e.message}');
      }
    }
    return imported;
  }

  EslipClassRow? _rebuildClassRowFromValidated(ValidatedEslipRow v) {
    final field = v.scheduleRaw.isNotEmpty
        ? parseScheduleField(v.scheduleRaw, log: false)
        : null;
    if (field == null && v.parsed == null) return null;

    final f = field;
    final p = v.parsed;
    final parsed = ParsedScheduleDisplay(
      startTime: f?.startTime ?? p!.startTime,
      endTime: f?.endTime ?? p!.endTime,
      subjectCode: v.subjectCode.isNotEmpty ? v.subjectCode : p!.subjectCode,
      subjectTitle: v.description,
      subjectName: formatCardSubject(
        subjectCode: v.subjectCode,
        subjectTitle: v.description,
      ),
      roomCode: f?.roomCode ?? p!.roomCode,
      instructor: v.instructor,
      dayPattern: f?.dayPattern ?? p!.dayPattern,
      dayToken: f?.dayToken ?? p!.dayToken,
      startTimeRaw: f?.startTimeRaw ?? p!.startTimeRaw,
      endTimeRaw: f?.endTimeRaw ?? p!.endTimeRaw,
    );

    return EslipClassRow(
      enrollmentCode: v.enrollmentCode,
      parsed: parsed,
    );
  }

  Future<int> confirmEslipImport({
    required List<ValidatedEslipRow> rows,
    required EslipParsedProfile profile,
    bool replaceSchedule = true,
  }) async {
    if (replaceSchedule) await clearScheduleSlots();

    await saveProfile(
      studentId: profile.studentId,
      fullName: profile.fullName,
      college: profile.college,
      course: profile.course,
      section: profile.section,
    );
    await syncStudentFromEslip(profile);

    final imported = await importValidatedEslipRows(rows);
    for (final v in rows) {
      final ins = v.instructor.trim();
      if (ins.isNotEmpty) {
        await upsertTeacherFromInstructor(ins, subjectCode: v.subjectCode);
      }
    }
    return imported;
  }

  /// Saves parsed OCR classes directly (one row per enrolment CODE, no review duplicates).
  Future<int> confirmEslipImportFromOutcome(
    EslipParseOutcome outcome, {
    bool replaceSchedule = true,
  }) async {
    if (replaceSchedule) await clearScheduleSlots();

    await saveProfile(
      studentId: outcome.profile.studentId,
      fullName: outcome.profile.fullName,
      college: outcome.profile.college,
      course: outcome.profile.course,
      section: outcome.profile.section,
    );
    await syncStudentFromEslip(outcome.profile);

    final imported = await importValidatedEslipRows(outcome.validatedRows);
    for (final v in outcome.validatedRows) {
      final ins = v.instructor.trim();
      if (ins.isNotEmpty) {
        await upsertTeacherFromInstructor(ins, subjectCode: v.subjectCode);
      }
    }
    return imported;
  }

  Future<Map<String, dynamic>> studentStats() async {
    final slots = await _allSlots();
    final classes = distinctClassBlocksFromSlots(slots);
    var labCount = 0;
    var totalUnits = 0;
    for (final c in classes) {
      if (c.subjectCode.toUpperCase().endsWith('L')) labCount++;
      totalUnits += 2;
    }
    return {
      'subjectCount': classes.length,
      'labCount': labCount,
      'totalUnits': totalUnits,
    };
  }

  Future<int> importEslipParsedClasses(List<EslipClassRow> rows) async {
    debugPrint('Total classes parsed: ${rows.length}');
    var blocks = 0;
    var imported = 0;
    for (final r in rows) {
      final p = r.parsed;
      try {
        blocks += await addScheduleClass(
          enrollmentCode: r.enrollmentCode,
          subjectName: p.subjectCode,
          roomCode: p.roomCode,
          dayPattern: p.dayToken,
          startTimeRaw: p.startTimeRaw,
          endTimeRaw: p.endTimeRaw,
          instructorName: p.instructor.isNotEmpty ? p.instructor : null,
          subjectTitle: p.subjectTitle.isNotEmpty ? p.subjectTitle : null,
        );
        imported++;
        debugPrint(
          'Imported: ${p.subjectCode} | ${p.startTime} | ${p.dayPattern}',
        );
      } on FormatException catch (e) {
        debugPrint('Skipped ${p.subjectCode}: ${e.message}');
      }
    }
    debugPrint('Saved $imported classes ($blocks weekly slots) to database');
    return imported;
  }
}
