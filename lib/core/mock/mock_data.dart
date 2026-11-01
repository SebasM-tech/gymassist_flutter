// DATOS DE MUESTRA SOLO PARA REVISAR VISTAS.
// Se reemplazan por entidades de dominio + repositorios Drift en las fases siguientes.
import 'package:gymassist/features/clients/domain/client_status.dart';

const muscleGroups = [
  'Pecho', 'Espalda', 'Cuádriceps', 'Femoral', 'Glúteos', 'Bíceps', 'Tríceps', 'Hombros'
];

class MockClient {
  MockClient({
    required this.nombre,
    required this.correo,
    required this.documento,
    required this.telefono,
    required this.plan,
    required this.username,
    required this.estado,
  });
  final String nombre, correo, documento, telefono, plan, username;
  ClientStatus estado;
}

class MockPlan {
  MockPlan(this.nombre, this.descripcion, this.precio, this.duracion, this.suscriptores);
  String nombre, descripcion;
  double precio;
  int duracion;
  int suscriptores;
}

class MockRoutine {
  MockRoutine(this.id, this.ejercicio, this.grupo, this.repeticiones, this.series, this.fotos);
  final String id, ejercicio, grupo, repeticiones, series;
  final List<String> fotos; // descripciones de las fotos
}

class MockMeasurement {
  const MockMeasurement(this.fecha, this.peso, this.estatura);
  final DateTime fecha;
  final double peso, estatura;
}

class MockAttendance {
  const MockAttendance(this.fecha, this.musculos);
  final DateTime fecha;
  final List<String> musculos;
}

class MockPrediction {
  const MockPrediction({
    required this.nombre, required this.correo, required this.telefono,
    required this.renovara, required this.riesgo, required this.asistencias,
    required this.pagoAlDia, required this.antiguedad, required this.tipoPlan,
    required this.recomendacion,
  });
  final String nombre, correo, telefono, riesgo, tipoPlan, recomendacion;
  final bool renovara, pagoAlDia;
  final int asistencias, antiguedad;
}

List<MockClient> mockClients() => [
      MockClient(nombre: 'Laura Gómez', correo: 'laura.gomez@mail.com', documento: '1045678901', telefono: '3001234567', plan: 'Mensual', username: 'lgomez', estado: ClientStatus.activo),
      MockClient(nombre: 'Carlos Pérez', correo: 'carlos.perez@mail.com', documento: '1098765432', telefono: '3109876543', plan: 'Trimestral', username: 'cperez', estado: ClientStatus.pendiente),
      MockClient(nombre: 'Marta Ruiz', correo: 'marta.ruiz@mail.com', documento: '1122334455', telefono: '3205551234', plan: 'Mensual', username: 'mruiz', estado: ClientStatus.activo),
      MockClient(nombre: 'Andrés Torres', correo: 'andres.torres@mail.com', documento: '1033221100', telefono: '3157778899', plan: 'Trimestral', username: 'atorres', estado: ClientStatus.suspendido),
      MockClient(nombre: 'Sofía Díaz', correo: 'sofia.diaz@mail.com', documento: '1066554433', telefono: '3014443322', plan: 'Mensual', username: 'sdiaz', estado: ClientStatus.pendiente),
    ];

List<MockPlan> mockPlans() => [
      MockPlan('Mensual', 'Acceso total a máquinas y clases grupales.', 80000, 1, 54),
      MockPlan('Trimestral', 'Tres meses con valoración física incluida.', 210000, 3, 33),
      MockPlan('Semestral', 'Seis meses con plan de entrenamiento personalizado.', 390000, 6, 12),
    ];

List<MockRoutine> mockRoutines() => [
      MockRoutine('r1', 'Press de banca', 'Pecho', '10', '4', ['Posición inicial', 'Bajada controlada', 'Empuje final']),
      MockRoutine('r2', 'Aperturas con mancuernas', 'Pecho', '12', '3', ['Posición inicial', 'Apertura completa']),
      MockRoutine('r3', 'Dominadas', 'Espalda', '8', '4', ['Agarre', 'Subida']),
      MockRoutine('r4', 'Sentadilla libre', 'Cuádriceps', '10', '4', ['Postura', 'Descenso', 'Ascenso']),
      MockRoutine('r5', 'Curl de bíceps', 'Bíceps', '12', '3', ['Posición inicial', 'Contracción']),
      MockRoutine('r6', 'Press militar', 'Hombros', '10', '4', ['Posición inicial', 'Empuje']),
    ];

List<MockMeasurement> mockMeasurements() => [
      MockMeasurement(DateTime(2025, 10, 28), 72.4, 1.75),
      MockMeasurement(DateTime(2025, 10, 14), 73.1, 1.75),
      MockMeasurement(DateTime(2025, 9, 30), 74.0, 1.75),
      MockMeasurement(DateTime(2025, 9, 16), 74.8, 1.75),
    ];

List<MockAttendance> mockAttendances() => [
      MockAttendance(DateTime(2025, 10, 31), ['Pecho', 'Tríceps']),
      MockAttendance(DateTime(2025, 10, 29), ['Espalda', 'Bíceps']),
      MockAttendance(DateTime(2025, 10, 27), ['Cuádriceps', 'Glúteos']),
      MockAttendance(DateTime(2025, 10, 24), ['Hombros']),
    ];

List<MockPrediction> mockPredictions() => const [
      MockPrediction(nombre: 'Laura Gómez', correo: 'laura.gomez@mail.com', telefono: '3001234567', renovara: true, riesgo: 'BAJO', asistencias: 14, pagoAlDia: true, antiguedad: 11, tipoPlan: 'Mensual', recomendacion: 'Cliente ideal. Considerar ofrecerle plan premium o descuento por referidos.'),
      MockPrediction(nombre: 'Marta Ruiz', correo: 'marta.ruiz@mail.com', telefono: '3205551234', renovara: true, riesgo: 'MEDIO', asistencias: 7, pagoAlDia: true, antiguedad: 3, tipoPlan: 'Mensual', recomendacion: 'Cliente con buen potencial. Programar seguimiento mensual.'),
      MockPrediction(nombre: 'Carlos Pérez', correo: 'carlos.perez@mail.com', telefono: '3109876543', renovara: false, riesgo: 'ALTO', asistencias: 5, pagoAlDia: false, antiguedad: 8, tipoPlan: 'Trimestral', recomendacion: 'Ofrecer plan de pagos flexible o descuento por pronto pago.'),
      MockPrediction(nombre: 'Andrés Torres', correo: 'andres.torres@mail.com', telefono: '3157778899', renovara: false, riesgo: 'CRITICO', asistencias: 1, pagoAlDia: false, antiguedad: 14, tipoPlan: 'Trimestral', recomendacion: 'URGENTE: contactar de inmediato. Ofrecer una sesión personalizada gratuita.'),
      MockPrediction(nombre: 'Sofía Díaz', correo: 'sofia.diaz@mail.com', telefono: '3014443322', renovara: false, riesgo: 'ESPERADO', asistencias: 3, pagoAlDia: false, antiguedad: 2, tipoPlan: 'Mensual', recomendacion: 'Cliente inactivo. Considerar campaña de reactivación con descuento.'),
    ];
