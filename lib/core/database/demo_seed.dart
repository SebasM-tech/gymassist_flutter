import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/di/providers.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

/// Datos de demostración para desarrollo. Se activa con:  flutter run --dart-define=SEED_DEMO=true
/// Usuario admin: admin / admin123.  Clientes: laura, carlos, marta (contraseña: cliente123).
/// Además crea 7 clientes con historial (valentina, juanh, daniela, miguel, camila, felipe, isabela) para las predicciones.
Future<void> seedDemoData(ProviderContainer c) async {
  final auth = c.read(authServiceProvider);
  final users = c.read(userRepositoryProvider);
  if (await users.usernameTaken('admin')) {
    await seedChurnHistory(c); // ya sembrado: solo agrega (una vez) los clientes con historial para la red neuronal
    return;
  }

  final admin = (await auth.registerAdmin(username: 'admin', email: 'admin@gymassist.local', password: 'admin123', confirmPassword: 'admin123')).valueOrNull!;
  final gym = (await c.read(gymServiceProvider).register(
    adminUserId: admin.id,
    name: 'FitLife Gym',
    nit: '900123456',
    address: 'Calle 30 #12-45, Cartagena',
    description: 'Gimnasio con zona de pesas, cardio y clases grupales.',
    bankAccount: '1234567890',
  ))
      .valueOrNull!;

  final planSvc = c.read(planServiceProvider);
  final mensual = (await planSvc.create(gymId: gym.id, name: 'Mensual', description: 'Acceso total a máquinas y clases grupales.', priceCop: 80000, durationMonths: 1)).valueOrNull!;
  final trimestral = (await planSvc.create(gymId: gym.id, name: 'Trimestral', description: 'Tres meses con valoración física incluida.', priceCop: 210000, durationMonths: 3)).valueOrNull!;
  await planSvc.create(gymId: gym.id, name: 'Semestral', description: 'Seis meses con plan personalizado.', priceCop: 390000, durationMonths: 6);

  final clientSvc = c.read(clientServiceProvider);
  Future<String> client(String name, String user, String planId, String doc) async => (await clientSvc.createClient(
        gymId: gym.id,
        planId: planId,
        fullName: name,
        email: '$user@mail.com',
        documentId: doc,
        phone: '300${doc.substring(0, 7)}',
        username: user,
        password: 'cliente123',
      ))
          .valueOrNull!
          .id;

  final laura = await client('Laura Gómez', 'laura', mensual.id, '1045678901');
  await client('Carlos Pérez', 'carlos', trimestral.id, '1098765432'); // queda pendiente de pago
  final marta = await client('Marta Ruiz', 'marta', mensual.id, '1122334455');

  await clientSvc.registerPayment(clientId: laura, registeredByUserId: admin.id);
  await clientSvc.registerPayment(clientId: marta, registeredByUserId: admin.id, method: PaymentMethod.transferencia);

  await c.read(attendanceServiceProvider).register(clientId: laura, muscles: [MuscleGroup.pecho, MuscleGroup.triceps]);
  await c.read(measurementServiceProvider).save(clientId: laura, weightKg: 62.5, heightM: 1.68);

  final routines = c.read(routineServiceProvider);
  await routines.create(gymId: gym.id, name: 'Press de banca', group: MuscleGroup.pecho, reps: '10', sets: '4');
  await routines.create(gymId: gym.id, name: 'Sentadilla libre', group: MuscleGroup.cuadriceps, reps: '10', sets: '4');
  await routines.create(gymId: gym.id, name: 'Dominadas', group: MuscleGroup.espalda, reps: '8', sets: '4');

  await seedChurnHistory(c);
}

