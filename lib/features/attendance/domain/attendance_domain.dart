import 'package:gymassist/core/domain/enums.dart';

class Attendance {
  const Attendance({required this.id, required this.clientId, required this.date, required this.muscles});
  final String id, clientId;
  final DateTime date;
  final List<MuscleGroup> muscles;
}

abstract interface class AttendanceRepository {
  Stream<List<Attendance>> watchByClient(String clientId);
  Future<DateTime?> lastDate(String clientId);
  Future<Attendance> add(String clientId, DateTime date, List<MuscleGroup> muscles);
}
