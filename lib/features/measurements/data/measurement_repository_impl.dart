import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/features/measurements/domain/measurement_domain.dart';
import 'package:uuid/uuid.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  MeasurementRepositoryImpl(this._db);
  final AppDatabase _db;

  Measurement _map(MeasurementRow r) => Measurement(id: r.id, clientId: r.clientId, weightKg: r.weightKg, heightM: r.heightM, measuredAt: r.measuredAt);

  @override
  Stream<List<Measurement>> watchByClient(String clientId) => (_db.select(_db.measurements)
        ..where((t) => t.clientId.equals(clientId))
        ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
      .watch()
      .map((rows) => rows.map(_map).toList());

  @override
  Future<Measurement?> latest(String clientId) async {
    final r = await (_db.select(_db.measurements)
          ..where((t) => t.clientId.equals(clientId))
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Measurement> add({required String clientId, required double weightKg, required double heightM, required DateTime measuredAt}) async {
    final id = const Uuid().v4();
    await _db.into(_db.measurements).insert(MeasurementsCompanion.insert(id: id, clientId: clientId, weightKg: weightKg, heightM: heightM, measuredAt: measuredAt));
    return Measurement(id: id, clientId: clientId, weightKg: weightKg, heightM: heightM, measuredAt: measuredAt);
  }
}
