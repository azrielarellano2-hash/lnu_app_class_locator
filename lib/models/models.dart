class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    this.studentId,
    this.fullName,
    this.college,
    this.course,
    this.section,
    this.profilePictureUrl,
    this.timezone = 'Asia/Manila',
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    return UserProfile(
      id: j['id'] as int,
      email: j['email'] as String,
      studentId: j['student_id'] as String?,
      fullName: j['full_name'] as String?,
      college: j['college'] as String?,
      course: j['course'] as String?,
      section: j['section'] as String?,
      profilePictureUrl: j['profile_picture_url'] as String?,
      timezone: j['timezone'] as String? ?? 'Asia/Manila',
    );
  }

  final int id;
  final String email;
  final String? studentId;
  final String? fullName;
  final String? college;
  final String? course;
  final String? section;
  final String? profilePictureUrl;
  final String timezone;
}

class DashboardSummary {
  DashboardSummary({
    required this.subjectCount,
    required this.freeHoursToday,
    required this.dueSoonCount,
    required this.greetingDateLocal,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    return DashboardSummary(
      subjectCount: j['subject_count'] as int,
      freeHoursToday: (j['free_hours_today'] as num).toDouble(),
      dueSoonCount: j['due_soon_count'] as int,
      greetingDateLocal: j['greeting_date_local'] as String,
    );
  }

  final int subjectCount;
  final double freeHoursToday;
  final int dueSoonCount;
  final String greetingDateLocal;
}

class ScheduleSlot {
  ScheduleSlot({
    required this.id,
    this.enrollmentCode,
    required this.subjectName,
    required this.roomCode,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.dayPattern,
    this.subjectTitle,
    this.instructorName,
    this.section,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) {
    return ScheduleSlot(
      id: j['id'] as int,
      enrollmentCode: j['enrollment_code'] as String?,
      subjectName: j['subject_name'] as String,
      roomCode: j['room_code'] as String,
      dayOfWeek: j['day_of_week'] as int,
      startTime: j['start_time'] as String,
      endTime: j['end_time'] as String,
      dayPattern: j['day_pattern'] as String?,
      subjectTitle: j['subject_title'] as String?,
      instructorName: j['instructor_name'] as String?,
      section: j['section'] as String?,
    );
  }

  final int id;
  final String? enrollmentCode;
  final String subjectName;
  final String roomCode;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  /// Raw e-slip day token (MTh, W, TF, SS) for card + filtering.
  final String? dayPattern;
  final String? subjectTitle;
  final String? instructorName;
  final String? section;
}

class WeeklyDay {
  WeeklyDay({
    required this.dateIso,
    required this.weekdayIndex,
    required this.label,
    required this.slots,
  });

  factory WeeklyDay.fromJson(Map<String, dynamic> j) {
    final slots = (j['slots'] as List<dynamic>)
        .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
        .toList();
    return WeeklyDay(
      dateIso: j['date_iso'] as String,
      weekdayIndex: j['weekday_index'] as int,
      label: j['label'] as String,
      slots: slots,
    );
  }

  final String dateIso;
  final int weekdayIndex;
  final String label;
  final List<ScheduleSlot> slots;
}

class WeeklySchedule {
  WeeklySchedule({required this.weekStart, required this.days});

  factory WeeklySchedule.fromJson(Map<String, dynamic> j) {
    final days = (j['days'] as List<dynamic>)
        .map((e) => WeeklyDay.fromJson(e as Map<String, dynamic>))
        .toList();
    return WeeklySchedule(
      weekStart: j['week_start'] as String,
      days: days,
    );
  }

  final String weekStart;
  final List<WeeklyDay> days;
}

class CampusRoom {
  CampusRoom({
    required this.id,
    required this.code,
    required this.building,
    this.floor,
    this.description,
    this.latitude,
    this.longitude,
  });

  factory CampusRoom.fromJson(Map<String, dynamic> j) {
    return CampusRoom(
      id: j['id'] as int,
      code: j['code'] as String,
      building: j['building'] as String,
      floor: j['floor'] as String?,
      description: j['description'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String code;
  final String building;
  final String? floor;
  final String? description;
  final double? latitude;
  final double? longitude;
}

class MyScheduleRoomRow {
  MyScheduleRoomRow({required this.roomCode, this.room});

  factory MyScheduleRoomRow.fromJson(Map<String, dynamic> j) {
    return MyScheduleRoomRow(
      roomCode: j['room_code'] as String,
      room: j['room'] == null
          ? null
          : CampusRoom.fromJson(j['room'] as Map<String, dynamic>),
    );
  }

  final String roomCode;
  final CampusRoom? room;
}

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.dueTime,
    required this.isCompleted,
    required this.reminderType,
  });

  factory Reminder.fromJson(Map<String, dynamic> j) {
    return Reminder(
      id: j['id'] as int,
      title: j['title'] as String,
      description: j['description'] as String?,
      dueDate: j['due_date'] as String,
      dueTime: j['due_time'] as String?,
      isCompleted: j['is_completed'] as bool,
      reminderType: j['reminder_type'] as String,
    );
  }

  final int id;
  final String title;
  final String? description;
  final String dueDate;
  final String? dueTime;
  final bool isCompleted;
  final String reminderType;
}
