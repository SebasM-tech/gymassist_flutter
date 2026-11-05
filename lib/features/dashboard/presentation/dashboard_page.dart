import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';

/// Dashboard con los datos reales del gimnasio (GET /api/m/admin/dashboard).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const _mesesEs = {
    'JANUARY': 'Ene', 'FEBRUARY': 'Feb', 'MARCH': 'Mar', 'APRIL': 'Abr', 'MAY': 'May', 'JUNE': 'Jun',
    'JULY': 'Jul', 'AUGUST': 'Ago', 'SEPTEMBER': 'Sep', 'OCTOBER': 'Oct', 'NOVEMBER': 'Nov', 'DECEMBER': 'Dic',
  };

  static double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminDashboardProvider);
    final gym = ref.watch(sessionProvider).valueOrNull?.gym?.nombre ?? 'mi gimnasio';
    return PageBody(title: 'Dashboard · $gym', children: asyncChildren(data, onRetry: () => ref.invalidate(adminDashboardProvider), data: (d) {
      final dist = (d['distribucionEstados'] as Map?)?.cast<String, dynamic>() ?? const {};
      final states = [
        ('Activos', _n(dist['ACTIVO']), AppColors.success),
        ('Pendientes', _n(dist['PENDIENTE']), AppColors.warning),
        ('Suspendidos', _n(dist['SUSPENDIDO']), AppColors.danger),
      ];
      final tendencia = [for (final t in (d['tendenciaIngresos'] as List? ?? const [])) (t as Map).cast<String, dynamic>()];
      final meses = [for (final t in tendencia) _mesesEs['${t['mes']}'.toUpperCase()] ?? '${t['mes']}'];
      final ingresos = [for (final t in tendencia) _n(t['ingresos']) / 1000000];
      final maxY = ingresos.fold<double>(0, (m, v) => v > m ? v : m);
      final hayEstados = states.any((s) => s.$2 > 0);
      return [
        AdaptiveGrid(minItemWidth: 150, children: [
          StatCard(icon: Icons.payments_outlined, label: 'Ingresos del mes', value: formatCop(_n(d['ingresosMesActual'])), color: AppColors.success),
          StatCard(icon: Icons.person_add_alt_1_outlined, label: 'Clientes nuevos este mes', value: '${_n(d['clientesNuevosEsteMes']).toInt()}'),
          StatCard(icon: Icons.how_to_reg_outlined, label: 'Clientes activos', value: '${_n(d['clientesActivos']).toInt()}', color: AppColors.success),
          StatCard(icon: Icons.event_busy_outlined, label: 'Por vencer (7 días)', value: '${_n(d['suscripcionesPorVencer']).toInt()}', color: AppColors.warning),
          StatCard(icon: Icons.date_range_outlined, label: 'Ingresos de la semana', value: formatCop(_n(d['ingresosSemanales'])), color: AppColors.info),
          StatCard(icon: Icons.account_balance_wallet_outlined, label: 'Ingresos totales', value: formatCop(_n(d['ingresosTotales']))),
        ]),
        const SizedBox(height: 24),
        AdaptiveGrid(minItemWidth: 420, spacing: 20, children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('Ingresos de los últimos 6 meses (millones)', icon: Icons.bar_chart),
              const SizedBox(height: 20),
              SizedBox(
                height: 260,
                child: tendencia.isEmpty
                    ? const EmptyState(icon: Icons.bar_chart, message: 'Aún no hay ingresos registrados.')
                    : BarChart(BarChartData(
                        maxY: maxY <= 0 ? 1 : maxY * 1.2,
                        gridData: const FlGridData(drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(1)}M', style: const TextStyle(fontSize: 11)))),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, m) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(v.toInt() < meses.length ? meses[v.toInt()] : '', style: const TextStyle(fontSize: 12))))),
                        ),
                        barGroups: [
                          for (var i = 0; i < ingresos.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(toY: ingresos[i], width: 22, color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
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
                child: !hayEstados
                    ? const EmptyState(icon: Icons.donut_large, message: 'Aún no hay clientes.')
                    : PieChart(PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 44,
                        sections: [
                          for (final s in states)
                            if (s.$2 > 0)
                              PieChartSectionData(value: s.$2, color: s.$3, radius: 60, title: '${s.$2.toInt()}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      )),
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 16, runSpacing: 8, children: [
                for (final s in states)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${s.$1} (${s.$2.toInt()})'),
                  ]),
              ]),
            ]),
          ),
        ]),
      ];
    }));
  }
}
