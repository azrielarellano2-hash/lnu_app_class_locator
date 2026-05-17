import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/utils/schedule_field_parser.dart';

void main() {
  group('parseScheduleField', () {
    test('parses standard schedule strings', () {
      const cases = <(String, String, String, String, String)>[
        ('8-9 am MTh COMLAB2A', '8:00 AM', '9:00 AM', 'MTh', 'COMLAB2A'),
        ('9-10:30 am MTh COMLAB4A', '9:00 AM', '10:30 AM', 'MTh', 'COMLAB4A'),
        ('1-2:30 pm TF COMLAB2A', '1:00 PM', '2:30 PM', 'TF', 'COMLAB2A'),
        ('8-10 am W CISCOLAB', '8:00 AM', '10:00 AM', 'W', 'CISCOLAB'),
        ('10 am-12 pm W COMLAB7A', '10:00 AM', '12:00 PM', 'W', 'COMLAB7A'),
        ('5:30-7 pm SS COMLAB3A', '5:30 PM', '7:00 PM', 'SS', 'COMLAB3A'),
      ];

      for (final c in cases) {
        final p = parseScheduleField(c.$1);
        expect(p, isNotNull, reason: c.$1);
        expect(p!.startTime.replaceAll('\u202f', ' '), c.$2);
        expect(p.endTime.replaceAll('\u202f', ' '), c.$3);
        expect(p.dayToken, c.$4);
        expect(p.roomCode, c.$5);
      }
    });

    test('maps day tokens', () {
      expect(parseScheduleField('8-9 am MTh COMLAB2A')!.dayPattern,
          'Monday and Thursday');
      expect(parseScheduleField('8-10 am W CISCOLAB')!.dayPattern, 'Wednesday');
      expect(parseScheduleField('1-2:30 pm TF COMLAB2A')!.dayPattern,
          'Tuesday and Friday');
      expect(parseScheduleField('8-10 am SS COMLAB1A')!.dayPattern,
          'Saturday and Sunday');
    });
  });
}
