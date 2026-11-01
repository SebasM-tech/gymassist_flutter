import 'package:gymassist/core/domain/enums.dart';

class AppUser {
  const AppUser({required this.id, required this.username, required this.email, required this.role});
  final String id, username, email;
  final UserRole role;
}

class UserCredentials {
  const UserCredentials({required this.user, required this.passwordHash});
  final AppUser user;
  final String passwordHash;
}

abstract interface class UserRepository {
  Future<AppUser?> findById(String id);
  Future<UserCredentials?> credentialsByUsername(String username);
  Future<bool> usernameTaken(String username, {String? exceptUserId});
  Future<bool> emailTaken(String email, {String? exceptUserId});
  Future<AppUser> create({required String username, required String email, required String passwordHash, required UserRole role});
  Future<void> update(String id, {String? username, String? email, String? passwordHash});
}
