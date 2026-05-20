import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';
import 'package:lnu_app_class_locator/utils/lnu_slip_patterns.dart';

void main() {
  test('preprocess no longer corrupts 8-10am times', () {
    final pre = preprocessEslipOcrText('8-10am W CISCOLAB');
    expect(pre, isNot(contains(r'$1')));
    expect(pre, contains('8-10 am'));
  });

  test('preprocess fixes enrolment codes for row splitting', () {
    final pre = preprocessEslipOcrText('A 145 IT-122 8-9 am MTh COMLAB2A');
    expect(pre, contains('A145'));
    expect(pre, isNot(contains(r'$1')));
  });

  test('preprocess does not split PM in PMF room codes', () {
    final pre = preprocessEslipOcrText('9-10:30 am MTh PMF15A EE22');
    expect(pre, contains('PMF15A'));
    expect(pre, isNot(contains('PM F15A')));
  });

  test('subject code regex matches lab and education codes', () {
    expect(lnuSubjectCodePattern.firstMatch('IT-122')?.group(0), 'IT-122');
    expect(lnuSubjectCodePattern.firstMatch('IT-121L')?.group(0), 'IT-121L');
    expect(lnuSubjectCodePattern.firstMatch('EDUC-118')?.group(0), 'EDUC-118');
    expect(lnuSubjectCodePattern.firstMatch('PATHFIT-4')?.group(0), 'PATHFIT-4');
  });

  const userSampleRows = [
    'A145 IT-122 System Analysis and Design 2  8-9 am MTh COMLAB2A AI31 M. Gotardo',
    'A146 IT-121L Information Management I 1 1  9-10:30 am MTh COMLAB4A AI31 D. Funcion',
    'A144 GE-117 The Entrepreneurial Mind (Elective) 3  1-2:30 pm MTh TBA11A AI31 A. Parena',
    'A147 IT-121 Information Management I 2  8-10 am W CISCOLAB AI31 D. Funcion',
    'A152 IT-117 System Integration and Architecture 2  10 am-12 pm W COMLAB7A AI31 D. Turco',
    'A148 IT-119L IT Elective IV 1 1  1-2:30 pm TF COMLAB2A AI31 G. Ormeneta',
  ];

  test('parses user sample rows into structured display fields', () {
    for (final line in userSampleRows) {
      final o = parseEslipOcrText(line);
      expect(o.classes, isNotEmpty, reason: 'Failed: $line');
    }

    final r1 = parseEslipOcrText(userSampleRows[0]).classes.single;
    final p1 = r1.parsed;
    expect(p1.subjectCode, 'IT-122');
    expect(p1.subjectName, 'IT-122 System Analysis and Design');
    expect(p1.roomCode, 'COMLAB2A');
    expect(p1.instructor, 'M. Gotardo');
    expect(p1.dayPattern, 'Monday and Thursday');
    expect(p1.startTime.replaceAll('\u202f', ' '), '8:00 AM');
    expect(p1.endTime.replaceAll('\u202f', ' '), '9:00 AM');

    final r2 = parseEslipOcrText(userSampleRows[1]).classes.single;
    expect(r2.parsed.subjectCode, 'IT-121L');
    expect(r2.parsed.subjectName, contains('Information Management I'));

    final r4 = parseEslipOcrText(userSampleRows[3]).classes.single;
    expect(r4.parsed.dayPattern, 'Wednesday');

    final r5 = parseEslipOcrText(userSampleRows[4]).classes.single;
    expect(r5.parsed.startTimeRaw, '10:00');
    expect(r5.parsed.endTimeRaw, '12:00');
  });

  const fullSample = '''
First Semester 2025-2026 Enrolment and Assessment Form
Student ID No: 2300289
Name: ARELLANO, AZRIEL S.
A145 IT-122 System Analysis and Design 2 8-9 am MTh COMLAB2A AI31 M. Gotardo
A146 IT-121L Information Management I 1 1 9-10:30 am MTh COMLAB4A AI31 D. Funcion
A144 GE-117 The Entrepreneurial Mind (Elective) 3 1-2:30 pm MTh TBA11A AI31 A. Parena
A143 IT-122L System Analysis and Design 1 1 2:30-4 pm MTh COMLAB2A AI31 M. Gotardo
A151 IT-125L Information Assurance and Security 1 5:30-7 pm MTh COMLAB1A AI31 D. Diaz
A148 IT-119L IT Elective IV - Web Systems and Technologies 1 1 1-2:30 pm TF COMLAB2A AI31 G. Ormeneta
A150 IT-117L System Integration and Architecture 1 1 2:30-4 pm TF COMLAB3A AI31 D. Turco
A142 GE-119 Philippine Popular Culture (Elective) 3 4-5:30 pm TF CON204A AI31 A. Rosales
A147 IT-121 Information Management I 2 8-10 am W CISCOLAB AI31 D. Funcion
A152 IT-117 System Integration and Architecture 2 10 am-12 pm W COMLAB7A AI31 D. Turco
A149 IT-119 IT Elective IV - Web Systems and Technologies 2 1-3 pm W COMLAB6A AI31 G. Ormeneta
A153 IT-125 Information Assurance and Security 2 5-7 pm W COMLAB3A AI31 D. Diaz
''';

  test('parses full 12-row enrolment slip without duplicate CODE rows', () {
    final o = parseEslipOcrText(fullSample);
    expect(o.profile.studentId, '2300289');
    expect(o.classes.length, 12);
    final codes = o.classes.map((c) => c.enrollmentCode).toList();
    expect(codes.toSet().length, codes.length);
    for (final row in o.classes) {
      expect(row.parsed.subjectName, isNotEmpty);
      expect(row.parsed.roomCode, isNotEmpty);
      expect(row.parsed.dayPattern, isNotEmpty);
    }
    final wed = o.classes.where((c) => c.parsed.dayPattern == 'Wednesday');
    expect(wed.length, 4);
    final mth = o.classes.where(
      (c) => c.parsed.dayPattern == 'Monday and Thursday',
    );
    expect(mth.length, 5);
  });

  test('keeps IT-121 and IT-121L as separate enrolment rows', () {
    const sample = '''
A146 IT-121L Information Management I 1 1 9-10:30 am MTh COMLAB4A AI31 D. Funcion
A147 IT-121 Information Management I 2 8-10 am W CISCOLAB AI31 D. Funcion
''';
    final o = parseEslipOcrText(sample);
    expect(o.classes.length, 2);
    expect(
      o.classes.map((c) => c.parsed.subjectCode).toSet(),
      {'IT-121L', 'IT-121'},
    );
  });

  test('merges description and schedule split across lines', () {
    const split = '''
A145 IT-122 System Analysis and Design 2
8-9 am MTh COMLAB2A AI31 M. Gotardo
''';
    final row = parseEslipOcrText(split).classes.single;
    expect(row.parsed.subjectCode, 'IT-122');
    expect(row.parsed.subjectName, contains('System Analysis and Design'));
    expect(row.parsed.instructor, 'M. Gotardo');
  });

  test('joins enrolment code line with subject and schedule on following lines', () {
    const ocr = '''
A145
IT-122
System Analysis and Design
2
8-9 am MTh COMLAB2A
AI31
M. Gotardo
A143
IT-122L
System Analysis and Design
1 1
2:30-4 pm MTh COMLAB2A
AI31
M. Gotardo
A146
IT-121L
Information Management I
1 1
9-10:30 am MTh COMLAB4A
AI31
D. Funcion
''';
    final o = parseEslipOcrText(ocr);
    expect(o.classes.length, 3);
    expect(o.warnings.where((w) => w.contains('No time range')), isEmpty);
    expect(
      o.classes.map((c) => c.parsed.subjectCode).toSet(),
      {'IT-122', 'IT-122L', 'IT-121L'},
    );
    final lab = o.classes.firstWhere((c) => c.parsed.subjectCode == 'IT-121L');
    expect(lab.parsed.dayPattern, 'Monday and Thursday');
    expect(lab.parsed.instructor, 'D. Funcion');
  });

  test('parses multiline OCR rows anchored by enrolment code', () {
    const multiline = '''
A145
IT-122
System Analysis and Design
2
8-9 am MTh COMLAB2A
AI31
M. Gotardo
A146
IT-121L
Information Management I
1 1
9-10:30 am MTh COMLAB4A
AI31
D. Funcion
''';
    final o = parseEslipOcrText(multiline);
    expect(o.classes.map((c) => c.parsed.subjectCode).toSet(),
        {'IT-122', 'IT-121L'});
  });

  test('parses all subjects when enrolment codes are missing from OCR', () {
    const noRowCodes = '''
IT-122 System Analysis and Design 2 8-9 am MTh COMLAB2A AI31 M. Gotardo
IT-121L Information Management I 1 1 9-10:30 am MTh COMLAB4A AI31 D. Funcion
GE-117 The Entrepreneurial Mind (Elective) 3 1-2:30 pm MTh TBA11A AI31 A. Parena
IT-121 Information Management I 2 8-10 am W CISCOLAB AI31 D. Funcion
IT-117 System Integration and Architecture 2 10 am-12 pm W COMLAB7A AI31 D. Turco
IT-119L IT Elective IV 1 1 1-2:30 pm TF COMLAB2A AI31 G. Ormeneta
''';
    final o = parseEslipOcrText(noRowCodes);
    expect(o.classes.length, 6);
  });

  test('parses compound instructor surnames', () {
    const line =
        'A148 IT-119L IT Elective IV 1 1 1-2:30 pm TF COMLAB2A AI31 J. Dela Cruz';
    final row = parseEslipOcrText(line).classes.single;
    expect(row.parsed.instructor, 'J. Dela Cruz');
  });

  test('preprocess fixes spaced room, day, and section OCR', () {
    const messy =
        'A 145 IT - 122 System Analysis 2 8 - 9 am M Th COM LAB 2A Al31 M. Gotardo';
    final pre = preprocessEslipOcrText(messy);
    expect(pre, contains('A145'));
    expect(pre, contains('IT-122'));
    expect(pre, contains('MTh'));
    expect(pre, contains('COMLAB2A'));
    expect(pre, contains('AI31'));

    final row = parseEslipOcrText(messy).classes.single;
    expect(row.parsed.subjectCode, 'IT-122');
    expect(row.parsed.roomCode, 'COMLAB2A');
    expect(row.parsed.dayPattern, 'Monday and Thursday');
    expect(row.parsed.instructor, 'M. Gotardo');
  });

  test('preprocess separates compact meridiem from day', () {
    expect(preprocessEslipOcrText('8-10am W CISCOLAB'), contains('8-10 am'));
    expect(preprocessEslipOcrText('8-10amW CISCOLAB'), contains('8-10 am W'));
  });

  test('parses Wednesday when meridiem is glued to W', () {
    const glued =
        'A147 IT-121 Information Management I 2 8-10am W CISCOLAB AI31 D. Funcion';
    final outcome = parseEslipOcrText(glued);
    expect(outcome.classes, hasLength(1));
    final p = outcome.classes.single.parsed;
    expect(p.dayToken, 'W');
    expect(p.dayPattern, 'Wednesday');
    expect(p.roomCode, 'CISCOLAB');
  });

  test('parses Wednesday from Wed alias and keeps Web in titles', () {
    const line =
        'A149 IT-119 IT Elective IV - Web Systems and Technologies 2 1-3 pm Wed COMLAB6A AI31 G. Ormeneta';
    final p = parseEslipOcrText(line).classes.single.parsed;
    expect(p.dayPattern, 'Wednesday');
    expect(p.subjectTitle, contains('Web'));
  });

  test('parses split meridiem and compact evening times', () {
    const line =
        'A151 IT-125L Information Assurance and Security 1 5:30-7 pm MTh COMLAB1A AI31 D. Diaz';
    final p = parseEslipOcrText(line).classes.single.parsed;
    expect(p.startTimeRaw, '17:30');
    expect(p.endTimeRaw, '19:00');
    expect(p.roomCode, 'COMLAB1A');

    const wed =
        'A152 IT-117 System Integration and Architecture 2 10 am-12 pm W COMLAB7A AI31 D. Turco';
    final w = parseEslipOcrText(wed).classes.single.parsed;
    expect(w.startTimeRaw, '10:00');
    expect(w.endTimeRaw, '12:00');
    expect(w.dayPattern, 'Wednesday');
  });

  test('parses ALL CAPS instructor names from OCR', () {
    const line =
        'A148 IT-119L IT Elective IV 1 1 1-2:30 pm TF COMLAB2A AI31 G. ORMENETA';
    expect(parseEslipOcrText(line).classes.single.parsed.instructor, 'G. ORMENETA');
  });

  test('keeps elective titles and strips units or lab columns', () {
    const line =
        'A144 GE-117 The Entrepreneurial Mind (Elective) 3 1-2:30 pm MTh TBA11A AI31 A. Parena';
    final p = parseEslipOcrText(line).classes.single.parsed;
    expect(p.subjectTitle, contains('Entrepreneurial Mind'));
    expect(p.subjectTitle, isNot(contains('1-2:30')));
    expect(p.roomCode, 'TBA11A');
  });

  test('instructor is not schedule text', () {
    const crowded =
        'A146 IT-121L Information Management I 1 1 9-10:30 am MTh COMLAB4A AI31 D. Funcion A145 IT-122 System Analysis and Design 2 8-9 am MTh COMLAB2A AI31 M. Gotardo';
    final o = parseEslipOcrText(crowded);
    expect(o.classes.length, 2);
    final row = o.classes.firstWhere(
      (c) => c.parsed.roomCode == 'COMLAB4A',
    );
    expect(row.parsed.instructor, 'D. Funcion');
  });
}
