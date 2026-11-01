import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/core/storage/file_storage.dart';

class RoutinePhoto {
  const RoutinePhoto({required this.id, required this.relativePath, required this.description, required this.sortOrder});
  final String id, relativePath, description;
  final int sortOrder;
}

class Routine {
  const Routine({required this.id, required this.gymId, required this.name, required this.group, required this.reps, required this.sets, required this.photos});
  final String id, gymId, name, reps, sets;
  final MuscleGroup group;
  final List<RoutinePhoto> photos;
}

class NewPhoto {
  const NewPhoto({required this.relativePath, required this.description});
  final String relativePath, description;
}

/// Foto elegida por el usuario (ruta temporal del selector de imágenes).
class PhotoInput {
  const PhotoInput({required this.sourcePath, required this.description});
  final String sourcePath, description;
}

abstract interface class RoutineRepository {
  Stream<List<Routine>> watchByGym(String gymId);
  Future<List<Routine>> listByGroup(String gymId, MuscleGroup group);
  Future<Routine?> findById(String id);
  Future<Routine> create({required String gymId, required String name, required MuscleGroup group, required String reps, required String sets, required List<NewPhoto> photos});

  /// Devuelve las rutas relativas de las fotos eliminadas para que el servicio borre los archivos.
  Future<List<String>> update(String id, {required String name, required MuscleGroup group, required String reps, required String sets, required Set<String> removePhotoIds, required List<NewPhoto> addPhotos});

  /// Borrado lógico; devuelve las rutas de las fotos para borrar los archivos.
  Future<List<String>> delete(String id);
}

class RoutineService {
  RoutineService(this._repo, this._storage);
  final RoutineRepository _repo;
  final FileStorage _storage;

  Failure? _validate(String name, String reps, String sets) =>
      [name, reps, sets].any((s) => s.trim().isEmpty) ? const Failure(FailureType.validation, 'Completa nombre, repeticiones y series.') : null;

  Future<List<NewPhoto>> _store(List<PhotoInput> inputs) async => [
        for (final i in inputs) NewPhoto(relativePath: await _storage.saveRoutineImage(i.sourcePath), description: i.description.trim()),
      ];

  Future<void> _deleteFiles(Iterable<String> paths) async {
    for (final p in paths) {
      await _storage.delete(p);
    }
  }

  Future<Result<Routine>> create({required String gymId, required String name, required MuscleGroup group, required String reps, required String sets, List<PhotoInput> photos = const []}) async {
    final bad = _validate(name, reps, sets);
    if (bad != null) return Err(bad);
    final stored = await _store(photos);
    try {
      return Ok(await _repo.create(gymId: gymId, name: name.trim(), group: group, reps: reps.trim(), sets: sets.trim(), photos: stored));
    } catch (_) {
      await _deleteFiles(stored.map((p) => p.relativePath)); // no dejar archivos huérfanos
      rethrow;
    }
  }

  Future<Result<Routine>> update(String id, {required String name, required MuscleGroup group, required String reps, required String sets, Set<String> removePhotoIds = const {}, List<PhotoInput> addPhotos = const []}) async {
    final bad = _validate(name, reps, sets);
    if (bad != null) return Err(bad);
    if (await _repo.findById(id) == null) return fail(FailureType.notFound, 'Rutina no encontrada.');
    final stored = await _store(addPhotos);
    try {
      final removed = await _repo.update(id, name: name.trim(), group: group, reps: reps.trim(), sets: sets.trim(), removePhotoIds: removePhotoIds, addPhotos: stored);
      await _deleteFiles(removed);
    } catch (_) {
      await _deleteFiles(stored.map((p) => p.relativePath));
      rethrow;
    }
    return Ok((await _repo.findById(id))!);
  }

  Future<Result<void>> delete(String id) async {
    if (await _repo.findById(id) == null) return fail(FailureType.notFound, 'Rutina no encontrada.');
    await _deleteFiles(await _repo.delete(id));
    return const Ok(null);
  }
}
