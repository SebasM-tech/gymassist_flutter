import 'package:flutter_test/flutter_test.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/core/utils/date_utils.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';
import 'support/test_env.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  test('crear cliente: queda pendiente y su vencimiento = hoy + duración del plan', () async {
    final s = await env.scenario();
    final c = (await env.clients.findById(s.clientId))!;
    expect(c.status, ClientStatus.pendiente);
    expect(c.membershipEnd, addMonths(DateTime(2025, 10, 1), 3));
    expect(c.planName, 'Trimestral');
  });

  test('crear cliente: correo o usuario repetidos => conflict', () async {
    final s = await env.scenario();
    final r = await env.clientService.createClient(gymId: s.gymId, planId: s.plan.id, fullName: 'Otro', email: 'carlos@x.com', documentId: '1', phone: '1', username: 'otro', password: 'cliente1');
    expect(r.failureOrNull?.type, FailureType.conflict);
  });

  test('registrar pago: activa, fija el periodo y guarda el pago', () async {
    final s = await env.scenario();
    await env.activate(s.clientId, s.adminId);
    final c = (await env.clients.findById(s.clientId))!;
    expect(c.status, ClientStatus.activo);
    expect(c.membershipEnd, DateTime(2026, 1, 1));
    final pays = await env.payments.listByGym(s.gymId);
    expect(pays.single.amountCop, 210000);
    // un segundo pago con la membresía activa se rechaza
    final again = await env.clientService.registerPayment(clientId: s.clientId, registeredByUserId: s.adminId);
    expect(again.failureOrNull?.type, FailureType.conflict);
  });

  test('un cliente suspendido no puede pagar', () async {
    final s = await env.scenario();
    await env.clientService.suspend(s.clientId);
    final r = await env.clientService.registerPayment(clientId: s.clientId, registeredByUserId: s.adminId);
    expect(r.failureOrNull?.type, FailureType.forbidden);
  });

  test('expireSubscriptions vence las membresías cuyo fin es hoy o anterior', () async {
    final s = await env.scenario();
    await env.activate(s.clientId, s.adminId);
    env.now = DateTime(2025, 12, 31);
    expect(await env.clientService.expireSubscriptions(), 0);
    env.now = DateTime(2026, 1, 1, 6);
    expect(await env.clientService.expireSubscriptions(), 1);
    expect((await env.clients.findById(s.clientId))!.status, ClientStatus.pendiente);
  });

  test('eliminar un plan deja a sus clientes sin plan', () async {
    final s = await env.scenario();
    await env.planService.delete(s.plan.id);
    expect((await env.clients.findById(s.clientId))!.planId, isNull);
    expect(await env.plans.listByGym(s.gymId), isEmpty);
  });

  test('cambiar de plan solo mientras el pago está pendiente', () async {
    final s = await env.scenario();
    final mensual = (await env.planService.create(gymId: s.gymId, name: 'Mensual', description: '1 mes', priceCop: 80000, durationMonths: 1)).valueOrNull!;
    expect((await env.clientService.changePlan(s.clientId, mensual.id)).isOk, isTrue);
    await env.activate(s.clientId, s.adminId);
    expect((await env.clientService.changePlan(s.clientId, s.plan.id)).failureOrNull?.type, FailureType.forbidden);
  });

  test('dashboard: ingresos salen de pagos reales', () async {
    final s = await env.scenario();
    await env.activate(s.clientId, s.adminId);
    final d = await env.dashboard.load(s.gymId);
    expect(d.incomeMonth, 210000);
    expect(d.activeClients, 1);
    expect(d.newClientsMonth, 1);
    expect(d.incomeTrend, hasLength(6));
    expect(d.incomeTrend.last.totalCop, 210000);
  });
}
