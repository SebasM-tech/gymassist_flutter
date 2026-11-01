import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/attendance/domain/attendance_domain.dart';
import 'package:uuid/uuid.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._db);
  final AppDatabase _db;

  Attendance _map(AttendanceRow r) => Attendance(id: r.id, clientId: r.clientId, date: r.date, muscles: r.muscles);

  @override
  Stream<List<Attendance>> watchByClient(String clientId) => (_db.select(_db.attendances)
        ..where((t) => t.clientId.equals(clientId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch()
      .map((rows) => rows.map(_map).toList());

  @override
  Future<DateTime?> lastDate(String clientId) async {
    final maxDate = _db.attendances.date.max();
    final q = _db.selectOnly(_db.attendances)
      ..addColumns([maxDate])
      ..where(_db.attendances.clientId.equals(clientId));
    final row = await q.getSingleOrNull();
    return row?.read(maxDate);
  }

  @override
  Future<Attendance> add(String clientId, DateTime date, List<MuscleGroup> muscles) async {
    final id = const Uuid().v4();
    await _db.into(_db.attendances).insert(AttendancesCompanion.insert(id: id, clientId: clientId, date: date, muscles: muscles));
    return Attendance(id: id, clientId: clientId, date: date, muscles: muscles);
  }
}
