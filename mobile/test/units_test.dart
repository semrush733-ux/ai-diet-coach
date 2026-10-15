import 'package:ai_diet_coach/core/utils/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Units', () {
    test('kg ↔ lb round trip', () {
      const kg = 72.5;
      expect(Units.lbToKg(Units.kgToLb(kg)), closeTo(kg, 1e-9));
    });

    test('feet/inches → cm', () {
      // 5 ft 8 in = 68 in = 172.72 cm
      expect(Units.feetInchesToCm(5, 8), closeTo(172.72, 0.01));
    });

    test('glucose mmol/L ↔ mg/dL uses 18.016 factor', () {
      expect(Units.mmolLToMgDl(5.5), closeTo(99.088, 0.001));
      expect(Units.mgDlToMmolL(126), closeTo(6.994, 0.001));
      expect(
          Units.mgDlToMmolL(Units.mmolLToMgDl(7.2)), closeTo(7.2, 1e-9));
    });
  });
}
