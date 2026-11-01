import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/chatbot/presentation/chatbot_panel.dart';

enum Role { admin, client }

class NavItem {
  const NavItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

const _adminMain = [
  NavItem('Home', Icons.home_outlined, '/admin'),
  NavItem('Clientes', Icons.people_outline, '/admin/clientes'),
  NavItem('Planes', Icons.card_membership_outlined, '/admin/membresias'),
  NavItem('Rutinas', Icons.fitness_center, '/admin/rutinas'),
];
const _adminMore = [
  NavItem('Dashboard', Icons.pie_chart_outline, '/admin/dashboard'),
  NavItem('Predicciones IA', Icons.psychology_outlined, '/admin/predicciones'),
  NavItem('Modelo de optimización', Icons.calculate_outlined, '/admin/modelo'),
];
const _clientMain = [
  NavItem('Home', Icons.home_outlined, '/cliente'),
  NavItem('IMC', Icons.monitor_weight_outlined, '/cliente/imc'),
  NavItem('Rutinas', Icons.fitness_center, '/cliente/rutinas'),
  NavItem('Asistencia', Icons.event_available_outlined, '/cliente/asistencia'),
  NavItem('Membresía', Icons.credit_card_outlined, '/cliente/pago'),
];

/// Estructura móvil: AppBar + contenido + NavigationBar inferior.
/// El admin tiene 4 destinos principales y "Más" (Dashboard, Predicciones, Modelo).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.role, required this.location, required this.child});
  final Role role;
  final String location;
  final Widget child;

  bool _active(NavItem i) =>
      (i.path == '/admin' || i.path == '/cliente') ? location == i.path : location.startsWith(i.path);

  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirm(context,
        title: '¿Cerrar sesión?',
        message: 'Tu sesión actual será cerrada.',
        confirmLabel: 'Sí, cerrar sesión',
        danger: true);
    // TODO(auth): limpiar la sesión local (flutter_secure_storage).
    if (ok && context.mounted) context.go('/login');
  }

  void _showMore(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final i in _adminMore)
              ListTile(
                leading: Icon(i.icon, color: AppColors.accent),
                title: Text(i.label),
                selected: _active(i),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(i.path);
                },
              ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = role == Role.admin;
    final main = isAdmin ? _adminMain : _clientMain;
    final dark = context.isDark;
    var selected = main.indexWhere(_active);
    if (selected < 0) selected = isAdmin ? main.length : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: dark ? navGradientDark : navGradient)),
        title: Text(isAdmin ? 'GymAssist Admin' : 'GymAssist', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: dark ? 'Tema claro' : 'Tema oscuro',
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).state = dark ? ThemeMode.light : ThemeMode.dark,
          ),
          PopupMenuButton<String>(
            tooltip: 'Perfil',
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onSelected: (v) => v == 'cuenta' ? context.go(isAdmin ? '/admin/cuenta' : '/cliente/cuenta') : _logout(context),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'cuenta', child: ListTile(leading: Icon(Icons.manage_accounts_outlined), title: Text('Cuenta'), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'salir', child: ListTile(leading: Icon(Icons.logout, color: AppColors.danger), title: Text('Cerrar sesión', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => (isAdmin && i == main.length) ? _showMore(context) : context.go(main[i].path),
        destinations: [
          for (final i in main) NavigationDestination(icon: Icon(i.icon), label: i.label),
          if (isAdmin) const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
        ],
      ),
      floatingActionButton: isAdmin ? null : const ChatbotFab(),
    );
  }
}
