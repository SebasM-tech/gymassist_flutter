import 'package:flutter/material.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

const _fields = [
  ('Ingreso por cada usuario activo', 'I', Icons.paid_outlined),
  ('Costo operativo por cada usuario activo', 'C', Icons.receipt_long_outlined),
  ('Pérdida por cada usuario moroso', 'P', Icons.person_off_outlined),
  ('Capacidad máxima del gimnasio', 'K', Icons.groups_outlined),
  ('% máximo permitido de usuarios morosos', 'M', Icons.percent),
  ('Capacidad operativa de entrenadores', 'E', Icons.fitness_center),
  ('Ganancia mínima requerida', 'Gmin', Icons.trending_up),
  ('Capacidad promedio diaria de asistencia', 'A', Icons.apartment),
  ('Asistencia promedio de usuarios activos', 'a1', Icons.straighten),
  ('Asistencia promedio de usuarios morosos', 'a2', Icons.straighten),
  ('Mínimo de usuarios activos requeridos', 'Umin', Icons.how_to_reg_outlined),
  ('Capacidad tecnológica máxima del sistema', 'T', Icons.memory),
  ('% mínimo de retención', 'R', Icons.bar_chart),
];

const _constraints = [
  'x₁ + x₂ ≤ K', 'x₁ ≥ x₂', 'x₂ ≤ M(x₁+x₂)', 'x₂ ≤ E', '(I−C)x₁ − Px₂ ≥ Gmin',
  'a₁x₁ + a₂x₂ ≤ A', 'x₁ ≥ Umin', 'x₁ + x₂ ≤ T', 'x₁ ≥ R(x₁+x₂)',
];

class OptimizationPage extends StatefulWidget {
  const OptimizationPage({super.key});
  @override
  State<OptimizationPage> createState() => _OptimizationPageState();
}

class _OptimizationPageState extends State<OptimizationPage> {
  final _key = GlobalKey<FormState>();
  final _ctrls = [for (final _ in _fields) TextEditingController()];
  bool _solved = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _solve() {
    if (!_key.currentState!.validate()) return;
    // TODO(optimization): SolveOptimizationModel (solver entero en Dart; reemplaza Pyomo/GLPK).
    setState(() => _solved = true);
  }

  @override
  Widget build(BuildContext context) {
    final form = AppCard(
      child: Form(
        key: _key,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('Parámetros del modelo', icon: Icons.tune),
          const SizedBox(height: 20),
          AdaptiveGrid(minItemWidth: 240, children: [
            for (var i = 0; i < _fields.length; i++)
              AppTextField(
                label: '${_fields[i].$1} (${_fields[i].$2})',
                icon: _fields[i].$3,
                controller: _ctrls[i],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.number,
              ),
          ]),
          const SizedBox(height: 24),
          GradientButton(label: 'Resolver modelo', icon: Icons.calculate_outlined, expanded: true, onPressed: _solve),
        ]),
      ),
    );

    final results = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Resultados de optimización', icon: Icons.pie_chart_outline),
        const SizedBox(height: 16),
        if (!_solved)
          const EmptyState(icon: Icons.functions, message: 'Ingresa los parámetros y resuelve el modelo para ver los resultados aquí.')
        else ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(.14), borderRadius: BorderRadius.circular(10)),
            child: const Text('Valores de ejemplo: el solver llega en la fase 10 del plan.', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 16),
          const AdaptiveGrid(minItemWidth: 150, spacing: 10, children: [
            StatCard(icon: Icons.groups_outlined, label: 'Clientes óptimos', value: '80'),
            StatCard(icon: Icons.fitness_center, label: 'Entrenadores', value: '20', color: AppColors.info),
            StatCard(icon: Icons.attach_money, label: 'Ganancia máxima', value: r'$ 4.2M', color: AppColors.success),
            StatCard(icon: Icons.percent, label: 'Ocupación', value: '67 %', color: AppColors.warning),
          ]),
          const SizedBox(height: 20),
          Text('Distribución óptima', style: context.tt.titleSmall?.copyWith(color: context.muted)),
          const SizedBox(height: 10),
          const _Bar('Clientes', .8, AppColors.accent),
          const _Bar('Entrenadores', .2, AppColors.info),
        ],
        const SizedBox(height: 24),
        const CardTitle('Restricciones del sistema', icon: Icons.lock_outline),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _constraints) Chip(label: Text(c, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        ]),
      ]),
    );

    return PageBody(
      title: 'Modelo de optimización',
      children: [
        Text('Calcula la distribución óptima de clientes y entrenadores para maximizar la ganancia del gimnasio.', style: TextStyle(color: context.muted)),
        const SizedBox(height: 20),
        form, const SizedBox(height: 20), results,
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.label, this.fraction, this.color);
  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: context.muted))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: fraction, minHeight: 22, color: color, backgroundColor: context.border),
            ),
          ),
        ]),
      );
}
