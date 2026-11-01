import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/features/plans/domain/plan_domain.dart';
import 'package:uuid/uuid.dart';

class PlanRepositoryImpl implements PlanRepository {
  PlanRepositoryImpl(this._db);
  final AppDatabase _db;

  Plan _map(PlanRow r) => Plan(id: r.id, gymId: r.gymId, name: r.name, description: r.description, priceCop: r.priceCop, durationMonths: r.durationMonths);

  @override
  Stream<List<PlanSummary>> watchByGym(String gymId) {
    final subs = _db.clients.id.count();
    final q = _db.select(_db.plans).join([leftOuterJoin(_db.clients, _db.clients.planId.equalsExp(_db.plans.id))])
      ..where(_db.plans.gymId.equals(gymId) & _db.plans.deletedAt.isNull())
      ..addColumns([subs])
      ..groupBy([_db.plans.id])
      ..orderBy([OrderingTerm.asc(_db.plans.name)]);
    return q.watch().map((rows) => [
          for (final r in rows) PlanSummary(plan: _map(r.readTable(_db.plans)), subscribers: r.read(subs) ?? 0),
        ]);
  }

  @override
  Future<List<Plan>> listByGym(String gymId) async {
    final rows = await (_db.select(_db.plans)
          ..where((t) => t.gymId.equals(gymId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_map).toList();
  }

  @override
  Future<Plan?> findById(String id) async {
    final r = await (_db.select(_db.plans)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Plan> create({required String gymId, required String name, required String description, required int priceCop, required int durationMonths}) async {
    final id = const Uuid().v4();
    await _db.into(_db.plans).insert(PlansCompanion.insert(id: id, gymId: gymId, name: name, description: description, priceCop: priceCop, durationMonths: durationMonths));
    return Plan(id: id, gymId: gymId, name: name, description: description, priceCop: priceCop, durationMonths: durationMonths);
  }

  @override
  Future<void> update(Plan plan) async {
    await (_db.update(_db.plans)..where((t) => t.id.equals(plan.id))).write(PlansCompanion(
      name: Value(plan.name),
      description: Value(plan.description),
      priceCop: Value(plan.priceCop),
      durationMonths: Value(plan.durationMonths),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> delete(String id) => _db.transaction(() async {
        await (_db.update(_db.plans)..where((t) => t.id.equals(id))).write(PlansCompanion(deletedAt: Value(DateTime.now())));
        await (_db.update(_db.clients)..where((t) => t.planId.equals(id))).write(ClientsCompanion(planId: const Value<String?>(null)));
      });
}
