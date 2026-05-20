import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/data/day_codes.dart';
import 'package:lnu_app_class_locator/utils/parsed_schedule.dart';

void main() {
  group('day token priority', () {
    test('MTh is one token not M+T', () {
      expect(extractDayTokensFromBlob('MTh'), ['MTh']);
      expect(extractDayTokensFromBlob('8-9amMTh'), ['MTh']);
      expect(extractDayTokensFromBlob('amMTh'), ['MTh']);
      expect(extractDayTokensFromBlob('pmTF'), ['TF']);
      expect(weekdayIndicesForToken('MTh'), [0, 3]);
    });

    test('TF is one token', () {
      expect(extractDayTokensFromBlob('TF'), ['TF']);
      expect(weekdayIndicesForToken('TF'), [1, 4]);
    });

    test('W is Wednesday only', () {
      expect(weekdayIndicesForToken('W'), [2]);
      expect(weekdayNamesForToken('W'), ['Wednesday']);
    });
  });

  group('parseScheduleString ground truth', () {
    const rows = <(String, List<String>, String)>[
      ('8-9 am MTh COMLAB2A', ['Monday', 'Thursday'], 'COMLAB2A'),
      ('9-10:30 am MTh COMLAB4A', ['Monday', 'Thursday'], 'COMLAB4A'),
      ('1-2:30 pm MTh TBA11A', ['Monday', 'Thursday'], 'TBA11A'),
      ('2:30-4 pm MTh COMLAB2A', ['Monday', 'Thursday'], 'COMLAB2A'),
      ('5:30-7 pm MTh COMLAB1A', ['Monday', 'Thursday'], 'COMLAB1A'),
      ('1-2:30 pm TF COMLAB2A', ['Tuesday', 'Friday'], 'COMLAB2A'),
      ('2:30-4 pm TF COMLAB3A', ['Tuesday', 'Friday'], 'COMLAB3A'),
      ('4-5:30 pm TF CON204A', ['Tuesday', 'Friday'], 'CON204A'),
      ('8-10 am W CISCOLAB', ['Wednesday'], 'CISCOLAB'),
      ('10 am-12 pm W COMLAB7A', ['Wednesday'], 'COMLAB7A'),
      ('1-3 pm W COMLAB6A', ['Wednesday'], 'COMLAB6A'),
      ('5-7 pm W COMLAB3A', ['Wednesday'], 'COMLAB3A'),
    ];

    for (final row in rows) {
      test(row.$1, () {
        final p = parseScheduleString(row.$1);
        expect(p, isNotNull, reason: row.$1);
        expect(p!.days, row.$2);
        expect(p.room, row.$3);
      });
    }

    test('Wednesday rows count', () {
      const wedSubjects = ['8-10 am W CISCOLAB', '10 am-12 pm W COMLAB7A'];
      for (final s in wedSubjects) {
        expect(parseScheduleString(s)!.days, ['Wednesday']);
      }
    });
  });
}
