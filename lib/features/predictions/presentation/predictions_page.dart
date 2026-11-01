import 'package:flutter/material.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

enum _Filter { todos, renovara, noRenovara, critico }

class PredictionsPage extends StatefulWidget {
  const PredictionsPage({super.key});
  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

class _PredictionsPageState extends State<PredictionsPage> {
  final _all = mockPredictions(); // TODO(predictions): PredictChurn use case (árbol J48 portado a Dart)
  _Filter _filter = _Filter.todos;

  Color _riskColor(String r) => switch (r) {
        'BAJO' => AppColors.success,
        'MEDIO' => AppColors.warning,
        'ALTO' => const Color(0xFFF97316),
        'CRITICO' => AppColors.danger,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final items = _all.where((p) => switch (_filter) {
          _Filter.todos => true,
          _Filter.renovara => p.renovara,
          _Filter.noRenovara => !p.renovara,
          _Filter.critico => p.riesgo == 'CRITICO' || p.riesgo == 'ALTO',
        }).toList();
    final yes = _all.where((p) => p.renovara).length;

    return PageBody(title: 'Predicciones de renovación', children: [
      Text('Análisis predictivo para gestionar a tus clientes.', style: TextStyle(color: context.muted)),
      const SizedBox(height: 20),
      AdaptiveGrid(minItemWidth: 150, children: [
        StatCard(icon: Icons.groups_outlined, label: 'Total clientes', value: '${_all.length}'),
        StatCard(icon: Icons.check_circle_outline, label: 'Renovarán', value: '$yes', color: AppColors.success),
        StatCard(icon: Icons.cancel_outlined, label: 'No renovarán', value: '${_all.length - yes}', color: AppColors.danger),
        StatCard(icon: Icons.warning_amber_rounded, label: 'En riesgo', value: '${_all.where((p) => p.riesgo == 'ALTO' || p.riesgo == 'CRITICO').length}', color: AppColors.warning),
      ]),
      const SizedBox(height: 20),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (f, label, icon) in const [
          (_Filter.todos, 'Todos', Icons.bar_chart),
          (_Filter.renovara, 'Renovarán', Icons.check_circle_outline),
          (_Filter.noRenovara, 'No renovarán', Icons.cancel_outlined),
          (_Filter.critico, 'Críticos', Icons.error_outline),
        ])
          ChoiceChip(avatar: Icon(icon, size: 18), label: Text(label), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
      ]),
      const SizedBox(height: 20),
      if (items.isEmpty)
        const AppCard(child: EmptyState(icon: Icons.search_off, message: 'Ningún cliente coincide con este filtro.'))
      else
        for (final p in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StripeCard(
              color: p.renovara ? AppColors.success : AppColors.danger,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(p.nombre, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  StatusBadge(p.riesgo, _riskColor(p.riesgo)),
                  StatusBadge(p.renovara ? 'Renovará' : 'No renovará', p.renovara ? AppColors.success : AppColors.danger),
                ]),
                const SizedBox(height: 6),
                Text('${p.correo}  ·  ${p.telefono}', style: TextStyle(color: context.muted)),
                const SizedBox(height: 16),
                AdaptiveGrid(minItemWidth: 140, spacing: 10, children: [
                  _Feature('${p.asistencias}', 'Asistencias (4 sem)'),
                  _Feature(p.pagoAlDia ? 'Sí' : 'No', 'Pago al día'),
                  _Feature('${p.antiguedad}', 'Meses de antigüedad'),
                  _Feature(p.tipoPlan, 'Tipo de plan'),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(.14), borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.recomendacion)),
                  ]),
                ),
              ]),
            ),
          ),
    ]);
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.cs.surfaceContainerHighest.withOpacity(.5), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: context.tt.bodySmall?.copyWith(color: context.muted)),
        ]),
      );
}
