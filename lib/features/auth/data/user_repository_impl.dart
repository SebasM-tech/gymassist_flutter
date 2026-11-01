import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/auth/domain/user.dart';
import 'package:uuid/uuid.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._db);
  final AppDatabase _db;

  AppUser _map(UserRow r) => AppUser(id: r.id, username: r.username, email: r.email, role: r.role);

  @override
  Future<AppUser?> findById(String id) async {
    final r = await (_db.select(_db.users)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<UserCredentials?> credentialsByUsername(String username) async {
    final r = await (_db.select(_db.users)..where((t) => t.username.equals(username) & t.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : UserCredentials(user: _map(r), passwordHash: r.passwordHash);
  }

  @override
  Future<bool> usernameTaken(String username, {String? exceptUserId}) async {
    final q = _db.select(_db.users)
      ..where((t) => t.username.equals(username) & (exceptUserId == null ? const Constant(true) : t.id.equals(exceptUserId).not()));
    return (await q.get()).isNotEmpty;
  }

  @override
  Future<bool> emailTaken(String email, {String? exceptUserId}) async {
    final q = _db.select(_db.users)
      ..where((t) => t.email.equals(email) & (exceptUserId == null ? const Constant(true) : t.id.equals(exceptUserId).not()));
    return (await q.get()).isNotEmpty;
  }

  @override
  Future<AppUser> create({required String username, required String email, required String passwordHash, required UserRole role}) async {
    final id = const Uuid().v4();
    await _db.into(_db.users).insert(UsersCompanion.insert(id: id, username: username, email: email, passwordHash: passwordHash, role: role));
    return AppUser(id: id, username: username, email: email, role: role);
  }

  @override
  Future<void> update(String id, {String? username, String? email, String? passwordHash}) async {
    await (_db.update(_db.users)..where((t) => t.id.equals(id))).write(UsersCompanion(
      username: username == null ? const Value.absent() : Value(username),
      email: email == null ? const Value.absent() : Value(email),
      passwordHash: passwordHash == null ? const Value.absent() : Value(passwordHash),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
