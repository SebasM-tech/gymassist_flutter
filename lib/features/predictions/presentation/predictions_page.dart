import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/config/api_config.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/predictions/data/predictions_providers.dart';
import 'package:gymassist/features/predictions/domain/prediction_domain.dart';

enum _Filter { todos, renovara, noRenovara, critico }

Color riskColor(String r) => switch (r) {
      'BAJO' => AppColors.success,
      'MEDIO' => AppColors.warning,
      'ALTO' => const Color(0xFFF97316),
      'CRITICO' => AppColors.danger,
      _ => Colors.grey,
    };

/// Predicción de deserción: los datos salen de la base local, se envían a la API FastAPI
/// (`prediccion-ml/` en GymAssist2.0) y la red LSTM de TensorFlow devuelve probabilidad, factores y recomendación.
class PredictionsPage extends ConsumerStatefulWidget {
  const PredictionsPage({super.key});
  @override
  ConsumerState<PredictionsPage> createState() => _PredictionsPageState();
}

class _PredictionsPageState extends ConsumerState<PredictionsPage> {
  _Filter _filter = _Filter.todos;

  void _refresh() => ref.invalidate(predictionsReportProvider);

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(predictionsReportProvider);
    return PageBody(
      title: 'Predicciones de renovación',
      trailing: IconButton(
        tooltip: 'Volver a predecir',
        onPressed: report.isLoading ? null : _refresh,
        icon: const Icon(Icons.refresh),
      ),
      children: [
        Text('Red neuronal LSTM (TensorFlow) servida con FastAPI.', style: TextStyle(color: context.muted)),
        const SizedBox(height: 20),
        ...report.when<List<Widget>>(
          skipLoadingOnRefresh: false,
          loading: () => [const _LoadingCard()],
          error: (e, _) => [_ErrorCard(error: e, onRetry: _refresh)],
          data: (r) => _content(context, r),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, PredictionsReport r) {
    final all = r.items;
    if (all.isEmpty) {
      return [
        _ModelCard(health: r.health),
        const SizedBox(height: 16),
        const AppCard(
          child: EmptyState(
            icon: Icons.person_search_outlined,
            message: 'No hay clientes registrados para predecir.\nAgrégalos en la sección Clientes.',
          ),
        ),
      ];
    }
    final items = all.where((p) => switch (_filter) {
          _Filter.todos => true,
          _Filter.renovara => p.renovara,
          _Filter.noRenovara => !p.renovara,
          _Filter.critico => p.riesgo == 'CRITICO' || p.riesgo == 'ALTO',
        }).toList();
    final yes = all.where((p) => p.renovara).length;
    final risk = all.where((p) => p.riesgo == 'ALTO' || p.riesgo == 'CRITICO').length;
    final avg = all.fold<double>(0, (s, p) => s + p.probabilidadAbandono) / all.length;

    return [
      _ModelCard(health: r.health),
      const SizedBox(height: 20),
      AdaptiveGrid(minItemWidth: 150, children: [
        StatCard(icon: Icons.groups_outlined, label: 'Total clientes', value: '${all.length}'),
        StatCard(icon: Icons.check_circle_outline, label: 'Renovarán', value: '$yes', color: AppColors.success),
        StatCard(icon: Icons.cancel_outlined, label: 'No renovarán', value: '${all.length - yes}', color: AppColors.danger),
        StatCard(icon: Icons.warning_amber_rounded, label: 'En riesgo', value: '$risk', color: AppColors.warning, caption: 'Riesgo medio: ${(avg * 100).round()}%'),
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
        for (final p in items) Padding(padding: const EdgeInsets.only(bottom: 16), child: _PredictionCard(p: p)),
    ];
  }
}

// --------------------------------------------------------------------------- tarjetas

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.health});
  final ModelHealth health;

  String _pct(double? v) => v == null ? '-' : '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.hub_outlined, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(child: Text('Modelo LSTM + Densa', style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            const StatusBadge('API conectada', AppColors.success),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 6, children: [
            Text('AUC ${health.auc?.toStringAsFixed(3) ?? '-'}', style: TextStyle(color: context.muted)),
            Text('Recall ${_pct(health.recall)}', style: TextStyle(color: context.muted)),
            Text('Umbral ${health.umbral?.toStringAsFixed(2) ?? '-'}', style: TextStyle(color: context.muted)),
            if (health.version != null) Text('v${health.version}', style: TextStyle(color: context.muted)),
          ]),
          const SizedBox(height: 4),
          Text(ApiConfig.mlApiBaseUrl, style: context.tt.bodySmall?.copyWith(color: context.muted)),
        ]),
      );
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.p});
  final ChurnPrediction p;

  @override
  Widget build(BuildContext context) {
    final rc = riskColor(p.riesgo);
    return _StripeBox(
      color: p.renovara ? AppColors.success : AppColors.danger,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(p.nombre, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          StatusBadge(p.riesgo, rc),
          StatusBadge(p.renovara ? 'Renovará' : 'No renovará', p.renovara ? AppColors.success : AppColors.danger),
        ]),
        if (p.correo.isNotEmpty || p.telefono.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text([p.correo, p.telefono].where((s) => s.isNotEmpty).join('  ·  '), style: TextStyle(color: context.muted)),
        ],
        const SizedBox(height: 16),

        // Probabilidad de abandono
        Row(children: [
          Text('Probabilidad de abandono', style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${p.porcentaje}%', style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: rc)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p.probabilidadAbandono.clamp(0, 1).toDouble(),
            minHeight: 10,
            color: rc,
            backgroundColor: rc.withOpacity(.15),
          ),
        ),
        const SizedBox(height: 16),

        AdaptiveGrid(minItemWidth: 140, spacing: 10, children: [
          _Feature('${p.asistencias4Semanas}', 'Asistencias (4 sem)'),
          _Feature(p.pagoAlDia ? 'Sí' : 'No', 'Pago al día'),
          _Feature('${p.antiguedadMeses}', 'Meses de antigüedad'),
          _Feature(p.tipoPlan, 'Tipo de plan'),
        ]),

        if (p.asistenciaSemanal.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Asistencia semanal (lo que lee la LSTM)', style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _WeeklyBars(weeks: p.asistenciaSemanal, color: AppColors.accent),
        ],

        if (p.factores.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('¿Por qué? Factores principales', style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final f in p.factores) _FactorRow(f),
        ],

        const SizedBox(height: 12),
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
    );
  }
}

