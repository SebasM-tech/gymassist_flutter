import 'package:flutter_test/flutter_test.dart';
import 'package:gymassist/features/predictions/domain/prediction_domain.dart';

void main() {
  test('interpreta la respuesta de POST /predecir/lote de FastAPI', () {
    final json = {
      'id': 'c1',
      'nombre': 'Juan Herrera',
      'probabilidadAbandono': 0.8123,
      'prediccion': 'Se va',
      'riesgo': 'CRITICO',
      'factores': [
        {'variable': 'dias_ultima_visita', 'factor': 'Días desde la última visita', 'impacto': 0.21, 'efecto': 'aumenta el riesgo', 'descripcion': 'Lleva 12 días sin venir'},
        {'variable': 'antiguedad_meses', 'factor': 'Antigüedad', 'impacto': -0.05, 'efecto': 'reduce el riesgo', 'descripcion': '6 meses de antigüedad'},
      ],
      'recomendacion': 'URGENTE: Contactarlo y ofrecer una sesión gratis.',
      'features': {'asistencias4Semanas': 2, 'pagoAlDia': 'Si', 'antiguedadMeses': 6, 'tipoPlan': 'Mensual'},
      'asistenciaSemanal': [3, 3, 3, 2, 3, 2, 2, 1, 1, 1, 0, 0],
    };
    final p = ChurnPrediction.fromJson(json, correo: 'juanh@mail.com');
    expect(p.seVa, isTrue);
    expect(p.porcentaje, 81);
    expect(p.factores.first.aumentaRiesgo, isTrue);
    expect(p.factores.last.aumentaRiesgo, isFalse);
    expect(p.pagoAlDia, isTrue);
    expect(p.asistenciaSemanal, hasLength(12));
    expect(p.correo, 'juanh@mail.com');
  });

  test('interpreta GET /salud', () {
    final h = ModelHealth.fromJson({
      'estado': 'ok',
      'modeloVersion': '20261101-111004',
      'umbral': 0.42,
      'metricas': {'roc_auc': 0.881, 'recall': 0.8, 'accuracy': 0.81},
    });
    expect(h.ok, isTrue);
    expect(h.auc, closeTo(0.881, 1e-9));
  });
}
