import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/routines/domain/routine_domain.dart';
import 'package:uuid/uuid.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  RoutineRepositoryImpl(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<List<Routine>> _withPhotos(List<RoutineRow> rows) async {
    if (rows.isEmpty) return const [];
    final photos = await (_db.select(_db.routinePhotos)
          ..where((p) => p.routineId.isIn(rows.map((r) => r.id)))
          ..orderBy([(p) => OrderingTerm.asc(p.sortOrder)]))
        .get();
    return [
      for (final r in rows)
        Routine(
          id: r.id,
          gymId: r.gymId,
          name: r.name,
          group: r.muscleGroup,
          reps: r.reps,
          sets: r.sets,
          photos: [
            for (final p in photos.where((p) => p.routineId == r.id))
              RoutinePhoto(id: p.id, relativePath: p.relativePath, description: p.description, sortOrder: p.sortOrder),
          ],
        ),
    ];
  }

  SimpleSelectStatement<$RoutinesTable, RoutineRow> _routines(String gymId) => _db.select(_db.routines)
    ..where((t) => t.gymId.equals(gymId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.name)]);

  @override
  Stream<List<Routine>> watchByGym(String gymId) => _routines(gymId).watch().asyncMap(_withPhotos);

  @override
  Future<List<Routine>> listByGroup(String gymId, MuscleGroup group) async =>
      _withPhotos(await (_routines(gymId)..where((t) => t.muscleGroup.equalsValue(group))).get());

  @override
  Future<Routine?> findById(String id) async {
    final row = await (_db.select(_db.routines)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : (await _withPhotos([row])).first;
  }

  Future<void> _insertPhotos(String routineId, List<NewPhoto> photos, int startOrder) async {
    for (var i = 0; i < photos.length; i++) {
      await _db.into(_db.routinePhotos).insert(RoutinePhotosCompanion.insert(
        id: _uuid.v4(),
        routineId: routineId,
        relativePath: photos[i].relativePath,
        description: photos[i].description,
        sortOrder: Value(startOrder + i),
      ));
    }
  }

  @override
  Future<Routine> create({required String gymId, required String name, required MuscleGroup group, required String reps, required String sets, required List<NewPhoto> photos}) =>
      _db.transaction(() async {
        final id = _uuid.v4();
        await _db.into(_db.routines).insert(RoutinesCompanion.insert(id: id, gymId: gymId, name: name, muscleGroup: group, reps: reps, sets: sets));
        await _insertPhotos(id, photos, 0);
        return (await findById(id))!;
      });

  @override
  Future<List<String>> update(String id, {required String name, required MuscleGroup group, required String reps, required String sets, required Set<String> removePhotoIds, required List<NewPhoto> addPhotos}) =>
      _db.transaction(() async {
        await (_db.update(_db.routines)..where((t) => t.id.equals(id))).write(RoutinesCompanion(
          name: Value(name),
          muscleGroup: Value(group),
          reps: Value(reps),
          sets: Value(sets),
          updatedAt: Value(DateTime.now()),
        ));
        final removed = await (_db.select(_db.routinePhotos)..where((p) => p.id.isIn(removePhotoIds) & p.routineId.equals(id))).get();
        await (_db.delete(_db.routinePhotos)..where((p) => p.id.isIn(removePhotoIds) & p.routineId.equals(id))).go();
        final remaining = await (_db.select(_db.routinePhotos)..where((p) => p.routineId.equals(id))).get();
        final nextOrder = remaining.isEmpty ? 0 : remaining.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
        await _insertPhotos(id, addPhotos, nextOrder);
        return removed.map((p) => p.relativePath).toList();
      });

  @override
  Future<List<String>> delete(String id) => _db.transaction(() async {
        final photos = await (_db.select(_db.routinePhotos)..where((p) => p.routineId.equals(id))).get();
        await (_db.delete(_db.routinePhotos)..where((p) => p.routineId.equals(id))).go();
        await (_db.update(_db.routines)..where((t) => t.id.equals(id))).write(RoutinesCompanion(deletedAt: Value(DateTime.now())));
        return photos.map((p) => p.relativePath).toList();
      });
}
