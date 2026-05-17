import '../utils/formatters.dart';

/// Structured schedule fields for UI cards — never raw OCR text.
class ParsedScheduleDisplay {
  const ParsedScheduleDisplay({
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    required this.subjectTitle,
    required this.subjectName,
    required this.roomCode,
    required this.instructor,
    required this.dayPattern,
    required this.dayToken,
    required this.startTimeRaw,
    required this.endTimeRaw,
  });

  final String startTime;
  final String endTime;

  /// Subject code only (e.g. IT-122).
  final String subjectCode;

  /// Course title without code (e.g. System Analysis and Design).
  final String subjectTitle;

  /// Card line: "IT-122 System Analysis and Design".
  final String subjectName;

  final String roomCode;
  final String instructor;

  /// Readable days (e.g. Monday and Thursday).
  final String dayPattern;

  /// Raw token for storage (MTh, W, TF, SS).
  final String dayToken;
  final String startTimeRaw;
  final String endTimeRaw;

  /// Card line 2 — `IT-122 System Analysis and Design` (code + description).
  String get cardCourseLine => formatCardSubject(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
      );

  /// Description only (no subject code).
  String get cardDescriptionLine => formatCardDescription(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
      );

  /// Card line 1 — `8:00 AM – 9:00 AM`.
  String get cardTimeRange {
    if (startTime.isEmpty || endTime.isEmpty) return '';
    return '$startTime – $endTime';
  }

  /// Card line 4 — `Instructor: M. Gotardo` (empty when unknown).
  String get cardInstructorLine {
    final name = instructor.trim();
    if (name.isEmpty) return '';
    return 'Instructor: $name';
  }
}
