import 'dart:async';
import 'dart:convert';

import 'package:gymassist/core/config/api_config.dart';
import 'package:gymassist/features/predictions/domain/prediction_domain.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP de la API de predicción hecha en Python (FastAPI + TensorFlow).
///
/// Endpoints que usa:
///   GET  /salud           -> estado y métricas del modelo
///   POST /predecir/lote   -> probabilidad de abandono + factores + recomendación por cliente
class PredictionApiClient {
  PredictionApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.mlApiBaseUrl;

  final http.Client _http;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<ModelHealth> health() async {
    final res = await _send(() => _http.get(_uri('/salud')).timeout(ApiConfig.healthTimeout));
    return ModelHealth.fromJson(_decode(res));
  }

  /// `clientes` es la lista en el formato que espera FastAPI (ver `Cliente` en prediccion-ml/app/main.py).
  /// Devuelve el JSON de cada resultado (la pantalla lo combina con correo y teléfono locales).
  Future<List<Map<String, dynamic>>> predictBatch(List<Map<String, dynamic>> clientes, {DateTime? fechaReferencia}) async {
    if (clientes.isEmpty) return const [];
    final body = jsonEncode({
      'clientes': clientes,
      if (fechaReferencia != null) 'fechaReferencia': fechaReferencia.toIso8601String().substring(0, 10),
    });
    final res = await _send(() => _http
        .post(_uri('/predecir/lote'), headers: const {'Content-Type': 'application/json'}, body: body)
        .timeout(ApiConfig.predictTimeout));
    final json = _decode(res);
    return [for (final r in (json['resultados'] as List? ?? const [])) (r as Map).cast<String, dynamic>()];
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call();
      if (res.statusCode == 503) {
        throw PredictionApiException(_detail(res) ?? 'La API está encendida pero no tiene un modelo entrenado. Ejecuta: python -m scripts.entrenar');
      }
      if (res.statusCode >= 400) {
        throw PredictionApiException('La API respondió ${res.statusCode}: ${_detail(res) ?? res.reasonPhrase ?? ''}');
      }
      return res;
    } on PredictionApiException {
      rethrow;
    } on TimeoutException {
      throw PredictionApiException('La API de predicción no respondió a tiempo ($baseUrl).', apiOffline: true);
    } on http.ClientException {
      throw PredictionApiException('No se pudo conectar con la API de predicción en $baseUrl.', apiOffline: true);
    } catch (e) {
      // SocketException (móvil/escritorio) y errores de red del navegador caen aquí.
      throw PredictionApiException('No se pudo conectar con la API de predicción en $baseUrl.', apiOffline: true);
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    throw const PredictionApiException('Respuesta inesperada de la API.');
  }

  String? _detail(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is Map && j['detail'] != null) return '${j['detail']}';
    } catch (_) {}
    return null;
  }

  void close() => _http.close();
}
