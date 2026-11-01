import 'package:drift/native.dart';
import 'package:gymassist/core/database/app_database.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/core/security/password_hasher.dart';
import 'package:gymassist/core/security/session_store.dart';
import 'package:gymassist/features/attendance/data/attendance_repository_impl.dart';
import 'package:gymassist/features/attendance/domain/attendance_service.dart';
import 'package:gymassist/features/auth/data/user_repository_impl.dart';
import 'package:gymassist/features/auth/domain/auth_service.dart';
import 'package:gymassist/features/clients/data/client_repository_impl.dart';
import 'package:gymassist/features/clients/domain/client_service.dart';
import 'package:gymassist/features/dashboard/domain/dashboard_service.dart';
import 'package:gymassist/features/gym_setup/data/gym_repository_impl.dart';
import 'package:gymassist/features/gym_setup/domain/gym_domain.dart';
import 'package:gymassist/features/payments/data/payment_repository_impl.dart';
import 'package:gymassist/features/plans/data/plan_repository_impl.dart';
import 'package:gymassist/features/plans/domain/plan_domain.dart';

/// Entorno de pruebas: BD en memoria, reloj controlable y bcrypt con costo mínimo.
class TestEnv {
  TestEnv({DateTime? start}) : now = start ?? DateTime(2025, 10, 1, 9) {
    db = AppDatabase(NativeDatabase.memory());
    final tx = DriftTransactor(db);
    clock() => now;
    final users = UserRepositoryImpl(db);
    gyms = GymRepositoryImpl(db);
    plans = PlanRepositoryImpl(db);
    clients = ClientRepositoryImpl(db);
    payments = PaymentRepositoryImpl(db);
    attendances = AttendanceRepositoryImpl(db);
    sessions = InMemorySessionStore();
    const hasher = BcryptPasswordHasher(cost: 4);
    auth = AuthService(users: users, gyms: gyms, clients: clients, hasher: hasher, sessions: sessions, clock: clock);
    gymService = GymService(gyms);
    planService = PlanService(plans);
    clientService = ClientService(clients: clients, plans: plans, users: users, payments: payments, hasher: hasher, tx: tx, clock: clock);
    attendanceService = AttendanceService(attendances: attendances, clients: clients, tx: tx, clock: clock);
    dashboard = DashboardService(clients: clients, payments: payments, clock: clock);
  }

  DateTime now;
  late final AppDatabase db;
  late final GymRepositoryImpl gyms;
  late final PlanRepositoryImpl plans;
  late final ClientRepositoryImpl clients;
  late final PaymentRepositoryImpl payments;
  late final AttendanceRepositoryImpl attendances;
  late final InMemorySessionStore sessions;
  late final AuthService auth;
  late final GymService gymService;
  late final PlanService planService;
  late final ClientService clientService;
  late final AttendanceService attendanceService;
  late final DashboardService dashboard;

  /// Admin + gimnasio + plan trimestral + un cliente pendiente.
  Future<({String adminId, String gymId, Plan plan, String clientId})> scenario() async {
    final admin = (await auth.registerAdmin(username: 'Admin', email: 'admin@x.com', password: 'secreto1', confirmPassword: 'secreto1')).valueOrNull!;
    final gym = (await gymService.register(adminUserId: admin.id, name: 'FitLife', nit: '900', address: 'Calle 1', description: 'Gym', bankAccount: '123')).valueOrNull!;
    final plan = (await planService.create(gymId: gym.id, name: 'Trimestral', description: '3 meses', priceCop: 210000, durationMonths: 3)).valueOrNull!;
    final client = (await clientService.createClient(gymId: gym.id, planId: plan.id, fullName: 'Carlos Pérez', email: 'carlos@x.com', documentId: '10', phone: '300', username: 'carlos', password: 'cliente1')).valueOrNull!;
    return (adminId: admin.id, gymId: gym.id, plan: plan, clientId: client.id);
  }

  Future<void> activate(String clientId, String adminId) async {
    final r = await clientService.registerPayment(clientId: clientId, registeredByUserId: adminId, method: PaymentMethod.efectivo);
    if (!r.isOk) throw StateError('No se pudo activar: ${r.failureOrNull}');
  }

  Future<void> dispose() => db.close();
}
