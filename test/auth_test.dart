import 'package:flutter_test/flutter_test.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/features/auth/domain/auth_service.dart';
import 'support/test_env.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  test('registerAdmin rechaza usuario duplicado (sin distinguir mayúsculas)', () async {
    await env.auth.registerAdmin(username: 'Admin', email: 'a@x.com', password: 'secreto1', confirmPassword: 'secreto1');
    final r = await env.auth.registerAdmin(username: 'ADMIN', email: 'b@x.com', password: 'secreto1', confirmPassword: 'secreto1');
    expect(r.failureOrNull?.type, FailureType.conflict);
  });

  test('registerAdmin valida contraseña corta y confirmación', () async {
    final short = await env.auth.registerAdmin(username: 'a', email: 'a@x.com', password: '123', confirmPassword: '123');
    final diff = await env.auth.registerAdmin(username: 'a', email: 'a@x.com', password: 'secreto1', confirmPassword: 'otra');
    expect(short.failureOrNull?.type, FailureType.validation);
    expect(diff.failureOrNull?.type, FailureType.validation);
  });

  test('login: credenciales incorrectas => unauthorized; admin sin gimnasio => gymSetup; con gimnasio => adminHome', () async {
    final admin = (await env.auth.registerAdmin(username: 'admin', email: 'a@x.com', password: 'secreto1', confirmPassword: 'secreto1')).valueOrNull!;
    expect((await env.auth.login('admin', 'mala')).failureOrNull?.type, FailureType.unauthorized);
    expect((await env.auth.login('admin', 'secreto1')).valueOrNull?.destination, LoginDestination.gymSetup);
    await env.gymService.register(adminUserId: admin.id, name: 'G', nit: '1', address: 'x', description: 'y', bankAccount: '2');
    expect((await env.auth.login('admin', 'secreto1')).valueOrNull?.destination, LoginDestination.adminHome);
  });

  test('login de cliente: pendiente => pago, activo => home, suspendido => bloqueado', () async {
    final s = await env.scenario();
    expect((await env.auth.login('carlos', 'cliente1')).valueOrNull?.destination, LoginDestination.clientPayment);
    await env.activate(s.clientId, s.adminId);
    expect((await env.auth.login('carlos', 'cliente1')).valueOrNull?.destination, LoginDestination.clientHome);
    await env.clientService.suspend(s.clientId);
    expect((await env.auth.login('carlos', 'cliente1')).failureOrNull?.type, FailureType.forbidden);
  });

  test('la sesión se cierra tras 30 minutos de inactividad', () async {
    await env.auth.registerAdmin(username: 'admin', email: 'a@x.com', password: 'secreto1', confirmPassword: 'secreto1');
    await env.auth.login('admin', 'secreto1');
    env.now = env.now.add(const Duration(minutes: 29));
    expect(await env.auth.restoreSession(), isNotNull); // renueva la actividad
    env.now = env.now.add(const Duration(minutes: 31));
    expect(await env.auth.restoreSession(), isNull);
  });
}
