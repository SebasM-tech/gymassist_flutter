import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/clients/domain/client_domain.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';
import 'package:uuid/uuid.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl(this._db);
  final AppDatabase _db;

  /// clients + users (correo/usuario) + plans (nombre del plan, puede no existir).
  JoinedSelectStatement<HasResultSet, dynamic> _query() => _db.select(_db.clients).join([
        innerJoin(_db.users, _db.users.id.equalsExp(_db.clients.userId)),
        leftOuterJoin(_db.plans, _db.plans.id.equalsExp(_db.clients.planId)),
      ]);

  Client _map(TypedResult r) {
    final c = r.readTable(_db.clients);
    final u = r.readTable(_db.users);
    final p = r.readTableOrNull(_db.plans);
    return Client(
      id: c.id,
      userId: c.userId,
      gymId: c.gymId,
      planId: c.planId,
      planName: p?.name,
      fullName: c.fullName,
      email: u.email,
      username: u.username,
      documentId: c.documentId,
      phone: c.phone,
      status: c.status,
      joinedAt: c.joinedAt,
      membershipStart: c.membershipStart,
      membershipEnd: c.membershipEnd,
      missedCount: c.missedCount,
    );
  }

  @override
  Stream<List<Client>> watchByGym(String gymId) => (_query()
        ..where(_db.clients.gymId.equals(gymId))
        ..orderBy([OrderingTerm.asc(_db.clients.fullName)]))
      .watch()
      .map((rows) => rows.map(_map).toList());

  @override
  Future<List<Client>> listByGym(String gymId) async =>
      (await (_query()..where(_db.clients.gymId.equals(gymId))).get()).map(_map).toList();

  @override
  Future<List<Client>> listByStatus(ClientStatus status) async =>
      (await (_query()..where(_db.clients.status.equalsValue(status))).get()).map(_map).toList();

  @override
  Future<Client?> findById(String id) async {
    final r = await (_query()..where(_db.clients.id.equals(id))).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Client?> findByUserId(String userId) async {
    final r = await (_query()..where(_db.clients.userId.equals(userId))).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Client> createWithUser({
    required String gymId,
    required String planId,
    required String fullName,
    required String documentId,
    required String phone,
    required String username,
    required String email,
    required String passwordHash,
    required DateTime joinedAt,
    required DateTime membershipStart,
    required DateTime membershipEnd,
  }) =>
      _db.transaction(() async {
        const uuid = Uuid();
        final userId = uuid.v4();
        final clientId = uuid.v4();
        await _db.into(_db.users).insert(UsersCompanion.insert(id: userId, username: username, email: email, passwordHash: passwordHash, role: UserRole.client));
        await _db.into(_db.clients).insert(ClientsCompanion.insert(
          id: clientId,
          userId: userId,
          gymId: gymId,
          planId: Value(planId),
          fullName: fullName,
          documentId: documentId,
          phone: phone,
          status: ClientStatus.pendiente,
          joinedAt: joinedAt,
          membershipStart: Value(membershipStart),
          membershipEnd: Value(membershipEnd),
        ));
        return (await findById(clientId))!;
      });

  Future<void> _write(String id, ClientsCompanion c) =>
      (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(c.copyWith(updatedAt: Value(DateTime.now())));

  @override
  Future<void> setStatus(String id, ClientStatus status) => _write(id, ClientsCompanion(status: Value(status)));

  @override
  Future<void> setMembership(String id, {required ClientStatus status, required DateTime start, required DateTime end}) =>
      _write(id, ClientsCompanion(status: Value(status), membershipStart: Value(start), membershipEnd: Value(end)));

  @override
  Future<void> setPlan(String id, String planId) => _write(id, ClientsCompanion(planId: Value(planId)));

  @override
  Future<void> addMissed(String id, int count) => (_db.update(_db.clients)..where((t) => t.id.equals(id)))
      .write(ClientsCompanion.custom(missedCount: _db.clients.missedCount + Constant(count)));
}
