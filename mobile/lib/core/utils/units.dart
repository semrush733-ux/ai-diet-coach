/// Unit conversions used across onboarding and profile.
/// Canonical storage is always metric (kg, cm); glucose canonical is mg/dL.
abstract final class Units {
  static const double lbPerKg = 2.2046226218;
  static const double cmPerInch = 2.54;

  /// 1 mmol/L of glucose = 18.016 mg/dL (molar mass of glucose 180.16 g/mol).
  static const double mgDlPerMmolL = 18.016;

  static double kgToLb(double kg) => kg * lbPerKg;
  static double lbToKg(double lb) => lb / lbPerKg;

  static double cmToTotalInches(double cm) => cm / cmPerInch;
  static (int feet, int inches) cmToFeetInches(double cm) {
    final total = (cmToTotalInches(cm)).round();
    return (total ~/ 12, total % 12);
  }

  static double feetInchesToCm(int feet, int inches) =>
      (feet * 12 + inches) * cmPerInch;

  static double mmolLToMgDl(double mmolL) => mmolL * mgDlPerMmolL;
  static double mgDlToMmolL(double mgDl) => mgDl / mgDlPerMmolL;
}