/// Clientes con 12 semanas de asistencias, membresías y medidas variadas, para que la pantalla
/// de Predicciones (red LSTM en Python vía FastAPI) muestre casos de riesgo bajo, medio, alto y crítico.
Future<void> seedChurnHistory(ProviderContainer c) async {
  if (await c.read(userRepositoryProvider).usernameTaken('valentina')) return; // ya sembrado
  final db = c.read(databaseProvider);
  final gym = await (db.select(db.gyms)..limit(1)).getSingleOrNull();
  if (gym == null) return;
  final plans = await (db.select(db.plans)..where((p) => p.gymId.equals(gym.id) & p.deletedAt.isNull())).get();
  PlanRow plan(int months) => plans.firstWhere((p) => p.durationMonths == months, orElse: () => plans.first);
  if (plans.isEmpty) return;

  final clientSvc = c.read(clientServiceProvider);
  final attendances = c.read(attendanceRepositoryProvider);
  final measurements = c.read(measurementRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 18);
  const rotation = MuscleGroup.values;

  Future<void> add({
    required String name,
    required String user,
    required String doc,
    required int planMonths,
    required int monthsSinceJoin,
    required int daysToExpire, // negativo = ya venció
    required ClientStatus status,
    required List<int> weeks, // 12 valores, de la semana más antigua a la más reciente
    int musclesPerVisit = 2,
    List<double> weights = const [], // medidas (kg) en las últimas semanas; la estatura es fija
  }) async {
    final p = plan(planMonths);
    final res = await clientSvc.createClient(
      gymId: gym.id,
      planId: p.id,
      fullName: name,
      email: '$user@mail.com',
      documentId: doc,
      phone: '31${doc.substring(0, 8)}',
      username: user,
      password: 'cliente123',
    );
    final client = res.valueOrNull;
    if (client == null) return;

    final end = today.add(Duration(days: daysToExpire));
    await (db.update(db.clients)..where((t) => t.id.equals(client.id))).write(ClientsCompanion(
      joinedAt: Value(today.subtract(Duration(days: (monthsSinceJoin * 30.44).round()))),
      membershipStart: Value(DateTime(end.year, end.month - p.durationMonths, end.day)),
      membershipEnd: Value(end),
      status: Value(status),
    ));

    var m = 0;
    for (var i = 0; i < weeks.length; i++) {
      final weeksAgo = weeks.length - 1 - i;
      for (var k = 0; k < (weeks[i] > 7 ? 7 : weeks[i]); k++) {
        final date = today.subtract(Duration(days: weeksAgo * 7 + k));
        final muscles = [for (var j = 0; j < musclesPerVisit; j++) rotation[(m + j) % rotation.length]];
        m += musclesPerVisit;
        await attendances.add(client.id, date, muscles);
      }
    }
    for (var i = 0; i < weights.length; i++) {
      await measurements.add(
        clientId: client.id,
        weightKg: weights[i],
        heightM: 1.70,
        measuredAt: today.subtract(Duration(days: (weights.length - 1 - i) * 30)),
      );
    }
  }

  await add(name: 'Valentina Rojas', user: 'valentina', doc: '1001234567', planMonths: 3, monthsSinceJoin: 14, daysToExpire: 40,
      status: ClientStatus.activo, weeks: [3, 3, 4, 3, 3, 4, 3, 3, 4, 3, 4, 3], musclesPerVisit: 3, weights: [72, 70.5, 69]);
  await add(name: 'Juan Herrera', user: 'juanh', doc: '1002345678', planMonths: 1, monthsSinceJoin: 6, daysToExpire: 5,
      status: ClientStatus.activo, weeks: [3, 3, 3, 2, 3, 2, 2, 1, 1, 1, 0, 0]);
  await add(name: 'Daniela Castro', user: 'daniela', doc: '1003456789', planMonths: 1, monthsSinceJoin: 2, daysToExpire: -10,
      status: ClientStatus.pendiente, weeks: [2, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0], musclesPerVisit: 1);
  await add(name: 'Miguel Ortiz', user: 'miguel', doc: '1004567890', planMonths: 1, monthsSinceJoin: 9, daysToExpire: 18,
      status: ClientStatus.activo, weeks: [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  await add(name: 'Camila Vargas', user: 'camila', doc: '1005678901', planMonths: 3, monthsSinceJoin: 4, daysToExpire: 60,
      status: ClientStatus.activo, weeks: [0, 1, 0, 2, 0, 3, 0, 1, 0, 2, 0, 1], weights: [65, 66]);
  await add(name: 'Felipe Morales', user: 'felipe', doc: '1006789012', planMonths: 1, monthsSinceJoin: 20, daysToExpire: -35,
      status: ClientStatus.suspendido, weeks: [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], musclesPerVisit: 1);
  await add(name: 'Isabela Mendoza', user: 'isabela', doc: '1007890123', planMonths: 1, monthsSinceJoin: 1, daysToExpire: 20,
      status: ClientStatus.activo, weeks: [0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 4, 4], musclesPerVisit: 3, weights: [80, 78.5]);
}
