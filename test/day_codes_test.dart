import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/data/day_codes.dart';

void main() {
  group('strict LNU day tokens', () {
    test('expandEslipDayToken maps MTh to Monday+Thursday only', () {
      expect(expandEslipDayToken('MTh'), [0, 3]);
      expect(expandEslipDayToken('W'), [2]);
      expect(expandEslipDayToken('TF'), [1, 4]);
      expect(expandEslipDayToken('SS'), [5, 6]);
    });

    test('MTh is never Monday+Tuesday', () {
      final days = expandEslipDayToken('MTh');
      expect(days, isNot(contains(1)));
      expect(days, contains(0));
      expect(days, contains(3));
    });

    test('OCR aliases normalize to canonical tokens', () {
      expect(canonicalizeEslipDayToken('MTH'), 'MTh');
      expect(canonicalizeEslipDayToken('NTh'), 'MTh');
      expect(canonicalizeEslipDayToken('NTH'), 'MTh');
      expect(canonicalizeEslipDayToken('TTH'), 'TF');
      expect(canonicalizeEslipDayToken('Wed'), 'W');
    });

    test('matchScheduleDayToken prefers strict tokens in tail', () {
      expect(matchScheduleDayToken('8-9 am MTh'), 'MTh');
      expect(matchScheduleDayToken('8-10 am W'), 'W');
      expect(matchScheduleDayToken('1-2:30 pm TF'), 'TF');
    });

    test('single M T Th map when explicit', () {
      expect(weekdayIndicesForToken('M'), [0]);
      expect(weekdayIndicesForToken('Th'), [3]);
    });

    test('extractDayTokens does not split MTh', () {
      expect(extractDayTokensFromBlob('MTh'), ['MTh']);
      expect(extractDayTokensFromBlob('TF'), ['TF']);
    });

    test('does not parse T inside TBA room code', () {
      expect(extractDayTokensFromBlob('TBA11A'), isEmpty);
    });

    test('readable labels match expected mapping', () {
      expect(readableDayPattern('MTh'), 'Monday and Thursday');
      expect(readableDayPattern('TF'), 'Tuesday and Friday');
      expect(readableDayPattern('W'), 'Wednesday');
      expect(readableDayPattern('SS'), 'Saturday and Sunday');
    });
  });
}
