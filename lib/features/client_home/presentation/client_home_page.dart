import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(perfilProvider.future),
      child: PageBody(title: 'Inicio', children: asyncChildren(perfil, onRetry: () => ref.invalidate(perfilProvider), data: (p) {
        final c = p.cliente;
        final diasRestantes = c.fechaFinMembresia?.difference(DateTime.now()).inDays;
        return [
          WelcomeCard(name: c.nombre.split(' ').first, subtitle: '${p.gym?.nombre ?? 'Tu gimnasio'} · veamos cómo va tu progreso 💪'),
          const SizedBox(height: 20),
          if (c.estado != ClientStatus.activo) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 10),
                const Expanded(child: Text('Tu membresía no está activa. Paga para usar rutinas y registrar asistencia.')),
                TextButton(onPressed: () => context.go('/cliente/pago'), child: const Text('Pagar')),
              ]),
            ),
            const SizedBox(height: 20),
          ],
          AdaptiveGrid(minItemWidth: 150, children: [
            StatCard(icon: Icons.event_available_outlined, label: 'Asistencias', value: '${c.totalAsistencias}', color: AppColors.success),
            StatCard(icon: Icons.event_busy_outlined, label: 'Inasistencias', value: '${c.inasistencias}', color: AppColors.warning),
            StatCard(
              icon: Icons.monitor_weight_outlined,
              label: 'Último IMC',
              value: p.ultimaMedicion == null ? '-' : p.ultimaMedicion!.imc.toStringAsFixed(1),
              caption: p.ultimaMedicion?.interpretacion ?? 'Regístralo en IMC',
            ),
            StatCard(
              icon: Icons.card_membership_outlined,
              label: 'Plan ${c.planNombre ?? ''}',
              value: diasRestantes == null ? '-' : (diasRestantes < 0 ? 'Vencido' : '$diasRestantes días'),
              caption: c.fechaFinMembresia == null ? null : 'Vence ${formatDate(c.fechaFinMembresia!)}',
              color: AppColors.info,
            ),
          ]),
        ];
      })),
    );
  }
}
