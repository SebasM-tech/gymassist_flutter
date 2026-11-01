import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/payments/domain/payment_domain.dart';
import 'package:uuid/uuid.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._db);
  final AppDatabase _db;

  Payment _map(PaymentRow r) => Payment(id: r.id, clientId: r.clientId, planId: r.planId, amountCop: r.amountCop, method: r.method, paidAt: r.paidAt, periodStart: r.periodStart, periodEnd: r.periodEnd, registeredBy: r.registeredBy, note: r.note);

  @override
  Stream<List<Payment>> watchByClient(String clientId) => (_db.select(_db.payments)
        ..where((t) => t.clientId.equals(clientId))
        ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
      .watch()
      .map((rows) => rows.map(_map).toList());

  @override
  Future<List<Payment>> listByGym(String gymId) async {
    final q = _db.select(_db.payments).join([innerJoin(_db.clients, _db.clients.id.equalsExp(_db.payments.clientId))])
      ..where(_db.clients.gymId.equals(gymId));
    return (await q.get()).map((r) => _map(r.readTable(_db.payments))).toList();
  }

  @override
  Future<Payment> add({
    required String clientId,
    required String? planId,
    required int amountCop,
    required PaymentMethod method,
    required DateTime paidAt,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String registeredBy,
    String? note,
  }) async {
    final id = const Uuid().v4();
    await _db.into(_db.payments).insert(PaymentsCompanion.insert(
      id: id,
      clientId: clientId,
      planId: Value(planId),
      amountCop: amountCop,
      method: method,
      paidAt: paidAt,
      periodStart: periodStart,
      periodEnd: periodEnd,
      registeredBy: registeredBy,
      note: Value(note),
    ));
    return Payment(id: id, clientId: clientId, planId: planId, amountCop: amountCop, method: method, paidAt: paidAt, periodStart: periodStart, periodEnd: periodEnd, registeredBy: registeredBy, note: note);
  }
}
