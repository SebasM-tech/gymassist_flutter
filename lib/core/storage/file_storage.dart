import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Reemplaza a S3. En la BD solo se guarda la ruta RELATIVA (en iOS la ruta absoluta del contenedor cambia entre versiones).
abstract interface class FileStorage {
  /// Copia la imagen al almacenamiento de la app y devuelve su ruta relativa.
  Future<String> saveRoutineImage(String sourcePath);
  Future<String> absolutePath(String relativePath);
  Future<void> delete(String relativePath);
}

class LocalFileStorage implements FileStorage {
  LocalFileStorage({Future<Directory> Function()? baseDir}) : _baseDir = baseDir ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _baseDir;
  static const _folder = 'routines';

  @override
  Future<String> saveRoutineImage(String sourcePath) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base.path, _folder));
    await dir.create(recursive: true);
    final name = '${const Uuid().v4()}${p.extension(sourcePath).toLowerCase()}';
    await File(sourcePath).copy(p.join(dir.path, name));
    return p.join(_folder, name);
  }

  @override
  Future<String> absolutePath(String relativePath) async => p.join((await _baseDir()).path, relativePath);

  @override
  Future<void> delete(String relativePath) async {
    final f = File(await absolutePath(relativePath));
    if (await f.exists()) await f.delete();
  }
}
