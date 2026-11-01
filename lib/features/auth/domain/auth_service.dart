import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/core/security/password_hasher.dart';
import 'package:gymassist/core/security/session_store.dart';
import 'package:gymassist/features/auth/domain/user.dart';
import 'package:gymassist/features/clients/domain/client_domain.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';
import 'package:gymassist/features/gym_setup/domain/gym_domain.dart';

/// A dónde debe ir el usuario tras iniciar sesión (antes: `authenticationSuccessHandler` de SecurityConfig).
enum LoginDestination { gymSetup, adminHome, clientHome, clientPayment }

class LoginResult {
  const LoginResult(this.user, this.destination);
  final AppUser user;
  final LoginDestination destination;
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthService {
  AuthService({
    required this.users,
    required this.gyms,
    required this.clients,
    required this.hasher,
    required this.sessions,
    required this.clock,
  });

  final UserRepository users;
  final GymRepository gyms;
  final ClientRepository clients;
  final PasswordHasher hasher;
  final SessionStore sessions;
  final Clock clock;

  /// Igual que los 30 minutos de `spring.session.timeout` en Redis.
  static const sessionTimeout = Duration(minutes: 30);
  static const minPasswordLength = 6;

  Future<Result<AppUser>> registerAdmin({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final u = username.trim().toLowerCase();
    final e = email.trim().toLowerCase();
    if (u.isEmpty) return fail(FailureType.validation, 'El usuario es obligatorio.');
    if (!_emailRe.hasMatch(e)) return fail(FailureType.validation, 'El correo no es válido.');
    if (password.length < minPasswordLength) {
      return fail(FailureType.validation, 'La contraseña debe tener al menos $minPasswordLength caracteres.');
    }
    if (password != confirmPassword) return fail(FailureType.validation, 'Las contraseñas no coinciden.');
    if (await users.usernameTaken(u)) return fail(FailureType.conflict, 'El nombre de usuario ya está en uso.');
    if (await users.emailTaken(e)) return fail(FailureType.conflict, 'El correo ya está registrado.');
    final hash = await hasher.hash(password);
    return Ok(await users.create(username: u, email: e, passwordHash: hash, role: UserRole.admin));
  }

  Future<Result<LoginResult>> login(String username, String password) async {
    final cred = await users.credentialsByUsername(username.trim().toLowerCase());
    if (cred == null || !await hasher.verify(password, cred.passwordHash)) {
      return fail(FailureType.unauthorized, 'Usuario o contraseña incorrectos.');
    }
    final dest = await _destinationFor(cred.user);
    if (dest == null) {
      return fail(FailureType.forbidden, 'Tu cuenta está suspendida. Contacta al administrador.');
    }
    await sessions.write(Session(userId: cred.user.id, role: cred.user.role, lastActiveAt: clock()));
    return Ok(LoginResult(cred.user, dest));
  }

  Future<LoginDestination?> _destinationFor(AppUser user) async {
    switch (user.role) {
      case UserRole.admin:
        return await gyms.findByAdmin(user.id) == null ? LoginDestination.gymSetup : LoginDestination.adminHome;
      case UserRole.client:
        final c = await clients.findByUserId(user.id);
        if (c == null) return null;
        return switch (c.status) {
          ClientStatus.activo => LoginDestination.clientHome,
          ClientStatus.pendiente => LoginDestination.clientPayment,
          ClientStatus.suspendido => null,
        };
    }
  }

  /// Recupera la sesión al abrir la app; se cierra tras 30 min de inactividad.
  Future<AppUser?> restoreSession() async {
    final s = await sessions.read();
    if (s == null) return null;
    if (clock().difference(s.lastActiveAt) > sessionTimeout) {
      await sessions.clear();
      return null;
    }
    final user = await users.findById(s.userId);
    if (user == null) {
      await sessions.clear();
      return null;
    }
    await sessions.write(s.touched(clock()));
    return user;
  }

  Future<void> logout() => sessions.clear();

  /// Cuenta del cliente o del admin: correo, usuario y (opcional) contraseña.
  Future<Result<AppUser>> updateAccount({
    required String userId,
    required String email,
    String? username,
    String? newPassword,
    String? confirmPassword,
  }) async {
    final e = email.trim().toLowerCase();
    final u = username?.trim().toLowerCase();
    if (!_emailRe.hasMatch(e)) return fail(FailureType.validation, 'El correo no es válido.');
    if (u != null && u.isEmpty) return fail(FailureType.validation, 'El usuario es obligatorio.');
    final changingPassword = newPassword != null && newPassword.isNotEmpty;
    if (changingPassword) {
      if (newPassword.length < minPasswordLength) {
        return fail(FailureType.validation, 'La contraseña debe tener al menos $minPasswordLength caracteres.');
      }
      if (newPassword != confirmPassword) return fail(FailureType.validation, 'Las contraseñas no coinciden.');
    }
    if (await users.emailTaken(e, exceptUserId: userId)) return fail(FailureType.conflict, 'El correo ya está registrado.');
    if (u != null && await users.usernameTaken(u, exceptUserId: userId)) {
      return fail(FailureType.conflict, 'El nombre de usuario ya está en uso.');
    }
    await users.update(
      userId,
      email: e,
      username: u,
      passwordHash: changingPassword ? await hasher.hash(newPassword) : null,
    );
    final updated = await users.findById(userId);
    return updated == null ? fail(FailureType.notFound, 'Usuario no encontrado.') : Ok(updated);
  }
}
