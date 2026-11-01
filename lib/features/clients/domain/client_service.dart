import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/core/security/password_hasher.dart';
import 'package:gymassist/core/utils/date_utils.dart';
import 'package:gymassist/features/auth/domain/user.dart';
import 'package:gymassist/features/clients/domain/client_domain.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';
import 'package:gymassist/features/payments/domain/payment_domain.dart';
import 'package:gymassist/features/plans/domain/plan_domain.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Reglas que antes vivían en `ClienteService`, `AdminController` y `PaymentController`.
class ClientService {
  ClientService({
    required this.clients,
    required this.plans,
    required this.users,
    required this.payments,
    required this.hasher,
    required this.tx,
    required this.clock,
  });

  final ClientRepository clients;
  final PlanRepository plans;
  final UserRepository users;
  final PaymentRepository payments;
  final PasswordHasher hasher;
  final Transactor tx;
  final Clock clock;

  Future<Result<Client>> createClient({
    required String gymId,
    required String planId,
    required String fullName,
    required String email,
    required String documentId,
    required String phone,
    required String username,
    required String password,
  }) async {
    final u = username.trim().toLowerCase();
    final e = email.trim().toLowerCase();
    if ([fullName, documentId, phone, u].any((s) => s.trim().isEmpty)) {
      return fail(FailureType.validation, 'Completa todos los datos del cliente.');
    }
    if (!_emailRe.hasMatch(e)) return fail(FailureType.validation, 'El correo no es válido.');
    if (password.length < 6) return fail(FailureType.validation, 'La contraseña debe tener al menos 6 caracteres.');
    final plan = await plans.findById(planId);
    if (plan == null || plan.gymId != gymId) return fail(FailureType.notFound, 'El plan no existe.');
    if (await users.emailTaken(e)) return fail(FailureType.conflict, 'El correo electrónico ya está en uso.');
    if (await users.usernameTaken(u)) return fail(FailureType.conflict, 'El nombre de usuario ya está en uso.');

    final today = dateOnly(clock());
    return Ok(await clients.createWithUser(
      gymId: gymId,
      planId: planId,
      fullName: fullName.trim(),
      documentId: documentId.trim(),
      phone: phone.trim(),
      username: u,
      email: e,
      passwordHash: await hasher.hash(password),
      joinedAt: today,
      membershipStart: today,
      membershipEnd: addMonths(today, plan.durationMonths),
    ));
  }

  /// Botón "Registrar pago": activa la membresía y guarda el pago (el backend original no lo guardaba).
  Future<Result<Client>> registerPayment({
    required String clientId,
    required String registeredByUserId,
    PaymentMethod method = PaymentMethod.efectivo,
    String? note,
  }) async {
    final c = await clients.findById(clientId);
    if (c == null) return fail(FailureType.notFound, 'Cliente no encontrado.');
    if (c.status == ClientStatus.suspendido) return fail(FailureType.forbidden, 'El cliente está suspendido. Actívalo antes de registrar un pago.');
    if (c.status == ClientStatus.activo) return fail(FailureType.conflict, 'La membresía del cliente ya está activa.');
    final planId = c.planId;
    final plan = planId == null ? null : await plans.findById(planId);
    if (plan == null) return fail(FailureType.validation, 'El cliente no tiene un plan asignado.');

    final now = clock();
    final start = dateOnly(now);
    final end = addMonths(start, plan.durationMonths);
    await tx.run(() async {
      await payments.add(
        clientId: clientId,
        planId: plan.id,
        amountCop: plan.priceCop,
        method: method,
        paidAt: now,
        periodStart: start,
        periodEnd: end,
        registeredBy: registeredByUserId,
        note: note,
      );
      await clients.setMembership(clientId, status: ClientStatus.activo, start: start, end: end);
    });
    return Ok((await clients.findById(clientId))!);
  }

  Future<Result<void>> stopMembership(String clientId) => _transition(clientId, from: {ClientStatus.activo}, to: ClientStatus.pendiente);
  Future<Result<void>> suspend(String clientId) => _transition(clientId, from: {ClientStatus.activo, ClientStatus.pendiente}, to: ClientStatus.suspendido);
  Future<Result<void>> activate(String clientId) => _transition(clientId, from: {ClientStatus.suspendido}, to: ClientStatus.activo);

  Future<Result<void>> _transition(String id, {required Set<ClientStatus> from, required ClientStatus to}) async {
    final c = await clients.findById(id);
    if (c == null) return fail(FailureType.notFound, 'Cliente no encontrado.');
    if (!from.contains(c.status)) return fail(FailureType.conflict, 'Esa acción no aplica al estado actual del cliente.');
    await clients.setStatus(id, to);
    return const Ok(null);
  }

  /// El cliente solo puede cambiar de plan mientras está pendiente de pago.
  Future<Result<void>> changePlan(String clientId, String planId) async {
    final c = await clients.findById(clientId);
    if (c == null) return fail(FailureType.notFound, 'Cliente no encontrado.');
    if (c.status != ClientStatus.pendiente) return fail(FailureType.forbidden, 'Solo puedes cambiar de plan mientras tu pago está pendiente.');
    final plan = await plans.findById(planId);
    if (plan == null || plan.gymId != c.gymId) return fail(FailureType.notFound, 'El plan no existe.');
    await clients.setPlan(clientId, planId);
    return const Ok(null);
  }

  /// Reemplaza al `@Scheduled(cron = "0 0 6 * * ?")`. Se ejecuta al abrir la app, al volver a primer plano y en segundo plano.
  /// Devuelve cuántas membresías venció.
  Future<int> expireSubscriptions() async {
    final today = dateOnly(clock());
    var expired = 0;
    for (final c in await clients.listByStatus(ClientStatus.activo)) {
      final end = c.membershipEnd;
      if (end != null && !dateOnly(end).isAfter(today)) {
        await clients.setStatus(c.id, ClientStatus.pendiente);
        expired++;
      }
    }
    return expired;
  }
}
