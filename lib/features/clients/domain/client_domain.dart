import 'package:gymassist/features/clients/domain/client_status.dart';

class Client {
  const Client({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.planId,
    required this.planName,
    required this.fullName,
    required this.email,
    required this.username,
    required this.documentId,
    required this.phone,
    required this.status,
    required this.joinedAt,
    required this.membershipStart,
    required this.membershipEnd,
    required this.missedCount,
  });

  final String id, userId, gymId, fullName, email, username, documentId, phone;
  final String? planId, planName;
  final ClientStatus status;
  final DateTime joinedAt;
  final DateTime? membershipStart, membershipEnd;
  final int missedCount;
}

abstract interface class ClientRepository {
  Stream<List<Client>> watchByGym(String gymId);
  Future<List<Client>> listByGym(String gymId);
  Future<List<Client>> listByStatus(ClientStatus status);
  Future<Client?> findById(String id);
  Future<Client?> findByUserId(String userId);

  /// Crea usuario + cliente en una sola transacción.
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
  });

  Future<void> setStatus(String id, ClientStatus status);
  Future<void> setMembership(String id, {required ClientStatus status, required DateTime start, required DateTime end});
  Future<void> setPlan(String id, String planId);
  Future<void> addMissed(String id, int count);
}
