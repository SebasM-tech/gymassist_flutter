import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

class ImcPage extends ConsumerStatefulWidget {
  const ImcPage({super.key});
  @override
  ConsumerState<ImcPage> createState() => _ImcPageState();
}

class _ImcPageState extends ConsumerState<ImcPage> {
  final _key = GlobalKey<FormState>();
  final _peso = TextEditingController();
  final _estatura = TextEditingController();
  final _filtro = TextEditingController();
  bool _busy = false;
  bool _showHistory = true;

  @override
  void dispose() {
    for (final c in [_peso, _estatura, _filtro]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(gymApiProvider).guardarMedicion(peso: Validators.parse(_peso.text)!, estatura: Validators.parse(_estatura.text)!),
      ok: 'Medición guardada',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _peso.clear();
      _estatura.clear();
      _key.currentState!.reset();
      ref.invalidate(medicionesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediciones = ref.watch(medicionesProvider);
    final items = mediciones.valueOrNull ?? const <Medicion>[];
    final last = items.isEmpty ? null : items.first;
    final q = _filtro.text.trim();
    final history = items.where((m) => m.fecha == null || formatDate(m.fecha!).contains(q)).toList();

    return PageBody(title: 'Índice de masa corporal', maxWidth: 900, children: [
      AppCard(
        child: Form(
          key: _key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('Calcula tu IMC', icon: Icons.monitor_weight_outlined),
            const SizedBox(height: 20),
            AdaptiveGrid(minItemWidth: 240, children: [
              AppTextField(label: 'Peso (kg)', icon: Icons.scale_outlined, controller: _peso, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: Validators.positive),
              AppTextField(label: 'Estatura (m)', icon: Icons.height, controller: _estatura, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: Validators.positive),
            ]),
            const SizedBox(height: 20),
            GradientButton(label: _busy ? 'Guardando…' : 'Calcular y guardar', icon: Icons.calculate_outlined, onPressed: _busy ? null : _save),
            if (last != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(.1), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tu último registro de IMC', style: context.tt.titleSmall?.copyWith(color: context.muted)),
                  const SizedBox(height: 4),
                  Text(last.imc.toStringAsFixed(1), style: context.tt.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accent)),
                  Text('Interpretación: ${last.interpretacion}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 24),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('Historial de mediciones', icon: Icons.history),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _filtro,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Buscar por fecha (AAAA-MM-DD)', prefixIcon: Icon(Icons.search)),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showHistory = !_showHistory),
              icon: Icon(_showHistory ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              label: Text(_showHistory ? 'Ocultar' : 'Mostrar'),
            ),
          ]),
          if (_showHistory) ...[
            const SizedBox(height: 12),
            if (mediciones.isLoading && items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (mediciones.hasError)
              ErrorCard(message: '${mediciones.error}', onRetry: () => ref.invalidate(medicionesProvider))
            else if (history.isEmpty)
              EmptyState(icon: Icons.search_off, message: items.isEmpty ? 'Aún no tienes mediciones. Registra la primera arriba.' : 'No hay mediciones para esa fecha.')
            else
              for (final m in history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.monitor_weight_outlined, size: 18)),
                  title: Text(m.fecha == null ? '-' : formatDate(m.fecha!)),
                  subtitle: Text('${m.peso} kg · ${m.estatura} m · ${m.interpretacion}'),
                  trailing: Text('IMC ${m.imc.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
          ],
        ]),
      ),
    ]);
  }
}
