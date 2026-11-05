import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/routines/presentation/routine_form.dart';

class RoutinesAdminPage extends ConsumerWidget {
  const RoutinesAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinas = ref.watch(adminRutinasProvider);
    void reload() {
      ref.invalidate(adminRutinasProvider);
      ref.invalidate(adminResumenProvider);
    }

    Future<void> delete(Rutina r) async {
      final ok = await showConfirm(context, title: '¿Eliminar rutina?', message: 'Se eliminará "${r.nombre}".', confirmLabel: 'Sí, eliminar', danger: true);
      if (!ok || !context.mounted) return;
      if (await runAction(context, () => ref.read(gymApiProvider).borrarRutina(r.id), ok: 'Rutina eliminada')) reload();
    }

    return PageBody(title: 'Rutinas', children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('Nueva rutina', icon: Icons.fitness_center),
          const SizedBox(height: 20),
          RoutineForm(
            submitLabel: 'Guardar',
            onSubmit: (f) async {
              final ok = await runAction(
                context,
                () => ref.read(gymApiProvider).crearRutina(
                    nombre: f.nombre, grupoMuscular: f.grupo, repeticiones: f.repeticiones, series: f.series, fotos: f.fotos, descripciones: f.descripciones),
                ok: f.fotos.isEmpty ? 'Rutina guardada' : 'Rutina guardada con ${f.fotos.length} foto(s) en S3',
              );
              if (ok) reload();
              return ok;
            },
          ),
        ]),
      ),
      const SizedBox(height: 24),
      const CardTitle('Rutinas existentes', icon: Icons.list_alt),
      const SizedBox(height: 12),
      ...asyncChildren(rutinas, onRetry: reload, data: (list) => [
            if (list.isEmpty)
              const AppCard(child: EmptyState(icon: Icons.fitness_center, message: 'Todavía no hay rutinas. Crea la primera arriba.'))
            else
              CardList(children: [
                for (final r in list)
                  ListCard(
                    title: r.nombre,
                    badge: StatusBadge(grupoLabel(r.grupoMuscular), AppColors.accent),
                    lines: [
                      (Icons.repeat, '${r.series} series · ${r.repeticiones} repeticiones'),
                      (Icons.image_outlined, '${r.fotos.length} fotos'),
                    ],
                    actions: [
                      SmallActionButton('Editar', Icons.edit_outlined, AppColors.accent, () => context.go('/admin/rutinas/${r.id}/editar')),
                      SmallActionButton('Eliminar', Icons.delete_outline, AppColors.danger, () => delete(r)),
                    ],
                  ),
              ]),
          ]),
    ]);
  }
}
