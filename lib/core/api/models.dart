import 'package:gymassist/core/config/api_config.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

/// Modelos de la API de Spring Boot (/api/m/**).
double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _s(Object? v) => v == null ? '' : '$v';
DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

class Gym {
  const Gym({required this.id, required this.nombre, required this.direccion, required this.descripcion, this.nit});
  final String id, nombre, direccion, descripcion;
  final int? nit;

  factory Gym.fromJson(Map<String, dynamic> j) => Gym(
        id: _s(j['id']),
        nombre: _s(j['nombre']),
        direccion: _s(j['direccion']),
        descripcion: _s(j['descripcion']),
        nit: j['nit'] == null ? null : _i(j['nit']),
      );
}

class Plan {
  const Plan({required this.id, required this.nombre, required this.descripcion, required this.precio, required this.duracionMeses, this.suscriptores = 0});
  final String id, nombre, descripcion;
  final double precio;
  final int duracionMeses, suscriptores;

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: _s(j['id']),
        nombre: _s(j['nombre']),
        descripcion: _s(j['descripcion']),
        precio: _d(j['precio']),
        duracionMeses: _i(j['duracionMeses']),
        suscriptores: _i(j['suscriptores']),
      );
}

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.username,
    required this.documento,
    required this.telefono,
    required this.estado,
    this.planId,
    this.planNombre,
    this.planPrecio,
    this.planDuracionMeses,
    this.fechaIngreso,
    this.fechaInicioMembresia,
    this.fechaFinMembresia,
    this.inasistencias = 0,
    this.totalAsistencias = 0,
  });

  final String id, nombre, correo, username, documento, telefono;
  final ClientStatus estado;
  final String? planId, planNombre;
  final double? planPrecio;
  final int? planDuracionMeses;
  final DateTime? fechaIngreso, fechaInicioMembresia, fechaFinMembresia;
  final int inasistencias, totalAsistencias;

  bool get activo => estado == ClientStatus.activo;

  static ClientStatus estadoDe(Object? v) => switch ('$v'.toUpperCase()) {
        'ACTIVO' => ClientStatus.activo,
        'SUSPENDIDO' => ClientStatus.suspendido,
        _ => ClientStatus.pendiente,
      };

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id: _s(j['id']),
        nombre: _s(j['nombre']),
        correo: _s(j['correo']),
        username: _s(j['username']),
        documento: _s(j['documento']),
        telefono: _s(j['telefono']),
        estado: estadoDe(j['estado']),
        planId: j['planId'] as String?,
        planNombre: j['planNombre'] as String?,
        planPrecio: j['planPrecio'] == null ? null : _d(j['planPrecio']),
        planDuracionMeses: j['planDuracionMeses'] == null ? null : _i(j['planDuracionMeses']),
        fechaIngreso: _date(j['fechaIngreso']),
        fechaInicioMembresia: _date(j['fechaInicioMembresia']),
        fechaFinMembresia: _date(j['fechaFinMembresia']),
        inasistencias: _i(j['inasistencias']),
        totalAsistencias: _i(j['totalAsistencias']),
      );
}

class Foto {
  const Foto({required this.url, required this.descripcion});
  final String url, descripcion;
}

class Rutina {
  const Rutina({required this.id, required this.nombre, required this.grupoMuscular, required this.repeticiones, required this.series, this.fotos = const []});
  final String id, nombre, grupoMuscular, repeticiones, series;
  final List<Foto> fotos;

  factory Rutina.fromJson(Map<String, dynamic> j) => Rutina(
        id: _s(j['id']),
        nombre: _s(j['nombre']),
        grupoMuscular: _s(j['grupoMuscular']),
        repeticiones: _s(j['repeticiones']),
        series: _s(j['series']),
        fotos: [
          for (final f in (j['fotos'] as List? ?? const []))
            Foto(
              // Preferimos el proxy del backend (/api/m/imagenes?key=...): funciona en Chrome sin CORS en S3.
              url: (f as Map)['path'] != null ? '${ApiConfig.springApiBaseUrl}${f['path']}' : _s(f['url']),
              descripcion: _s(f['descripcion']),
            ),
        ],
      );
}

