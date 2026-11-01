import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:gymassist/core/database/converters.dart';
import 'package:gymassist/core/database/tables.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, Gyms, Plans, Clients, Attendances, Measurements, Routines, RoutinePhotos, Payments, OutboxOps])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// SQLite local sin conexión.
  /// - Android/iOS/macOS: archivo en el directorio de documentos de la app.
  /// - Chrome (web): SQLite compilado a WebAssembly (web/sqlite3.wasm + web/drift_worker.js),
  ///   guardado en IndexedDB/OPFS del navegador.
  /// Este archivo NO debe importar `package:drift/native.dart` (usa dart:ffi y rompe la compilación web).
  factory AppDatabase.open() => AppDatabase(driftDatabase(
        name: 'gymassist',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
          onResult: (result) {
            if (result.missingFeatures.isNotEmpty) {
              debugPrint('Drift web: ${result.chosenImplementation} (faltan: ${result.missingFeatures})');
            }
          },
        ),
      ));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Ejemplo para v2:  if (from < 2) await m.addColumn(clients, clients.newColumn);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

class DriftTransactor implements Transactor {
  DriftTransactor(this._db);
  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
