import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

/// Reemplaza el iframe de Power BI. TODO(dashboard): alimentar con consultas agregadas de Drift.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _months = ['Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov'];
  static const _income = [3.2, 3.6, 4.1, 3.9, 4.4, 4.85]; // millones COP

  @override
  Widget build(BuildContext context) {
    const states = [('Activos', 87.0, AppColors.success), ('Pendientes', 21.0, AppColors.warning), ('Suspendidos', 8.0, AppColors.danger)];
    return PageBody(title: 'Dashboard · FitLife Gym', children: [
      AdaptiveGrid(minItemWidth: 150, children: [
        StatCard(icon: Icons.payments_outlined, label: 'Ingresos del mes', value: formatCop(4850000), color: AppColors.success),
        StatCard(icon: Icons.person_add_alt_1_outlined, label: 'Clientes nuevos este mes', value: '12'),
        StatCard(icon: Icons.how_to_reg_outlined, label: 'Clientes activos', value: '87', color: AppColors.success),
        StatCard(icon: Icons.event_busy_outlined, label: 'Por vencer (7 días)', value: '9', color: AppColors.warning),
        StatCard(icon: Icons.date_range_outlined, label: 'Ingresos de la semana', value: formatCop(1240000), color: AppColors.info),
        StatCard(icon: Icons.account_balance_wallet_outlined, label: 'Ingresos totales', value: formatCop(18600000)),
      ]),
      const SizedBox(height: 24),
      AdaptiveGrid(minItemWidth: 420, spacing: 20, children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('Ingresos de los últimos 6 meses (millones)', icon: Icons.bar_chart),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: BarChart(BarChartData(
                gridData: const FlGridData(drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(0)}M', style: const TextStyle(fontSize: 11)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(_months[v.toInt()], style: const TextStyle(fontSize: 12))))),
                ),
                barGroups: [
                  for (var i = 0; i < _income.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: _income[i], width: 22, color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                    ]),
                ],
              )),
            ),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('Distribución de estados', icon: Icons.donut_large),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 44,
                sections: [
                  for (final s in states) PieChartSectionData(value: s.$2, color: s.$3, radius: 60, title: '${s.$2.toInt()}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              )),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 8, children: [
              for (final s in states)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(s.$1),
                ]),
            ]),
          ]),
        ),
      ]),
    ]);
  }
}
