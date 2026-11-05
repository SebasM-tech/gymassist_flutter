import 'package:flutter/foundation.dart';

/// Dirección de la API de predicción (FastAPI + TensorFlow, carpeta `prediccion-ml/` del repo GymAssist2.0).
///
/// Se puede cambiar sin tocar código:
///   flutter run -d chrome --dart-define=ML_API_URL=http://localhost:8000
///   flutter run -d <android> --dart-define=ML_API_URL=http://192.168.1.50:8000   (celular real, misma Wi-Fi)
///
/// Si no se indica, se usa:
///   - Emulador de Android: http://10.0.2.2:8000 (10.0.2.2 es el "localhost" del PC visto desde el emulador)
///   - Chrome, Windows, macOS, iOS simulador: http://localhost:8000
class ApiConfig {
  ApiConfig._();

  static const _fromEnv = String.fromEnvironment('ML_API_URL');

  static String get mlApiBaseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv.endsWith('/') ? _fromEnv.substring(0, _fromEnv.length - 1) : _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static const _springFromEnv = String.fromEnvironment('SPRING_API_URL');

  /// Backend Spring Boot (MongoDB, S3, Mercado Pago). Por defecto el de Railway.
  ///   flutter run -d chrome --dart-define=SPRING_API_URL=http://localhost:8080   (backend local)
  static String get springApiBaseUrl {
    const def = 'https://gymassist20-production.up.railway.app';
    final v = _springFromEnv.isNotEmpty ? _springFromEnv : def;
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  static const springTimeout = Duration(seconds: 30);

  /// La red LSTM + la explicación por oclusión tardan un poco con muchos clientes.
  static const predictTimeout = Duration(seconds: 60);
  static const healthTimeout = Duration(seconds: 5);
}
