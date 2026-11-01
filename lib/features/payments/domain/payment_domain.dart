import 'package:gymassist/core/domain/enums.dart';

class Payment {
  const Payment({required this.id, required this.clientId, required this.planId, required this.amountCop, required this.method, required this.paidAt, required this.periodStart, required this.periodEnd, required this.registeredBy, required this.note});
  final String id, clientId, registeredBy;
  final String? planId, note;
  final int amountCop;
  final PaymentMethod method;
  final DateTime paidAt, periodStart, periodEnd;
}

abstract interface class PaymentRepository {
  Stream<List<Payment>> watchByClient(String clientId);
  Future<List<Payment>> listByGym(String gymId);
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
  });
}