/// Igual a StripeCard pero sin IntrinsicHeight: AdaptiveGrid usa LayoutBuilder,
/// que no puede calcular su altura intrínseca y rompía el layout.
class _StripeBox extends StatelessWidget {
  const _StripeBox({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
        ),
        child: Stack(children: [
          Padding(padding: const EdgeInsets.fromLTRB(25, 20, 20, 20), child: child),
          Positioned(left: 0, top: 0, bottom: 0, width: 5, child: ColoredBox(color: color)),
        ]),
      );
}

class _FactorRow extends StatelessWidget {
  const _FactorRow(this.f);
  final ChurnFactor f;

  @override
  Widget build(BuildContext context) {
    final color = f.aumentaRiesgo ? AppColors.danger : AppColors.success;
    final pts = (f.impacto * 100).abs().toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(f.aumentaRiesgo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.factor, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (f.descripcion.isNotEmpty) Text(f.descripcion, style: context.tt.bodySmall?.copyWith(color: context.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${f.aumentaRiesgo ? '+' : '−'}$pts pts', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Mini gráfica de barras: visitas por semana (12 semanas, la última a la derecha).
class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.weeks, required this.color});
  final List<int> weeks;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = weeks.fold<int>(1, (m, v) => v > m ? v : m);
    return Column(children: [
      SizedBox(
        height: 56,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < weeks.length; i++)
            Expanded(
              child: Tooltip(
                message: '${i == weeks.length - 1 ? 'Esta semana' : 'Hace ${weeks.length - 1 - i} sem'}: ${weeks[i]} visitas',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: weeks[i] == 0 ? 3 : 56 * weeks[i] / maxV,
                  decoration: BoxDecoration(
                    color: weeks[i] == 0 ? context.border : color.withOpacity(i >= weeks.length - 4 ? 1 : .45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Text('hace 12 sem', style: context.tt.bodySmall?.copyWith(color: context.muted)),
        const Spacer(),
        Text('esta semana', style: context.tt.bodySmall?.copyWith(color: context.muted)),
      ]),
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

// --------------------------------------------------------------------------- estados

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Consultando la red neuronal…', style: context.tt.bodyLarge),
          const SizedBox(height: 4),
          Text(ApiConfig.mlApiBaseUrl, style: TextStyle(color: context.muted)),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is PredictionApiException && (error as PredictionApiException).apiOffline;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(offline ? Icons.cloud_off_outlined : Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(offline ? 'La API de predicción está apagada' : 'No se pudo obtener la predicción',
                style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        Text('$error'),
        if (offline) ...[
          const SizedBox(height: 14),
          Text('Enciéndela en otra terminal:', style: TextStyle(color: context.muted)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
            child: const SelectableText(
              'cd GymAssist2.0\\prediccion-ml\n.venv\\Scripts\\activate\nuvicorn app.main:app --host 0.0.0.0 --port 8000',
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 16),
        GradientButton(label: 'Reintentar', icon: Icons.refresh, onPressed: onRetry),
      ]),
    );
  }
}
