import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/features/gym_setup/domain/gym_domain.dart';
import 'package:uuid/uuid.dart';

class GymRepositoryImpl implements GymRepository {
  GymRepositoryImpl(this._db);
  final AppDatabase _db;

  Gym _map(GymRow r) => Gym(id: r.id, adminUserId: r.adminUserId, name: r.name, nit: r.nit, address: r.address, description: r.description, bankAccount: r.bankAccount);

  @override
  Future<Gym?> findByAdmin(String adminUserId) async {
    final r = await (_db.select(_db.gyms)..where((t) => t.adminUserId.equals(adminUserId) & t.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Gym?> findById(String id) async {
    final r = await (_db.select(_db.gyms)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Gym> create({required String adminUserId, required String name, required String nit, required String address, required String description, required String bankAccount}) async {
    final id = const Uuid().v4();
    await _db.into(_db.gyms).insert(GymsCompanion.insert(id: id, adminUserId: adminUserId, name: name, nit: nit, address: address, description: description, bankAccount: bankAccount));
    return Gym(id: id, adminUserId: adminUserId, name: name, nit: nit, address: address, description: description, bankAccount: bankAccount);
  }
}
