import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';
import 'package:lnu_app_class_locator/utils/formatters.dart';
import 'package:lnu_app_class_locator/utils/lnu_slip_patterns.dart';
import 'package:lnu_app_class_locator/utils/parsed_schedule.dart';

void main() {
  group('extended subject and room patterns', () {
    test('matches EDUC and PATHFIT and PROF ED codes', () {
      expect(lnuSubjectCodePattern.firstMatch('EDUC-118')?.group(0), 'EDUC-118');
      expect(lnuSubjectCodePattern.firstMatch('PATHFIT-4')?.group(0), 'PATHFIT-4');
      expect(
        lnuSubjectCodePattern.firstMatch('PROF ED-109')?.group(0),
        'PROF ED-109',
      );
    });

    test('matches campus room codes', () {
      for (final room in [
        'CON105A',
        'ACAD201A',
        'MSR205A',
        'PMF15A',
        'ILS-JH',
        'TBA',
      ]) {
        expect(lnuRoomCodePattern.firstMatch(room)?.group(1), room);
      }
    });

    test('parses 7:30-9 am and 10:30 am-12 pm schedules', () {
      expect(
        parseScheduleString('7:30-9 am MTh CON105A')?.startTimeRaw,
        '07:30',
      );
      expect(parseScheduleString('7:30-9 am MTh CON105A')?.endTimeRaw, '09:00');
      expect(
        parseScheduleString('10:30 am-12 pm MTh PMF13A')?.endTimeRaw,
        '12:00',
      );
      expect(
        formatEslipScheduleColumn(
          dayPattern: 'MTh',
          startTimeRaw: '07:30',
          endTimeRaw: '09:00',
          roomCode: 'CON105A',
        ),
        '7:30-9 am MTh CON105A',
      );
    });
  });

  group('BINONGO second semester IT slip (11 rows)', () {
    const sample = '''
Second Semester 2025-2026 Enrolment and Assessment Form No. 380738
Student ID No: 2300639
Name: BINONGO III, AQUILINO T.
A113 IT-124 Quantitative Methods with Ethics 3 7:30-9 am MTh CON105A AI31 L. Caluza
A118 GE-108 Ethics 3 9-10:30 am MTh CON301A AI31 R. Martinez
A114 IT-105L Mobile Development 1 1 1-2:30 pm MTh COMLAB2A AI31 R. Cabangon
A115 IT-129L System Administration and Maintenance 1 1 2:30-4 pm MTh CON103A AI31 D. Tibe
A120 IT-128 Capstone Project I 2 8-9 am TF COMLAB1A AI31 D. Funcion
A119 IT-128L Capstone Project I 1 1 9-10:30 am TF COMLAB1A AI31 D. Funcion
A112 IT-126 Social and Professional Issues 3 4-5:30 pm TF ACAD201A AI31 R. Verecio
A121 IT-127L Application Development and Emerging Tech 1 1 5:30-7 pm TF COMLAB1A AI31 C. Celestial
A116 IT-105 Mobile Development 2 8-10 am W CON105A AI31 R. Cabangon
A117 IT-129 System Administration and Maintenance 2 10 am-12 pm W CON105A AI31 D. Tibe
A111 IT-127 Application Development and Emerging Tech 2 5-7 pm W COMLAB2A AI31 C. Celestial
''';

    test('parses all 11 classes with correct day groups', () {
      final o = parseEslipOcrText(sample);
      expect(o.profile.studentId, '2300639');
      expect(o.classes.length, 11);

      expect(
        o.classes.where((c) => c.parsed.dayToken == 'MTh').length,
        4,
      );
      expect(
        o.classes.where((c) => c.parsed.dayToken == 'TF').length,
        4,
      );
      expect(
        o.classes.where((c) => c.parsed.dayToken == 'W').length,
        3,
      );

      final capstone = o.classes.firstWhere(
        (c) => c.parsed.subjectCode == 'IT-128',
      );
      expect(capstone.parsed.roomCode, 'COMLAB1A');
      expect(
        o.validatedRows
            .firstWhere((r) => r.subjectCode == 'IT-128')
            .scheduleRaw,
        contains('TF'),
      );

      final wed = o.classes.firstWhere((c) => c.parsed.subjectCode == 'IT-105');
      expect(wed.parsed.dayToken, 'W');
      expect(wed.parsed.roomCode, 'CON105A');
    });
  });

  group('PARDILLA education slip (8 rows)', () {
    const sample = '''
Second Semester 2025-2026 Enrolment and Assessment Form No. 382225
Student ID No: 2402915
Name: PARDILLA, MARIDEL T.
E177 EDUC-118 Technology for Teaching and 3 7:30-9 am MTh MSR205A EE22 A. Cipriano
E174 EDUC-115 Teaching English in the Elementary 3 9-10:30 am MTh PMF15A EE22 M. Gallaza
E173 EDUC-113 Teaching Math in the Intermediate 3 10:30 am-12 pm MTh PMF13A EE22 F. Peñeda
E178 PATHFIT-4 Physical Activities Towards Health 2 1-2 pm MTh TBA EE22 T. Agner
E176 EDUC-117 Teaching P.E. and Health in the 3 4-5:30 pm MTh PMF11A EE22 L. Margallo
E171 PROF ED-109 Assessment of Learning 2 3 9-10:30 am TF PMF13A EE22 F. Peñeda
E175 EDUC-116 Teaching Music in the Elementary 3 10:30 am-12 pm TF ILS-JH EE22 L. Ripalda
E172 PROF ED-110 The Teacher and the Community 3 2:30-4 pm TF MSR205A EE22 T. Ticoy
''';

    test('parses 8 education rows including PROF ED and PATHFIT', () {
      final o = parseEslipOcrText(sample);
      expect(o.classes.length, 8);
      expect(
        o.classes.map((c) => c.parsed.subjectCode).toSet(),
        containsAll(['EDUC-118', 'PATHFIT-4', 'PROF ED-109', 'PROF ED-110']),
      );

      final pathfit = o.classes.firstWhere(
        (c) => c.parsed.subjectCode == 'PATHFIT-4',
      );
      expect(pathfit.parsed.roomCode, 'TBA');
      expect(pathfit.parsed.dayToken, 'MTh');

      final prof = o.classes.firstWhere(
        (c) => c.parsed.subjectCode == 'PROF ED-109',
      );
      expect(prof.parsed.dayToken, 'TF');
      expect(prof.parsed.roomCode, 'PMF13A');
      final profRow = o.validatedRows.firstWhere(
        (r) => r.subjectCode == 'PROF ED-109',
      );
      expect(profRow.scheduleRaw, contains('TF'));
      expect(profRow.scheduleRaw, contains('PMF13A'));

      final ils = o.classes.firstWhere(
        (c) => c.parsed.subjectCode == 'EDUC-116',
      );
      expect(ils.parsed.roomCode, 'ILS-JH');
    });
  });

  group('preprocess handles E-series codes and spaced subjects', () {
    test('E 177 becomes E177', () {
      final pre = preprocessEslipOcrText('E 177 EDUC-118 7:30-9 am MTh MSR205A');
      expect(pre, contains('E177'));
      expect(pre, contains('EDUC-118'));
    });
  });
}
