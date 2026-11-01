import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/di/providers.dart';
import 'package:gymassist/core/domain/enums.dart';

/// Datos de demostración para desarrollo. Se activa con:  flutter run --dart-define=SEED_DEMO=true
/// Usuario admin: admin / admin123.  Clientes: laura, carlos, marta (contraseña: cliente123).
Future<void> seedDemoData(ProviderContainer c) async {
  final auth = c.read(authServiceProvider);
  final users = c.read(userRepositoryProvider);
  if (await users.usernameTaken('admin')) return; // ya sembrado

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
}
