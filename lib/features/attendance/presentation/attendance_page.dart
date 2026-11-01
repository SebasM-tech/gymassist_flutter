import 'package:flutter/material.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _items = mockAttendances(); // TODO(attendance): AttendanceViewModel + RegisterAttendance use case
  final _selected = <String>{};
  final _filtro = TextEditingController();
  bool _showTimeline = true;
  String? _error;
  int _missed = 3;

  @override
  void dispose() {
    _filtro.dispose();
    super.dispose();
  }

  void _register() {
    if (_selected.isEmpty) {
      setState(() => _error = 'Debes seleccionar al menos un músculo trabajado.');
      return;
    }
    // TODO(attendance): la regla de inasistencias (huecos de días) vive en el use case.
    setState(() {
      _items.insert(0, MockAttendance(DateTime.now(), _selected.toList()));
      _selected.clear();
      _error = null;
    });
    showToast(context, 'Asistencia registrada');
  }

  @override
  Widget build(BuildContext context) {
    final q = _filtro.text.trim().toLowerCase();
    final list = _items.where((a) => '${formatDate(a.fecha)} ${a.musculos.join(' ')}'.toLowerCase().contains(q)).toList();

    final register = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Registrar asistencia', icon: Icons.edit_calendar_outlined),
        const SizedBox(height: 16),
        AppTextField(label: 'Fecha', icon: Icons.calendar_today_outlined, readOnly: true, controller: TextEditingController(text: formatDate(DateTime.now()))),
        const SizedBox(height: 16),
        Text('Músculos trabajados', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in muscleGroups)
            FilterChip(
              label: Text(g),
              selected: _selected.contains(g),
              onSelected: (v) => setState(() {
                v ? _selected.add(g) : _selected.remove(g);
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
        GradientButton(label: 'Registrar', icon: Icons.check, expanded: true, onPressed: _register),
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
          if (list.isEmpty)
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
                    Text(a.musculos.join(', ')),
                  ]),
                ),
              ),
        ],
      ]),
    );

    return PageBody(title: 'Asistencia', children: [
      AdaptiveGrid(minItemWidth: 150, children: [
        const StatCard(icon: Icons.store_mall_directory_outlined, label: 'Gimnasio al que perteneces', value: 'FitLife Gym'),
        StatCard(icon: Icons.event_busy_outlined, label: 'Total de inasistencias', value: '$_missed', color: AppColors.warning),
      ]),
      const SizedBox(height: 24),
      register, const SizedBox(height: 20), timeline,
    ]);
  }
}
