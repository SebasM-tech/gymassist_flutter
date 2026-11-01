import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/routines/presentation/routine_form.dart';

class RoutineEditPage extends StatelessWidget {
  const RoutineEditPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final routines = mockRoutines(); // TODO(routines): GetRoutineById
    final r = routines.firstWhere((x) => x.id == id, orElse: () => routines.first);
    return PageBody(title: 'Editar rutina', maxWidth: 900, children: [
      AppCard(
        child: RoutineForm(
          initial: r,
          submitLabel: 'Actualizar',
          onSaved: () {
            showToast(context, 'Rutina actualizada');
            context.go('/admin/rutinas');
          },
        ),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: () => context.go('/admin/rutinas'), icon: const Icon(Icons.arrow_back), label: const Text('Volver a rutinas')),
      ),
    ]);
  }
}
