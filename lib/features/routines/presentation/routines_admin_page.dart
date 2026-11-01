import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/routines/presentation/routine_form.dart';

class RoutinesAdminPage extends StatefulWidget {
  const RoutinesAdminPage({super.key});
  @override
  State<RoutinesAdminPage> createState() => _RoutinesAdminPageState();
}

class _RoutinesAdminPageState extends State<RoutinesAdminPage> {
  final _routines = mockRoutines(); // TODO(routines): RoutinesViewModel + RoutineRepository
  int _formVersion = 0; // cambia para reiniciar el formulario tras guardar

  Future<void> _delete(MockRoutine r) async {
    final ok = await showConfirm(context, title: '¿Eliminar rutina?', message: 'Se eliminará "${r.ejercicio}" y sus fotos.', confirmLabel: 'Sí, eliminar', danger: true);
    if (ok && mounted) {
      setState(() => _routines.remove(r));
      showToast(context, 'Rutina eliminada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(title: 'Rutinas', children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('Nueva rutina', icon: Icons.fitness_center),
          const SizedBox(height: 20),
          RoutineForm(
            key: ValueKey(_formVersion),
            submitLabel: 'Guardar',
            onSaved: () {
              setState(() => _formVersion++);
              showToast(context, 'Rutina guardada');
            },
          ),
        ]),
      ),
      const SizedBox(height: 24),
      const CardTitle('Rutinas existentes', icon: Icons.list_alt),
      const SizedBox(height: 12),
      if (_routines.isEmpty)
        const AppCard(child: EmptyState(icon: Icons.fitness_center, message: 'Todavía no hay rutinas. Crea la primera arriba.'))
      else
        CardList(children: [
          for (final r in _routines)
            ListCard(
              title: r.ejercicio,
              badge: StatusBadge(r.grupo, AppColors.accent),
              lines: [
                (Icons.repeat, '${r.series} series · ${r.repeticiones} repeticiones'),
                (Icons.image_outlined, '${r.fotos.length} fotos'),
              ],
              actions: [
                SmallActionButton('Editar', Icons.edit_outlined, AppColors.accent, () => context.go('/admin/rutinas/${r.id}/editar')),
                SmallActionButton('Eliminar', Icons.delete_outline, AppColors.danger, () => _delete(r)),
              ],
            ),
        ]),
    ]);
  }
}
