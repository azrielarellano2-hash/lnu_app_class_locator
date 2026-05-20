import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/data/day_codes.dart';
import 'package:lnu_app_class_locator/models/models.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';
import 'package:lnu_app_class_locator/utils/eslip_printable_rows.dart';
import 'package:lnu_app_class_locator/utils/formatters.dart';

void main() {
  group('TF day token', () {
    test('does not split TF into T + F', () {
      expect(extractDayTokensFromBlob('TF'), ['TF']);
      expect(extractDayTokensFromBlob('1-2:30pmTF'), ['TF']);
      expect(matchScheduleDayToken('1-2:30 pm TF'), 'TF');
    });

    test('does not treat T in TBA as Tuesday', () {
      expect(extractDayTokensFromBlob('TBA11A'), isEmpty);
      expect(matchScheduleDayToken('1-2:30 pm'), isNull);
    });

    test('canonicalizes readable Tuesday and Friday to TF', () {
      expect(canonicalizeEslipDayToken('Tuesday and Friday'), 'TF');
    });

    test('formatEslipScheduleColumn uses TF not full day names', () {
      expect(
        formatEslipScheduleColumn(
          dayPattern: 'Tuesday and Friday',
          startTimeRaw: '13:00',
          endTimeRaw: '14:30',
          roomCode: 'COMLAB2A',
        ),
        '1-2:30 pm TF COMLAB2A',
      );
    });
  });

  group('TF from OCR sample rows', () {
    const tfRows = [
      'A148 IT-119L IT Elective IV 1 1 1-2:30 pm TF COMLAB2A AI31 G. Ormeneta',
      'A150 IT-117L System Integration 1 1 2:30-4 pm TF COMLAB3A AI31 D. Turco',
      'A142 GE-119 Philippine Popular Culture 3 4-5:30 pm TF CON204A AI31 A. Rosales',
    ];

    for (final line in tfRows) {
      test(line, () {
        final o = parseEslipOcrText(line);
        expect(o.classes, hasLength(1));
        expect(o.classes.single.parsed.dayToken, 'TF');
        expect(o.classes.single.parsed.dayPattern, 'Tuesday and Friday');
        expect(
          o.classes.single.parsed.startTimeRaw,
          isNotEmpty,
        );
      });
    }
  });

  group('TF printable from DB slots', () {
    test('infers TF when Tue + Fri slots share enrolment code', () {
      const code = 'A148';
      final slots = [
        ScheduleSlot(
          id: 1,
          enrollmentCode: code,
          subjectName: 'IT-119L',
          roomCode: 'COMLAB2A',
          dayOfWeek: 1,
          startTime: '13:00',
          endTime: '14:30',
          subjectTitle: 'Web Systems',
          instructorName: 'G. Ormeneta',
          section: 'AI31',
        ),
        ScheduleSlot(
          id: 2,
          enrollmentCode: code,
          subjectName: 'IT-119L',
          roomCode: 'COMLAB2A',
          dayOfWeek: 4,
          startTime: '13:00',
          endTime: '14:30',
          subjectTitle: 'Web Systems',
          instructorName: 'G. Ormeneta',
          section: 'AI31',
        ),
      ];

      final rows = buildPrintableRowsFromSlots(slots, defaultSection: 'AI31');
      expect(rows, hasLength(1));
      expect(rows.single.scheduleRaw, '1-2:30 pm TF COMLAB2A');
      expect(eslipScheduleCell(rows.single), '1-2:30 pm TF COMLAB2A');
    });
  });
}
