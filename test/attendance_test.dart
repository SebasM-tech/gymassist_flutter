import 'package:flutter_test/flutter_test.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/domain/result.dart';
import 'support/test_env.dart';

void main() {
  late TestEnv env;
  late String clientId;
  setUp(() async {
    env = TestEnv();
    final s = await env.scenario();
    clientId = s.clientId;
    await env.activate(clientId, s.adminId);
  });
  tearDown(() => env.dispose());

  test('exige al menos un músculo', () async {
    final r = await env.attendanceService.register(clientId: clientId, muscles: []);
    expect(r.failureOrNull?.type, FailureType.validation);
  });

  test('solo con membresía activa', () async {
    await env.clientService.stopMembership(clientId);
    final r = await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.pecho]);
    expect(r.failureOrNull?.type, FailureType.forbidden);
  });

  test('suma N-1 inasistencias cuando pasan N días desde la última asistencia', () async {
    await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.pecho]); // 1-oct
    env.now = DateTime(2025, 10, 4, 18); // 3 días después => 2 inasistencias
    await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.espalda, MuscleGroup.biceps]);
    env.now = DateTime(2025, 10, 5, 8); // día consecutivo => 0
    await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.hombros]);
    expect((await env.clients.findById(clientId))!.missedCount, 2);
    expect((await env.attendances.watchByClient(clientId).first).length, 3);
  });

  test('no permite dos asistencias el mismo día', () async {
    await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.pecho]);
    final r = await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.espalda]);
    expect(r.failureOrNull?.type, FailureType.conflict);
  });

  test('los músculos se guardan y se leen como enums', () async {
    await env.attendanceService.register(clientId: clientId, muscles: [MuscleGroup.gluteos, MuscleGroup.cuadriceps]);
    final a = (await env.attendances.watchByClient(clientId).first).single;
    expect(a.muscles, [MuscleGroup.gluteos, MuscleGroup.cuadriceps]);
  });
}
