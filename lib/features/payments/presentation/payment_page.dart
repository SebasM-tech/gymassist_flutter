import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membresía del cliente: estado, cambio de plan y pago con Mercado Pago.
/// Spring Boot crea el cobro (con su clave) y la app solo abre el link de pago.
/// Cuando Mercado Pago aprueba, el webhook del backend activa la membresía.
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, this.resultado});

  /// Lo pone el backend al volver de Mercado Pago (Flutter web): aprobado, pendiente, rechazado…
  final String? resultado;
  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String? _newPlan;
  bool _busy = false;
  bool _waitingReturn = false;
  Timer? _poll;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    final r = widget.resultado;
    if (r != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _refresh();
        if (!mounted) return;
        final msg = switch (r) {
          'aprobado' => '¡Pago aprobado! Tu membresía ya está activa.',
          'pendiente' || 'in_process' || 'pending' => 'Tu pago está pendiente de confirmación en Mercado Pago.',
          'rechazado' || 'rejected' => 'El pago fue rechazado. Intenta de nuevo.',
          _ => 'Volviste de Mercado Pago (estado: $r).',
        };
        showToast(context, msg, error: r != 'aprobado');
        if (r != 'aprobado') _startPolling();
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(perfilProvider);
    await ref.read(sessionProvider.notifier).refresh();
  }

  /// Mientras el cliente paga (o si el webhook tarda), revisa el estado cada 5 s durante 3 minutos.
  void _startPolling() {
    _poll?.cancel();
    _polls = 0;
    _poll = Timer.periodic(const Duration(seconds: 5), (t) async {
      _polls++;
      await ref.read(sessionProvider.notifier).refresh();
      final activo = ref.read(sessionProvider).valueOrNull?.cliente?.activo ?? false;
      if (activo || _polls >= 36 || !mounted) {
        t.cancel();
        if (activo && mounted) {
          ref.invalidate(perfilProvider);
          setState(() => _waitingReturn = false);
          showToast(context, '¡Pago confirmado! Tu membresía está activa.');
        }
      }
    });
  }

  Future<void> _pay() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // En Chrome, Mercado Pago vuelve a esta misma pantalla (el backend redirige con ?pago=...).
      final returnUrl = kIsWeb ? '${Uri.base.origin}/#/cliente/pago' : null;
      final url = await ref.read(gymApiProvider).crearPago(returnUrl: returnUrl);
      final ok = kIsWeb
          ? await launchUrl(Uri.parse(url), webOnlyWindowName: '_self')
          : await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('No se pudo abrir Mercado Pago');
      if (mounted) setState(() => _waitingReturn = true);
      _startPolling();
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePlan() async {
    final id = _newPlan;
    if (id == null) return;
    if (await runAction(context, () => ref.read(gymApiProvider).cambiarPlan(id), ok: 'Plan actualizado. Ya puedes pagar.')) {
      setState(() => _newPlan = null);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilProvider);
    final planes = ref.watch(planesClienteProvider).valueOrNull ?? const <Plan>[];
    return RefreshIndicator(
      onRefresh: _refresh,
      child: PageBody(title: 'Mi membresía', children: asyncChildren(perfil, onRetry: _refresh, data: (p) {
        final c = p.cliente;
        final pending = c.estado != ClientStatus.activo;
        final precio = c.planPrecio == null ? '-' : formatCop(c.planPrecio!);
        return [
          AppCard(
            child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: const BoxDecoration(gradient: brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 12),
              Text(c.nombre, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              StatusBadge.forClient(c.estado),
              const SizedBox(height: 12),
              InfoRow('Usuario', '@${c.username}'),
              InfoRow('Gimnasio', p.gym?.nombre ?? '-'),
              InfoRow('Plan', c.planNombre ?? 'Sin plan'),
              InfoRow('Precio', precio),
            ]),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('Estado de la membresía', icon: Icons.credit_card_outlined),
              const SizedBox(height: 16),
              if (pending) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(.14), borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(c.estado == ClientStatus.suspendido
                          ? 'Tu cuenta está suspendida. Habla con el administrador del gimnasio.'
                          : 'Tu plan ${c.planNombre ?? ''} está pendiente de pago ($precio). Paga en línea con Mercado Pago o en recepción.'),
                    ),
                  ]),
                ),
                if (c.estado == ClientStatus.pendiente) ...[
                  const SizedBox(height: 16),
                  GradientButton(
                    label: _busy ? 'Abriendo Mercado Pago…' : 'Pagar con Mercado Pago',
                    icon: Icons.payment,
                    expanded: true,
                    gradient: const LinearGradient(colors: [Color(0xFF009EE3), Color(0xFF0070BA)]),
                    onPressed: (_busy || c.planId == null) ? null : _pay,
                  ),
                  if (_waitingReturn) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Ya pagué: actualizar estado')),
                  ],
                ],
                const SizedBox(height: 20),
                Text('¿Quieres cambiar de plan?', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _newPlan,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Nuevo plan', prefixIcon: Icon(Icons.swap_horiz, size: 20)),
                  items: [
                    for (final pl in planes.where((pl) => pl.id != c.planId))
                      DropdownMenuItem(value: pl.id, child: Text('${pl.nombre} - ${formatCop(pl.precio)} / ${pl.duracionMeses} meses', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _newPlan = v),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Actualizar plan',
                  icon: Icons.sync,
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  onPressed: _newPlan == null ? null : _changePlan,
                ),
              ] else ...[
                Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Tu membresía ${c.planNombre ?? ''} está activa.', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 8),
                if (c.fechaInicioMembresia != null) Text('Desde: ${formatDate(c.fechaInicioMembresia!)}'),
                if (c.fechaFinMembresia != null) Text('Válida hasta: ${formatDate(c.fechaFinMembresia!)}'),
              ],
            ]),
          ),
        ];
      })),
    );
  }
}
