import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/features/predictions/data/prediction_api_client.dart';
import 'package:gymassist/features/predictions/domain/prediction_domain.dart';

final predictionApiProvider = Provider<PredictionApiClient>((ref) {
  final api = PredictionApiClient();
  ref.onDispose(api.close);
  return api;
});

/// Flujo completo: Spring Boot (clientes reales de MongoDB) -> FastAPI (red LSTM en TensorFlow) -> pantalla.
/// `ref.invalidate(predictionsReportProvider)` vuelve a consultar.
final predictionsReportProvider = FutureProvider.autoDispose<PredictionsReport>((ref) async {
  final ml = ref.watch(predictionApiProvider);
  final health = await ml.health();
  if (!health.ok) {
    throw const PredictionApiException('La API está encendida pero no tiene un modelo entrenado. Ejecuta: python -m scripts.entrenar');
  }
  final clientes = await ref.watch(gymApiProvider).clientesParaPrediccion();
  final contactos = {for (final c in clientes) '${c['id']}': c};
  final now = DateTime.now();
  final raw = await ml.predictBatch(clientes, fechaReferencia: now);
  final items = [
    for (final r in raw)
      ChurnPrediction.fromJson(
        r,
        correo: '${contactos['${r['id']}']?['correo'] ?? ''}',
        telefono: '${contactos['${r['id']}']?['telefono'] ?? ''}',
      ),
  ]..sort((a, b) => b.probabilidadAbandono.compareTo(a.probabilidadAbandono));
  return PredictionsReport(health: health, items: items, generatedAt: now);
});
