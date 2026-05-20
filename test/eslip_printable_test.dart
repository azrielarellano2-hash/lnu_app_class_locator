import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/models/parsed_schedule_display.dart';
import 'package:lnu_app_class_locator/models/validated_eslip_row.dart';
import 'package:lnu_app_class_locator/screens/eslip_printable_view.dart';
import 'package:lnu_app_class_locator/theme/app_theme.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';

void main() {
  testWidgets('EslipPrintableView renders preview content', (tester) async {
    final profile = EslipParsedProfile(
      studentId: '2300289',
      fullName: 'Test Student',
      college: 'CCIS',
      course: 'BSIT',
    );
    final parsed = ParsedScheduleDisplay(
      startTime: '8:00 AM',
      endTime: '9:00 AM',
      subjectCode: 'IT-122',
      subjectTitle: 'System Analysis',
      subjectName: 'IT-122 System Analysis',
      roomCode: 'COMLAB2A',
      instructor: 'M. Gotardo',
      dayPattern: 'Monday and Thursday',
      dayToken: 'MTh',
      startTimeRaw: '08:00',
      endTimeRaw: '09:00',
    );
    final rows = [
      ValidatedEslipRow(
        enrollmentCode: 'A145',
        subjectCode: 'IT-122',
        description: 'System Analysis',
        units: '2',
        lab: '',
        scheduleRaw: '8-9 am MTh COMLAB2A',
        section: 'AI31',
        instructor: 'M. Gotardo',
        parsed: parsed,
        confidence: RowConfidenceLevel.high,
        confidenceScore: 1,
        fieldIssues: const [],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: EslipPrintableView(profile: profile, rows: rows),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enrolment form preview'), findsOneWidget);
    expect(find.text('LEYTE NORMAL UNIVERSITY'), findsOneWidget);
    expect(find.text('IT-122'), findsWidgets);
  });
}
