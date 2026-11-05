import 'package:gymassist/core/api/api_client.dart';
import 'package:gymassist/core/api/models.dart';

List<Map<String, dynamic>> _list(dynamic j) => [for (final x in (j as List? ?? const [])) (x as Map).cast<String, dynamic>()];
Map<String, dynamic> _map(dynamic j) => (j as Map).cast<String, dynamic>();

/// Todas las llamadas de la app al backend Spring Boot.
class GymApi {
  GymApi(this._c);
  final ApiClient _c;

  // ------------------------------------------------------------------ sesión
  Future<Map<String, dynamic>> login(String username, String password) async =>
      _map(await _c.post('/api/m/auth/login', {'username': username, 'password': password}));

  Future<Map<String, dynamic>> registerAdmin({required String username, required String email, required String password}) async =>
      _map(await _c.post('/api/m/auth/register', {'username': username, 'email': email, 'password': password}));

  Future<Map<String, dynamic>> me() async => _map(await _c.get('/api/m/auth/me'));

  // ------------------------------------------------------------------ admin
  Future<Gym> registrarGimnasio({required String nombre, required String nit, required String direccion, required String descripcion}) async =>
      Gym.fromJson(_map(await _c.post('/api/m/admin/gimnasio', {'nombre': nombre, 'nit': nit, 'direccion': direccion, 'descripcion': descripcion})));

  Future<ResumenAdmin> resumen() async => ResumenAdmin.fromJson(_map(await _c.get('/api/m/admin/resumen')));

  Future<List<Cliente>> clientes() async => [for (final j in _list(await _c.get('/api/m/admin/clientes'))) Cliente.fromJson(j)];

  Future<Cliente> crearCliente({
    required String nombre,
    required String correo,
    required String documento,
    required String telefono,
    required String planId,
    required String username,
    required String password,
  }) async =>
      Cliente.fromJson(_map(await _c.post('/api/m/admin/clientes', {
        'nombre': nombre,
        'correo': correo,
        'documento': documento,
        'telefono': telefono,
        'planId': planId,
        'username': username,
        'password': password,
      })));

  Future<Cliente> cambiarEstado(String clienteId, String estado) async =>
      Cliente.fromJson(_map(await _c.put('/api/m/admin/clientes/$clienteId/estado', {'estado': estado})));

  Future<Cliente> pagoManual(String clienteId) async => Cliente.fromJson(_map(await _c.post('/api/m/admin/clientes/$clienteId/pago-manual')));

  /// Clientes del gimnasio en el formato de la API de Python (para la red neuronal).
  Future<List<Map<String, dynamic>>> clientesParaPrediccion() async => _list(await _c.get('/api/m/admin/ml/clientes'));

  Future<Map<String, dynamic>> dashboard() async => _map(await _c.get('/api/m/admin/dashboard'));

  Future<void> actualizarCuentaAdmin({required String correo, String? password}) =>
      _c.put('/api/m/admin/cuenta', {'correo': correo, if (password != null && password.isNotEmpty) 'password': password});

  Future<List<Plan>> planesAdmin() async => [for (final j in _list(await _c.get('/api/m/admin/planes'))) Plan.fromJson(j)];

  Future<Plan> guardarPlan({String? id, required String nombre, required String descripcion, required String precio, required String duracionMeses}) async {
    final body = {'nombre': nombre, 'descripcion': descripcion, 'precio': precio, 'duracionMeses': duracionMeses};
    final j = id == null ? await _c.post('/api/m/admin/planes', body) : await _c.put('/api/m/admin/planes/$id', body);
    return Plan.fromJson(_map(j));
  }

  Future<void> borrarPlan(String id) => _c.delete('/api/m/admin/planes/$id');

  Future<List<Rutina>> rutinasAdmin() async => [for (final j in _list(await _c.get('/api/m/admin/rutinas'))) Rutina.fromJson(j)];

  Future<Rutina> crearRutina({
    required String nombre,
    required String grupoMuscular,
    required String repeticiones,
    required String series,
    List<UploadFile> fotos = const [],
    List<String> descripciones = const [],
  }) async =>
      Rutina.fromJson(_map(await _c.multipart('/api/m/admin/rutinas',
          fields: {'nombre': nombre, 'grupoMuscular': grupoMuscular, 'repeticiones': repeticiones, 'series': series},
          listFields: {'descripciones': descripciones},
          files: fotos)));

  Future<Rutina> editarRutina(String id, {required String nombre, required String grupoMuscular, required String repeticiones, required String series}) async =>
      Rutina.fromJson(_map(await _c.put('/api/m/admin/rutinas/$id',
          {'nombre': nombre, 'grupoMuscular': grupoMuscular, 'repeticiones': repeticiones, 'series': series})));

  Future<void> borrarRutina(String id) => _c.delete('/api/m/admin/rutinas/$id');

  // ------------------------------------------------------------------ cliente
  Future<PerfilCliente> perfil() async => PerfilCliente.fromJson(_map(await _c.get('/api/m/cliente/perfil')));

  Future<List<Plan>> planesCliente() async => [for (final j in _list(await _c.get('/api/m/cliente/planes'))) Plan.fromJson(j)];

  Future<Cliente> cambiarPlan(String planId) async => Cliente.fromJson(_map(await _c.put('/api/m/cliente/plan', {'planId': planId})));

  /// Devuelve el link de pago de Mercado Pago.
  Future<String> crearPago({String? returnUrl}) async =>
      '${_map(await _c.post('/api/m/cliente/pago', {if (returnUrl != null) 'returnUrl': returnUrl}))['initPoint']}';

  /// Pide al backend que consulte el pago en Mercado Pago (respaldo si el webhook no llegó).
  Future<Cliente> verificarPago(String paymentId) async =>
      Cliente.fromJson((_map(await _c.post('/api/m/cliente/pago/verificar', {'paymentId': paymentId}))['cliente'] as Map).cast<String, dynamic>());

  Future<String> chatbot(String mensaje) async => '${_map(await _c.post('/api/m/cliente/chatbot', {'mensaje': mensaje}))['respuesta']}';

  Future<List<Rutina>> rutinasCliente({String? grupo}) async =>
      [for (final j in _list(await _c.get('/api/m/cliente/rutinas', query: grupo == null ? null : {'grupo': grupo}))) Rutina.fromJson(j)];

  Future<AsistenciasInfo> asistencias() async => AsistenciasInfo.fromJson(_map(await _c.get('/api/m/cliente/asistencias')));

  Future<AsistenciasInfo> registrarAsistencia(List<String> musculos) async =>
      AsistenciasInfo.fromJson(_map(await _c.post('/api/m/cliente/asistencias', {'musculos': musculos})));

  Future<List<Medicion>> mediciones() async => [for (final j in _list(await _c.get('/api/m/cliente/mediciones'))) Medicion.fromJson(j)];

  Future<Medicion> guardarMedicion({required double peso, required double estatura}) async =>
      Medicion.fromJson(_map(await _c.post('/api/m/cliente/mediciones', {'peso': peso, 'estatura': estatura})));

  /// Devuelve el token nuevo (si cambió el usuario, el anterior deja de servir).
  Future<String> actualizarCuenta({required String correo, required String username, String? password}) async =>
      '${_map(await _c.put('/api/m/cliente/cuenta', {'correo': correo, 'username': username, if (password != null && password.isNotEmpty) 'password': password}))['token']}';
}
