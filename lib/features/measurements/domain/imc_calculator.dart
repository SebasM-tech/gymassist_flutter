/// Regla de negocio pura (antes en MedicionesService).
class ImcCalculator {
  ImcCalculator._();

  static double calculate(double pesoKg, double estaturaM) =>
      pesoKg / (estaturaM * estaturaM);

  static String interpret(double imc) {
    if (imc < 18.5) return 'Peso muy bajo';
    if (imc < 24.9) return 'Peso normal';
    if (imc < 29.9) return 'Sobrepeso';
    return 'Obesidad';
  }
}
