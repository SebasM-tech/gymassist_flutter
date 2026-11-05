import 'dart:async';
import 'dart:convert';

import 'package:gymassist/core/config/api_config.dart';
import 'package:http/http.dart' as http;

/// Error del backend con un mensaje listo para mostrar.
class ApiException implements Exception {
  const ApiException(this.message, {this.status = 0});
  final String message;
  final int status;

  bool get unauthorized => status == 401;
  bool get paymentRequired => status == 402;
  bool get conflict => status == 409;
  bool get offline => status == 0;

  @override
  String toString() => message;
}

/// Un archivo para subir en multipart (por ejemplo, la foto de una rutina).
class UploadFile {
  const UploadFile({required this.field, required this.bytes, required this.filename});
  final String field;
  final List<int> bytes;
  final String filename;
}

/// Cliente HTTP del backend Spring Boot (rutas /api/m/**). Agrega el token JWT en cada petición.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.springApiBaseUrl;

  final http.Client _http;
  final String baseUrl;
  String? token;

  /// Se llama cuando el backend responde 401 (token vencido): la sesión se cierra.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: (query == null || query.isEmpty) ? null : query);

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => _http.post(_uri(path),
      headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode(body ?? const {})));

  Future<dynamic> put(String path, [Object? body]) => _send(() => _http.put(_uri(path),
      headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode(body ?? const {})));

  Future<dynamic> delete(String path) => _send(() => _http.delete(_uri(path), headers: _headers));

  Future<dynamic> multipart(String path, {required Map<String, String> fields, Map<String, List<String>> listFields = const {}, List<UploadFile> files = const []}) {
    return _send(() async {
      final req = http.MultipartRequest('POST', _uri(path))..headers.addAll(_headers);
      req.fields.addAll(fields);
      // MultipartRequest.fields no admite claves repetidas: las listas van como partes de texto.
      for (final e in listFields.entries) {
        for (final v in e.value) {
          req.files.add(http.MultipartFile.fromString(e.key, v));
        }
      }
      for (final f in files) {
        req.files.add(http.MultipartFile.fromBytes(f.field, f.bytes, filename: f.filename));
      }
      return http.Response.fromStream(await _http.send(req));
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(ApiConfig.springTimeout);
    } on TimeoutException {
      throw const ApiException('El servidor no respondió a tiempo. Revisa tu conexión.');
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor ($baseUrl).');
    }
    final text = utf8.decode(res.bodyBytes);
    dynamic json;
    if (text.isNotEmpty) {
      try {
        json = jsonDecode(text);
      } catch (_) {
        json = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    if (res.statusCode == 401) onUnauthorized?.call();
    final msg = (json is Map && json['error'] != null)
        ? '${json['error']}'
        : switch (res.statusCode) {
            401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
            403 => 'No tienes permiso para esta acción.',
            404 => 'No encontrado.',
            _ => 'Error del servidor (${res.statusCode}).',
          };
    throw ApiException(msg, status: res.statusCode);
  }
}
