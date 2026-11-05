import 'package:drift/drift.dart';
import 'package:gymassist/core/database/app_database.dart';

/// Datos de contacto que no viajan a la API pero se muestran en la tarjeta.
class ClientContact {
  const ClientContact({required this.correo, required this.telefono});
  final String correo, telefono;
}

class ChurnPayload {
  const ChurnPayload({required this.clientes, required this.contactos});
  final List<Map<String, dynamic>> clientes; // JSON para FastAPI
  final Map<String, ClientContact> contactos; // por id de cliente
}

/// Lee los clientes de la base local (Drift/SQLite) y arma el JSON que espera la API de Python:
/// fechas de membresía, plan, asistencias (con músculos) y mediciones de peso/estatura.
/// Con eso Python calcula la secuencia semanal (entrada de la LSTM) y las 14 variables tabulares.
class ChurnPayloadBuilder {
  ChurnPayloadBuilder(this._db);
  final AppDatabase _db;

  static String? _d(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<ChurnPayload> build({String? gymId}) async {
    final clientsQ = _db.select(_db.clients)..where((c) => c.deletedAt.isNull());
    if (gymId != null) clientsQ.where((c) => c.gymId.equals(gymId));
    final clients = await clientsQ.get();
    if (clients.isEmpty) return const ChurnPayload(clientes: [], contactos: {});

    final ids = clients.map((c) => c.id).toList();
    final plans = {for (final p in await _db.select(_db.plans).get()) p.id: p};
    final users = {for (final u in await _db.select(_db.users).get()) u.id: u};

    final atts = await (_db.select(_db.attendances)
          ..where((a) => a.clientId.isIn(ids) & a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.date)]))
        .get();
    final meas = await (_db.select(_db.measurements)
          ..where((m) => m.clientId.isIn(ids) & m.deletedAt.isNull())
          ..orderBy([(m) => OrderingTerm.asc(m.measuredAt)]))
        .get();

    final attsBy = <String, List<AttendanceRow>>{};
    for (final a in atts) {
      (attsBy[a.clientId] ??= []).add(a);
    }
    final measBy = <String, List<MeasurementRow>>{};
    for (final m in meas) {
      (measBy[m.clientId] ??= []).add(m);
    }

    final clientes = <Map<String, dynamic>>[];
    final contactos = <String, ClientContact>{};
    for (final c in clients) {
      final plan = c.planId == null ? null : plans[c.planId];
      clientes.add({
        'id': c.id,
        'nombre': c.fullName,
        'estado': c.status.name.toUpperCase(), // ACTIVO / PENDIENTE / SUSPENDIDO
        'fechaIngreso': _d(c.joinedAt),
        'fechaInicioMembresia': _d(c.membershipStart),
        'fechaFinMembresia': _d(c.membershipEnd),
        'tipoPlan': plan?.name ?? 'Mensual',
        'duracionPlanMeses': plan?.durationMonths ?? 1,
        'precioPlan': plan?.priceCop ?? 0,
        'asistencias': [
          for (final a in attsBy[c.id] ?? const <AttendanceRow>[])
            {'fecha': _d(a.date), 'musculos': [for (final m in a.muscles) m.name]},
        ],
        'mediciones': [
          for (final m in measBy[c.id] ?? const <MeasurementRow>[])
            {'fecha': _d(m.measuredAt), 'peso': m.weightKg, 'estatura': m.heightM},
        ],
      });
      contactos[c.id] = ClientContact(correo: users[c.userId]?.email ?? '', telefono: c.phone);
    }
    return ChurnPayload(clientes: clientes, contactos: contactos);
  }
}
