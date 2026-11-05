import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final resumen = ref.watch(adminResumenProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminResumenProvider.future),
      child: PageBody(title: 'Home', children: [
        WelcomeCard(name: session?.username ?? 'Admin', subtitle: '${session?.gym?.nombre ?? 'Tu gimnasio'} · veamos cómo va hoy 💪'),
        const SizedBox(height: 20),
        ...asyncChildren(resumen, onRetry: () => ref.invalidate(adminResumenProvider), data: (r) => [
              AdaptiveGrid(minItemWidth: 150, children: [
                StatCard(icon: Icons.groups_outlined, label: 'Clientes', value: '${r.total}'),
                StatCard(icon: Icons.how_to_reg_outlined, label: 'Activos', value: '${r.activos}', color: AppColors.success),
                StatCard(icon: Icons.hourglass_bottom, label: 'Pendientes de pago', value: '${r.pendientes}', color: AppColors.warning),
                StatCard(icon: Icons.person_off_outlined, label: 'Suspendidos', value: '${r.suspendidos}', color: AppColors.danger),
                StatCard(icon: Icons.event_busy_outlined, label: 'Vencen en 7 días', value: '${r.porVencer}', color: AppColors.info),
                StatCard(icon: Icons.payments_outlined, label: 'Ingreso mensual', value: formatCop(r.ingresosMensuales), caption: 'Estimado con los activos'),
              ]),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardTitle('Accesos rápidos', icon: Icons.bolt_outlined),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    SmallActionButton('Clientes', Icons.people_outline, AppColors.accent, () => context.go('/admin/clientes')),
                    SmallActionButton('Planes (${r.planes})', Icons.card_membership_outlined, AppColors.accent, () => context.go('/admin/membresias')),
                    SmallActionButton('Rutinas (${r.rutinas})', Icons.fitness_center, AppColors.accent, () => context.go('/admin/rutinas')),
                    SmallActionButton('Predicciones IA', Icons.psychology_outlined, AppColors.info, () => context.go('/admin/predicciones')),
                  ]),
                ]),
              ),
            ]),
      ]),
    );
  }
}
