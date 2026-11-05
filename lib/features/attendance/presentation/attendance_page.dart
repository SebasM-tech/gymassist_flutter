import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});
  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  final _selected = <String>{};
  final _filtro = TextEditingController();
  bool _showTimeline = true;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _filtro.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Debes seleccionar al menos un músculo trabajado.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await runAction(context, () => ref.read(gymApiProvider).registrarAsistencia(_selected.toList()), ok: 'Asistencia registrada');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _selected.clear();
        _error = null;
      }
    });
    if (ok) {
      ref.invalidate(asistenciasProvider);
      ref.invalidate(perfilProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(asistenciasProvider);
    final gym = ref.watch(sessionProvider).valueOrNull?.gym?.nombre ?? '-';
    final data = info.valueOrNull;
    final items = data?.asistencias ?? const <Asistencia>[];
    final yaHoy = data?.hoyRegistrada ?? false;
    final q = _filtro.text.trim().toLowerCase();
    final list = items.where((a) => '${formatDate(a.fecha)} ${a.musculos.map(grupoLabel).join(' ')}'.toLowerCase().contains(q)).toList();

    final register = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Registrar asistencia', icon: Icons.edit_calendar_outlined),
        const SizedBox(height: 16),
        AppTextField(label: 'Fecha', icon: Icons.calendar_today_outlined, readOnly: true, controller: TextEditingController(text: formatDate(DateTime.now()))),
        const SizedBox(height: 16),
        Text('Músculos trabajados', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in gruposMusculares)
            FilterChip(
              label: Text(g.$2),
              selected: _selected.contains(g.$1),
              onSelected: yaHoy ? null : (v) => setState(() {
                v ? _selected.add(g.$1) : _selected.remove(g.$1);
                _error = null;
              }),
            ),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.danger.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        GradientButton(label: yaHoy ? 'Ya registraste hoy ✅' : (_busy ? 'Registrando…' : 'Registrar'), icon: Icons.check, expanded: true, onPressed: (yaHoy || _busy) ? null : _register),
      ]),
    );

    final timeline = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Historial de asistencia', icon: Icons.history),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _filtro,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Buscar asistencia', prefixIcon: Icon(Icons.search)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: _showTimeline ? 'Ocultar' : 'Mostrar',
            onPressed: () => setState(() => _showTimeline = !_showTimeline),
            icon: Icon(_showTimeline ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          ),
        ]),
        if (_showTimeline) ...[
          const SizedBox(height: 12),
          if (info.isLoading && data == null)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (info.hasError)
            ErrorCard(message: '${info.error}', onRetry: () => ref.invalidate(asistenciasProvider))
          else if (list.isEmpty)
            const EmptyState(icon: Icons.event_busy_outlined, message: 'Todavía no hay asistencias. Registra la primera.')
          else
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StripeCard(
                  color: AppColors.accent,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(formatDate(a.fecha), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
                    Text(a.musculos.map(grupoLabel).join(', ')),
                  ]),
                ),
              ),
        ],
      ]),
    );

    return PageBody(title: 'Asistencia', children: [
      AdaptiveGrid(minItemWidth: 150, children: [
        StatCard(icon: Icons.store_mall_directory_outlined, label: 'Gimnasio al que perteneces', value: gym),
        StatCard(icon: Icons.event_available_outlined, label: 'Asistencias', value: '${items.length}', color: AppColors.success),
        StatCard(icon: Icons.event_busy_outlined, label: 'Total de inasistencias', value: '${data?.inasistencias ?? 0}', color: AppColors.warning),
      ]),
      const SizedBox(height: 24),
      register, const SizedBox(height: 20), timeline,
    ]);
  }
}
