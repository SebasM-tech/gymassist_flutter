import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/core/security/password_hasher.dart';
import 'package:gymassist/core/security/session_store.dart';
import 'package:gymassist/core/storage/file_storage.dart';
import 'package:gymassist/features/attendance/data/attendance_repository_impl.dart';
import 'package:gymassist/features/attendance/domain/attendance_domain.dart';
import 'package:gymassist/features/attendance/domain/attendance_service.dart';
import 'package:gymassist/features/auth/data/user_repository_impl.dart';
import 'package:gymassist/features/auth/domain/auth_service.dart';
import 'package:gymassist/features/auth/domain/user.dart';
import 'package:gymassist/features/clients/data/client_repository_impl.dart';
import 'package:gymassist/features/clients/domain/client_domain.dart';
import 'package:gymassist/features/clients/domain/client_service.dart';
import 'package:gymassist/features/dashboard/domain/dashboard_service.dart';
import 'package:gymassist/features/gym_setup/data/gym_repository_impl.dart';
import 'package:gymassist/features/gym_setup/domain/gym_domain.dart';
import 'package:gymassist/features/measurements/data/measurement_repository_impl.dart';
import 'package:gymassist/features/measurements/domain/measurement_domain.dart';
import 'package:gymassist/features/payments/data/payment_repository_impl.dart';
import 'package:gymassist/features/payments/domain/payment_domain.dart';
import 'package:gymassist/features/plans/data/plan_repository_impl.dart';
import 'package:gymassist/features/plans/domain/plan_domain.dart';
import 'package:gymassist/features/routines/data/routine_repository_impl.dart';
import 'package:gymassist/features/routines/domain/routine_domain.dart';

// ---- infraestructura ----
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
final clockProvider = Provider<Clock>((_) => DateTime.now);
final transactorProvider = Provider<Transactor>((ref) => DriftTransactor(ref.watch(databaseProvider)));
final passwordHasherProvider = Provider<PasswordHasher>((_) => const BcryptPasswordHasher());
final sessionStoreProvider = Provider<SessionStore>((_) => SecureSessionStore());
final fileStorageProvider = Provider<FileStorage>((_) => LocalFileStorage());

// ---- repositorios (la UI nunca los usa directamente: va por servicios o por streams de lectura) ----
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepositoryImpl(ref.watch(databaseProvider)));
final gymRepositoryProvider = Provider<GymRepository>((ref) => GymRepositoryImpl(ref.watch(databaseProvider)));
final planRepositoryProvider = Provider<PlanRepository>((ref) => PlanRepositoryImpl(ref.watch(databaseProvider)));
final clientRepositoryProvider = Provider<ClientRepository>((ref) => ClientRepositoryImpl(ref.watch(databaseProvider)));
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepositoryImpl(ref.watch(databaseProvider)));
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepositoryImpl(ref.watch(databaseProvider)));
final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) => MeasurementRepositoryImpl(ref.watch(databaseProvider)));
final routineRepositoryProvider = Provider<RoutineRepository>((ref) => RoutineRepositoryImpl(ref.watch(databaseProvider)));

// ---- servicios con reglas de negocio ----
final authServiceProvider = Provider<AuthService>((ref) => AuthService(
      users: ref.watch(userRepositoryProvider),
      gyms: ref.watch(gymRepositoryProvider),
      clients: ref.watch(clientRepositoryProvider),
      hasher: ref.watch(passwordHasherProvider),
      sessions: ref.watch(sessionStoreProvider),
      clock: ref.watch(clockProvider),
    ));
final gymServiceProvider = Provider<GymService>((ref) => GymService(ref.watch(gymRepositoryProvider)));
final planServiceProvider = Provider<PlanService>((ref) => PlanService(ref.watch(planRepositoryProvider)));
final clientServiceProvider = Provider<ClientService>((ref) => ClientService(
      clients: ref.watch(clientRepositoryProvider),
      plans: ref.watch(planRepositoryProvider),
      users: ref.watch(userRepositoryProvider),
      payments: ref.watch(paymentRepositoryProvider),
      hasher: ref.watch(passwordHasherProvider),
      tx: ref.watch(transactorProvider),
      clock: ref.watch(clockProvider),
    ));
final attendanceServiceProvider = Provider<AttendanceService>((ref) => AttendanceService(
      attendances: ref.watch(attendanceRepositoryProvider),
      clients: ref.watch(clientRepositoryProvider),
      tx: ref.watch(transactorProvider),
      clock: ref.watch(clockProvider),
    ));
final measurementServiceProvider = Provider<MeasurementService>((ref) => MeasurementService(ref.watch(measurementRepositoryProvider), ref.watch(clockProvider)));
final routineServiceProvider = Provider<RoutineService>((ref) => RoutineService(ref.watch(routineRepositoryProvider), ref.watch(fileStorageProvider)));
final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService(
      clients: ref.watch(clientRepositoryProvider),
      payments: ref.watch(paymentRepositoryProvider),
      clock: ref.watch(clockProvider),
    ));

// ---- estado de sesión ----
final currentUserProvider = FutureProvider<AppUser?>((ref) => ref.watch(authServiceProvider).restoreSession());
