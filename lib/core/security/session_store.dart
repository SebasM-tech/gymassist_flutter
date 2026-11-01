import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymassist/core/domain/enums.dart';

class Session {
  const Session({required this.userId, required this.role, required this.lastActiveAt});
  final String userId;
  final UserRole role;
  final DateTime lastActiveAt;

  Session touched(DateTime now) => Session(userId: userId, role: role, lastActiveAt: now);

  Map<String, dynamic> toJson() => {'u': userId, 'r': role.name, 't': lastActiveAt.millisecondsSinceEpoch};

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        userId: j['u'] as String,
        role: UserRole.values.byName(j['r'] as String),
        lastActiveAt: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
      );
}

abstract interface class SessionStore {
  Future<Session?> read();
  Future<void> write(Session session);
  Future<void> clear();
}

/// Reemplaza la sesión en Redis: se guarda cifrada en Keychain/Keystore.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  static const _key = 'gymassist_session';

  @override
  Future<Session?> read() async {
    final raw = await _s.read(key: _key);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(Session session) => _s.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _s.delete(key: _key);
}

class InMemorySessionStore implements SessionStore {
  Session? _session;
  @override
  Future<Session?> read() async => _session;
  @override
  Future<void> write(Session session) async => _session = session;
  @override
  Future<void> clear() async => _session = null;
}
