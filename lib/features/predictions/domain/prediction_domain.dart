/// Modelos de la respuesta de la API FastAPI (`POST /predecir/lote` y `GET /salud`).
library;

double _toDouble(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Una variable que explica la predicción (explicación por oclusión, calculada en Python).
class ChurnFactor {
  const ChurnFactor({required this.variable, required this.factor, required this.descripcion, required this.impacto, required this.efecto});

  final String variable; // nombre técnico, ej. "dias_ultima_visita"
  final String factor; // nombre legible, ej. "Días desde la última visita"
  final String descripcion; // frase para el admin, ej. "Lleva 21 días sin venir"
  final double impacto; // >0 aumenta el riesgo, <0 lo reduce (en puntos de probabilidad)
  final String efecto;

  bool get aumentaRiesgo => impacto > 0;

  factory ChurnFactor.fromJson(Map<String, dynamic> j) => ChurnFactor(
        variable: '${j['variable'] ?? ''}',
        factor: '${j['factor'] ?? j['variable'] ?? ''}',
        descripcion: '${j['descripcion'] ?? ''}',
        impacto: _toDouble(j['impacto']),
        efecto: '${j['efecto'] ?? ''}',
      );
}

/// Predicción de deserción de un cliente, tal como la devuelve la red neuronal.
class ChurnPrediction {
  const ChurnPrediction({
    required this.id,
    required this.nombre,
    required this.probabilidadAbandono,
    required this.seVa,
    required this.riesgo,
    required this.factores,
    required this.recomendacion,
    required this.asistenciaSemanal,
    required this.asistencias4Semanas,
    required this.pagoAlDia,
    required this.antiguedadMeses,
    required this.tipoPlan,
    this.correo = '',
    this.telefono = '',
  });

  final String id, nombre, riesgo, recomendacion, tipoPlan, correo, telefono;
  final double probabilidadAbandono; // 0..1
  final bool seVa; // prediccion == "Se va"
  final List<ChurnFactor> factores;
  final List<int> asistenciaSemanal; // 12 semanas, de la más antigua a la más reciente
  final int asistencias4Semanas, antiguedadMeses;
  final bool pagoAlDia;

  bool get renovara => !seVa;
  int get porcentaje => (probabilidadAbandono * 100).round();

  factory ChurnPrediction.fromJson(Map<String, dynamic> j, {String correo = '', String telefono = ''}) {
    final f = (j['features'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ChurnPrediction(
      id: '${j['id']}',
      nombre: '${j['nombre'] ?? 'Cliente'}',
      probabilidadAbandono: _toDouble(j['probabilidadAbandono']),
      seVa: '${j['prediccion']}'.toLowerCase().contains('se va'),
      riesgo: '${j['riesgo'] ?? 'BAJO'}',
      factores: [for (final x in (j['factores'] as List? ?? const [])) ChurnFactor.fromJson((x as Map).cast<String, dynamic>())],
      recomendacion: '${j['recomendacion'] ?? ''}',
      asistenciaSemanal: [for (final x in (j['asistenciaSemanal'] as List? ?? const [])) _toInt(x)],
      asistencias4Semanas: _toInt(f['asistencias4Semanas']),
      pagoAlDia: '${f['pagoAlDia']}'.toLowerCase().startsWith('s'),
      antiguedadMeses: _toInt(f['antiguedadMeses']),
      tipoPlan: '${f['tipoPlan'] ?? '-'}',
      correo: correo,
      telefono: telefono,
    );
  }
}

/// Estado del modelo (`GET /salud`).
class ModelHealth {
  const ModelHealth({required this.ok, this.version, this.umbral, this.auc, this.recall, this.accuracy});

  final bool ok;
  final String? version;
  final double? umbral, auc, recall, accuracy;

  factory ModelHealth.fromJson(Map<String, dynamic> j) {
    final m = (j['metricas'] as Map?)?.cast<String, dynamic>() ?? const {};
    double? d(Object? v) => v is num ? v.toDouble() : null;
    return ModelHealth(
      ok: j['estado'] == 'ok',
      version: j['modeloVersion'] as String?,
      umbral: d(j['umbral']),
      auc: d(m['roc_auc']),
      recall: d(m['recall']),
      accuracy: d(m['accuracy']),
    );
  }
}

/// Resultado completo que consume la pantalla.
class PredictionsReport {
  const PredictionsReport({required this.health, required this.items, required this.generatedAt});
  final ModelHealth health;
  final List<ChurnPrediction> items;
  final DateTime generatedAt;
}

/// Error entendible para mostrar en pantalla.
class PredictionApiException implements Exception {
  const PredictionApiException(this.message, {this.apiOffline = false});
  final String message;
  final bool apiOffline;
  @override
  String toString() => message;
}
