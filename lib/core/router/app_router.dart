import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/widgets/app_shell.dart';
import 'package:gymassist/core/widgets/error_pages.dart';
import 'package:gymassist/features/account/presentation/admin_account_page.dart';
import 'package:gymassist/features/account/presentation/client_account_page.dart';
import 'package:gymassist/features/admin_home/presentation/admin_home_page.dart';
import 'package:gymassist/features/attendance/presentation/attendance_page.dart';
import 'package:gymassist/features/auth/presentation/auth_page.dart';
import 'package:gymassist/features/client_home/presentation/client_home_page.dart';
import 'package:gymassist/features/clients/presentation/clients_page.dart';
import 'package:gymassist/features/dashboard/presentation/dashboard_page.dart';
import 'package:gymassist/features/gym_setup/presentation/gym_register_page.dart';
import 'package:gymassist/features/measurements/presentation/imc_page.dart';
import 'package:gymassist/features/optimization/presentation/optimization_page.dart';
import 'package:gymassist/features/payments/presentation/payment_page.dart';
import 'package:gymassist/features/plans/presentation/plans_page.dart';
import 'package:gymassist/features/predictions/presentation/predictions_page.dart';
import 'package:gymassist/features/public/presentation/landing_page.dart';
import 'package:gymassist/features/routines/presentation/client_routines_page.dart';
import 'package:gymassist/features/routines/presentation/routine_edit_page.dart';
import 'package:gymassist/features/routines/presentation/routines_admin_page.dart';

Page<void> _page(Widget w) => NoTransitionPage<void>(child: w);

/// Guardas de navegación según la sesión del backend (rol ADMIN / CLIENTE y estado del cliente).
String? _guard(AppSession? s, bool loading, String loc) {
  final protected = loc.startsWith('/admin') || loc.startsWith('/cliente') || loc.startsWith('/gimnasio');
  if (loading) return null;
  if (s == null) return protected ? '/login' : null;
  if (loc == '/login') return homeFor(s);
  if (s.isAdmin) {
    if (loc.startsWith('/cliente')) return '/acceso-denegado';
    if (!s.tieneGimnasio && loc.startsWith('/admin')) return '/gimnasio/registro';
    if (s.tieneGimnasio && loc.startsWith('/gimnasio')) return '/admin';
  } else {
    if (loc.startsWith('/admin') || loc.startsWith('/gimnasio')) return '/acceso-denegado';
    final activo = s.cliente?.activo ?? false;
    if (!activo && (loc.startsWith('/cliente/rutinas') || loc.startsWith('/cliente/asistencia'))) return '/cliente/pago';
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (_, state) {
      final s = ref.read(sessionProvider);
      return _guard(s.valueOrNull, s.isLoading, state.uri.path);
    },
  errorBuilder: (_, __) => const ErrorPage(title: 'Página no encontrada', message: 'La dirección que buscas no existe.'),
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LandingPage()),
    GoRoute(path: '/login', builder: (_, __) => const AuthPage()),
    GoRoute(path: '/gimnasio/registro', builder: (_, __) => const GymRegisterPage()),
    GoRoute(
      path: '/acceso-denegado',
      builder: (_, __) => const ErrorPage(title: 'Acceso denegado', message: 'No tienes permisos para ver esta sección.', icon: Icons.lock_outline),
    ),
    ShellRoute(
      builder: (_, state, child) => AppShell(role: Role.admin, location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/admin', pageBuilder: (_, __) => _page(const AdminHomePage())),
        GoRoute(path: '/admin/clientes', pageBuilder: (_, __) => _page(const ClientsPage())),
        GoRoute(path: '/admin/membresias', pageBuilder: (_, __) => _page(const PlansPage())),
        GoRoute(path: '/admin/rutinas', pageBuilder: (_, __) => _page(const RoutinesAdminPage())),
        GoRoute(path: '/admin/rutinas/:id/editar', pageBuilder: (_, s) => _page(RoutineEditPage(id: s.pathParameters['id']!))),
        GoRoute(path: '/admin/dashboard', pageBuilder: (_, __) => _page(const DashboardPage())),
        GoRoute(path: '/admin/predicciones', pageBuilder: (_, __) => _page(const PredictionsPage())),
        GoRoute(path: '/admin/modelo', pageBuilder: (_, __) => _page(const OptimizationPage())),
        GoRoute(path: '/admin/cuenta', pageBuilder: (_, __) => _page(const AdminAccountPage())),
      ],
    ),
    ShellRoute(
      builder: (_, state, child) => AppShell(role: Role.client, location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/cliente', pageBuilder: (_, __) => _page(const ClientHomePage())),
        GoRoute(path: '/cliente/imc', pageBuilder: (_, __) => _page(const ImcPage())),
        GoRoute(path: '/cliente/rutinas', pageBuilder: (_, __) => _page(const ClientRoutinesPage())),
        GoRoute(path: '/cliente/rutinas/grupo/:grupo', pageBuilder: (_, s) => _page(GroupRoutinesPage(grupo: s.pathParameters['grupo']!))),
        GoRoute(path: '/cliente/asistencia', pageBuilder: (_, __) => _page(const AttendancePage())),
        GoRoute(path: '/cliente/cuenta', pageBuilder: (_, __) => _page(const ClientAccountPage())),
        GoRoute(path: '/cliente/pago', pageBuilder: (_, s) => _page(PaymentPage(resultado: s.uri.queryParameters['pago']))),
      ],
    ),
  ],
);
});
