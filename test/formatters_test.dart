import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/utils/formatters.dart';

void main() {
  group('formatReadableDayPattern', () {
    test('maps LNU e-slip day tokens', () {
      expect(formatReadableDayPattern('MTh'), 'Monday and Thursday');
      expect(formatReadableDayPattern('TF'), 'Tuesday and Friday');
      expect(formatReadableDayPattern('SS'), 'Saturday and Sunday');
      expect(formatReadableDayPattern('W'), 'Wednesday');
    });
  });

  group('formatCardDescription', () {
    test('shows description only', () {
      expect(
        formatCardDescription(
          subjectTitle: 'System Analysis and Design',
          subjectCode: 'IT-122',
        ),
        'System Analysis and Design',
      );
    });

    test('falls back to code when description missing', () {
      expect(
        formatCardDescription(
          subjectTitle: null,
          subjectCode: 'IT-122',
        ),
        'IT-122',
      );
    });
  });

  group('formatCardSubject', () {
    test('combines code and title', () {
      expect(
        formatCardSubject(
          subjectTitle: 'System Analysis and Design',
          subjectCode: 'IT-122',
        ),
        'IT-122 System Analysis and Design',
      );
    });

    test('shows title only when code missing', () {
      expect(
        formatCardSubject(
          subjectTitle: 'Mobile Development',
          subjectCode: 'CLASS',
        ),
        'Mobile Development',
      );
    });

    test('shows code only when title missing', () {
      expect(
        formatCardSubject(
          subjectTitle: null,
          subjectCode: 'IT-122',
        ),
        'IT-122',
      );
    });

    test('never unknown when title exists', () {
      expect(
        formatCardSubject(
          subjectTitle: 'Information Management I',
          subjectCode: 'CLASS',
        ),
        isNot('Unknown Subject'),
      );
    });
  });

  group('stripScheduleNoiseFromText', () {
    test('removes embedded schedule fragments', () {
      expect(
        stripScheduleNoiseFromText(
          'System Analysis 8-9 am MTh COMLAB2A',
        ),
        'System Analysis',
      );
    });
  });

  group('sanitizeInstructorForDisplay', () {
    test('accepts LNU instructor pattern', () {
      expect(sanitizeInstructorForDisplay('M. Gotardo'), 'M. Gotardo');
      expect(sanitizeInstructorForDisplay('D. Funcion'), 'D. Funcion');
      expect(
        sanitizeInstructorForDisplay('J. Dela Cruz'),
        'J. Dela Cruz',
      );
    });

    test('rejects schedule OCR blobs', () {
      expect(
        sanitizeInstructorForDisplay('9-10:30 am MTh COMLAB4A'),
        isNull,
      );
    });
  });
}
