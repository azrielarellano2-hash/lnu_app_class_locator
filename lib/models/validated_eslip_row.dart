import '../utils/eslip_ocr_parser.dart';
import 'parsed_schedule_display.dart';

/// Per-row confidence from multi-pass OCR validation.
enum RowConfidenceLevel { high, medium, low }

/// One enrolment table row with all LNU e-slip columns + validation metadata.
class ValidatedEslipRow {
  const ValidatedEslipRow({
    this.enrollmentCode,
    required this.subjectCode,
    required this.description,
    required this.units,
    required this.lab,
    required this.scheduleRaw,
    required this.section,
    required this.instructor,
    required this.parsed,
    required this.confidence,
    required this.confidenceScore,
    required this.fieldIssues,
  });

  final String? enrollmentCode;
  final String subjectCode;
  final String description;
  final String units;
  final String lab;
  final String scheduleRaw;
  final String section;
  final String instructor;
  final ParsedScheduleDisplay? parsed;
  final RowConfidenceLevel confidence;
  final double confidenceScore;
  final List<String> fieldIssues;

  bool get needsReview =>
      confidence == RowConfidenceLevel.low ||
      confidence == RowConfidenceLevel.medium;

  ValidatedEslipRow copyWith({
    String? enrollmentCode,
    String? subjectCode,
    String? description,
    String? units,
    String? lab,
    String? scheduleRaw,
    String? section,
    String? instructor,
    ParsedScheduleDisplay? parsed,
    RowConfidenceLevel? confidence,
    double? confidenceScore,
    List<String>? fieldIssues,
  }) {
    return ValidatedEslipRow(
      enrollmentCode: enrollmentCode ?? this.enrollmentCode,
      subjectCode: subjectCode ?? this.subjectCode,
      description: description ?? this.description,
      units: units ?? this.units,
      lab: lab ?? this.lab,
      scheduleRaw: scheduleRaw ?? this.scheduleRaw,
      section: section ?? this.section,
      instructor: instructor ?? this.instructor,
      parsed: parsed ?? this.parsed,
      confidence: confidence ?? this.confidence,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      fieldIssues: fieldIssues ?? this.fieldIssues,
    );
  }

  /// Converts to legacy import row when schedule fields are valid.
  EslipClassRow? toClassRow() {
    final p = parsed;
    if (p == null) return null;
    return EslipClassRow(
      enrollmentCode: enrollmentCode,
      parsed: p,
    );
  }
}
