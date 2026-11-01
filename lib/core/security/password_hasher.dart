import 'dart:isolate';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract interface class PasswordHasher {
  Future<String> hash(String plain);
  Future<bool> verify(String plain, String hash);
}

/// bcrypt en un isolate en móvil/desktop (no bloquea la UI). En web no hay isolates: corre en el hilo principal.
/// Compatible con los hashes `$2a$` que generaba Spring Security.
class BcryptPasswordHasher implements PasswordHasher {
  const BcryptPasswordHasher({this.cost = 10});
  final int cost;

  @override
  Future<String> hash(String plain) {
    final rounds = cost;
    String work() => BCrypt.hashpw(plain, BCrypt.gensalt(logRounds: rounds));
    return kIsWeb ? Future(work) : Isolate.run(work);
  }

  @override
  Future<bool> verify(String plain, String hash) {
    bool work() => BCrypt.checkpw(plain, hash);
    return kIsWeb ? Future(work) : Isolate.run(work);
  }
}