class Asistencia {
  const Asistencia({required this.fecha, required this.musculos});
  final DateTime fecha;
  final List<String> musculos;

  factory Asistencia.fromJson(Map<String, dynamic> j) =>
      Asistencia(fecha: _date(j['fecha']) ?? DateTime.now(), musculos: [for (final m in (j['musculos'] as List? ?? const [])) '$m']);
}

class AsistenciasInfo {
  const AsistenciasInfo({required this.asistencias, required this.inasistencias, required this.hoyRegistrada});
  final List<Asistencia> asistencias;
  final int inasistencias;
  final bool hoyRegistrada;

  factory AsistenciasInfo.fromJson(Map<String, dynamic> j) => AsistenciasInfo(
        asistencias: [for (final a in (j['asistencias'] as List? ?? const [])) Asistencia.fromJson((a as Map).cast<String, dynamic>())],
        inasistencias: _i(j['inasistencias']),
        hoyRegistrada: j['hoyRegistrada'] == true,
      );
}

class Medicion {
  const Medicion({required this.peso, required this.estatura, required this.imc, required this.interpretacion, this.fecha});
  final double peso, estatura, imc;
  final String interpretacion;
  final DateTime? fecha;

  factory Medicion.fromJson(Map<String, dynamic> j) => Medicion(
        peso: _d(j['peso']),
        estatura: _d(j['estatura']),
        imc: _d(j['imc']),
        interpretacion: _s(j['interpretacion']),
        fecha: _date(j['fecha']),
      );
}

class ResumenAdmin {
  const ResumenAdmin({
    required this.gym,
    required this.total,
    required this.activos,
    required this.pendientes,
    required this.suspendidos,
    required this.porVencer,
    required this.ingresosMensuales,
    required this.planes,
    required this.rutinas,
  });
  final Gym gym;
  final int total, activos, pendientes, suspendidos, porVencer, planes, rutinas;
  final double ingresosMensuales;

  factory ResumenAdmin.fromJson(Map<String, dynamic> j) => ResumenAdmin(
        gym: Gym.fromJson((j['gimnasio'] as Map).cast<String, dynamic>()),
        total: _i(j['total']),
        activos: _i(j['activos']),
        pendientes: _i(j['pendientes']),
        suspendidos: _i(j['suspendidos']),
        porVencer: _i(j['porVencer']),
        ingresosMensuales: _d(j['ingresosMensualesEstimados']),
        planes: _i(j['planes']),
        rutinas: _i(j['rutinas']),
      );
}

/// Perfil del cliente logueado (GET /api/m/cliente/perfil).
class PerfilCliente {
  const PerfilCliente({required this.cliente, this.gym, this.ultimaMedicion});
  final Cliente cliente;
  final Gym? gym;
  final Medicion? ultimaMedicion;

  factory PerfilCliente.fromJson(Map<String, dynamic> j) => PerfilCliente(
        cliente: Cliente.fromJson(j),
        gym: j['gimnasio'] == null ? null : Gym.fromJson((j['gimnasio'] as Map).cast<String, dynamic>()),
        ultimaMedicion: j['ultimaMedicion'] == null ? null : Medicion.fromJson((j['ultimaMedicion'] as Map).cast<String, dynamic>()),
      );
}

/// Grupos musculares que acepta el backend (valor guardado, texto visible).
const gruposMusculares = [
  ('Pecho', 'Pecho'),
  ('Espalda', 'Espalda'),
  ('Cuadriceps', 'Cuádriceps'),
  ('Femoral', 'Femoral'),
  ('Gluteos', 'Glúteos'),
  ('Biceps', 'Bíceps'),
  ('Triceps', 'Tríceps'),
  ('Hombros', 'Hombros'),
];

String grupoLabel(String valor) {
  for (final g in gruposMusculares) {
    if (g.$1.toLowerCase() == valor.toLowerCase()) return g.$2;
  }
  return valor;
}

String? grupoValor(String? cualquiera) {
  if (cualquiera == null) return null;
  final v = cualquiera.toLowerCase();
  for (final g in gruposMusculares) {
    if (g.$1.toLowerCase() == v || g.$2.toLowerCase() == v) return g.$1;
  }
  return null;
}
