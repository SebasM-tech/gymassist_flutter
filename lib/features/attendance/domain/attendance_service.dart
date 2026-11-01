import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/core/utils/date_utils.dart';
import 'package:gymassist/features/attendance/domain/attendance_domain.dart';
import 'package:gymassist/features/clients/domain/client_domain.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

class AttendanceService {
  AttendanceService({required this.attendances, required this.clients, required this.tx, required this.clock});
  final AttendanceRepository attendances;
  final ClientRepository clients;
  final Transactor tx;
  final Clock clock;

  /// Regla original (`registrarAsistencia`): si pasaron N días desde la última asistencia, suma N-1 inasistencias.
  /// Se agrega: una sola asistencia por día y solo con membresía activa.
  Future<Result<Attendance>> register({required String clientId, required List<MuscleGroup> muscles, DateTime? date}) async {
    if (muscles.isEmpty) return fail(FailureType.validation, 'Debes seleccionar al menos un músculo trabajado.');
    final client = await clients.findById(clientId);
    if (client == null) return fail(FailureType.notFound, 'Cliente no encontrado.');
    if (client.status != ClientStatus.activo) return fail(FailureType.forbidden, 'Tu membresía no está activa.');

    final day = dateOnly(date ?? clock());
    final last = await attendances.lastDate(clientId);
    var missed = 0;
    if (last != null) {
      final gap = daysBetween(last, day);
      if (gap == 0) return fail(FailureType.conflict, 'Ya registraste tu asistencia de hoy.');
      if (gap < 0) return fail(FailureType.validation, 'La fecha es anterior a tu última asistencia.');
      missed = gap > 1 ? gap - 1 : 0;
    }
    final saved = await tx.run(() async {
      final a = await attendances.add(clientId, day, muscles);
      if (missed > 0) await clients.addMissed(clientId, missed);
      return a;
    });
    return Ok(saved);
  }
}
