import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/data/day_codes.dart';

void main() {
  test('expandEslipDayToken maps LNU slip tokens', () {
    expect(expandEslipDayToken('MTh'), [0, 3]);
    expect(expandEslipDayToken('W'), [2]);
    expect(expandEslipDayToken('TF'), [1, 4]);
    expect(expandEslipDayToken('SS'), [5, 6]);
  });
}
