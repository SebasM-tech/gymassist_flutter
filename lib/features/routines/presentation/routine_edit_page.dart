import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/routines/presentation/routine_form.dart';

class RoutineEditPage extends ConsumerWidget {
  const RoutineEditPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinas = ref.watch(adminRutinasProvider);
    return PageBody(title: 'Editar rutina', maxWidth: 900, children: [
      ...asyncChildren(rutinas, onRetry: () => ref.invalidate(adminRutinasProvider), data: (list) {
        final matches = list.where((x) => x.id == id);
        if (matches.isEmpty) return const [AppCard(child: EmptyState(icon: Icons.search_off, message: 'La rutina no existe.'))];
        final r = matches.first;
        return [
          AppCard(
            child: RoutineForm(
              initial: r,
              submitLabel: 'Actualizar',
              onSubmit: (f) async {
                final ok = await runAction(
                  context,
                  () => ref.read(gymApiProvider).editarRutina(r.id, nombre: f.nombre, grupoMuscular: f.grupo, repeticiones: f.repeticiones, series: f.series),
                  ok: 'Rutina actualizada',
                );
                if (ok) {
                  ref.invalidate(adminRutinasProvider);
                  if (context.mounted) context.go('/admin/rutinas');
                }
                return ok;
              },
            ),
          ),
        ];
      }),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: () => context.go('/admin/rutinas'), icon: const Icon(Icons.arrow_back), label: const Text('Volver a rutinas')),
      ),
    ]);
  }
}
