import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymassist/core/api/api_client.dart';
import 'package:gymassist/core/api/gym_api.dart';
import 'package:gymassist/core/api/models.dart';

/// Sesión con el backend Spring Boot (token JWT + datos del usuario).
class AppSession {
  const AppSession({required this.token, required this.username, required this.email, required this.role, this.tieneGimnasio = false, this.gym, this.cliente});

  final String token, username, email, role;
  final bool tieneGimnasio;
  final Gym? gym;
  final Cliente? cliente;

  bool get isAdmin => role == 'ADMIN';
  bool get isCliente => role == 'CLIENTE';

  factory AppSession.fromJson(Map<String, dynamic> j, String token) => AppSession(
        token: token,
        username: '${j['username'] ?? ''}',
        email: '${j['email'] ?? ''}',
        role: '${j['role'] ?? ''}',
        tieneGimnasio: j['tieneGimnasio'] == true,
        gym: j['gimnasio'] == null ? null : Gym.fromJson((j['gimnasio'] as Map).cast<String, dynamic>()),
        cliente: j['cliente'] == null ? null : Cliente.fromJson((j['cliente'] as Map).cast<String, dynamic>()),
      );
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final c = ApiClient();
  ref.onDispose(() => c.onUnauthorized = null);
  return c;
});

final gymApiProvider = Provider<GymApi>((ref) => GymApi(ref.watch(apiClientProvider)));

final sessionProvider = AsyncNotifierProvider<SessionController, AppSession?>(SessionController.new);

class SessionController extends AsyncNotifier<AppSession?> {
  static const _key = 'gymassist_token';
  final _storage = const FlutterSecureStorage();

  ApiClient get _client => ref.read(apiClientProvider);
  GymApi get _api => ref.read(gymApiProvider);

  @override
  Future<AppSession?> build() async {
    _client.onUnauthorized = () {
      // Token vencido o inválido: cerrar sesión sin esperar.
      if (state.valueOrNull != null) logout();
    };
    String? token;
    try {
      token = await _storage.read(key: _key);
    } catch (e) {
      debugPrint('No se pudo leer el token guardado: $e');
    }
    if (token == null || token.isEmpty) return null;
    _client.token = token;
    try {
      return AppSession.fromJson(await _api.me(), token);
    } on ApiException catch (e) {
      if (e.unauthorized) await _clearToken();
      return null;
    }
  }

  Future<AppSession> login(String username, String password) async {
    final j = await _api.login(username.trim(), password);
    return _start(j);
  }

  Future<AppSession> registerAdmin({required String username, required String email, required String password}) async {
    final j = await _api.registerAdmin(username: username.trim(), email: email.trim(), password: password);
    return _start(j);
  }

  /// Vuelve a pedir /me (por ejemplo, después de registrar el gimnasio o de pagar).
  Future<void> refresh() async {
    final s = state.valueOrNull;
    if (s == null) return;
    try {
      state = AsyncData(AppSession.fromJson(await _api.me(), s.token));
    } on ApiException catch (e) {
      if (e.unauthorized) await logout();
    }
  }

  Future<void> replaceToken(String token) async {
    _client.token = token;
    await _saveToken(token);
    await refresh();
  }

  Future<void> logout() async {
    _client.token = null;
    await _clearToken();
    state = const AsyncData(null);
  }

  Future<AppSession> _start(Map<String, dynamic> j) async {
    final token = '${j['token']}';
    _client.token = token;
    await _saveToken(token);
    final s = AppSession.fromJson(j, token);
    state = AsyncData(s);
    return s;
  }

  Future<void> _saveToken(String t) async {
    try {
      await _storage.write(key: _key, value: t);
    } catch (e) {
      debugPrint('No se pudo guardar el token: $e');
    }
  }

  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// Ruta de inicio según el rol y el estado.
String homeFor(AppSession s) {
  if (s.isAdmin) return s.tieneGimnasio ? '/admin' : '/gimnasio/registro';
  if (s.cliente != null && !s.cliente!.activo) return '/cliente/pago';
  return '/cliente';
}
