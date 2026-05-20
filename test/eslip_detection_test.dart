import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';

void main() {
  group('isEslipDocument', () {
    test('detects LNU enrolment form keywords', () {
      const text = '''
LEYTE NORMAL UNIVERSITY
First Semester Enrolment and Assessment Form
CODE SUBJECT DESCRIPTION UNITS LAB SCHEDULE AND ROOM
Total Units 21
Assessment Details Tuition Fee
''';
      expect(isEslipDocument(text), isTrue);
    });

    test('detects by subject code density', () {
      const text = '''
IT-122 8-9 am MTh COMLAB2A
IT-121L 9-10:30 am MTh COMLAB4A
IT-121 8-10 am W CISCOLAB
GE-117 1-2:30 pm MTh TBA11A
''';
      expect(isEslipDocument(text), isTrue);
    });

    test('rejects random photo text', () {
      expect(
        isEslipDocument('Hello world this is a selfie caption'),
        isFalse,
      );
    });
  });
}
