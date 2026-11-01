import 'package:flutter/material.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

/// Reemplaza ClientePago + checkout + payment-success/failure.
/// Sin conexión no hay pasarela: el administrador registra el pago (ver /admin/clientes).
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // TODO(payments): estado y pagos reales desde repositorios.
  ClientStatus _status = ClientStatus.pendiente;
  final _plans = mockPlans();
  String? _newPlan;
  final _payments = [(DateTime(2025, 8, 3), 210000.0, 'Efectivo'), (DateTime(2025, 5, 2), 210000.0, 'Transferencia')];

  @override
  Widget build(BuildContext context) {
    final pending = _status == ClientStatus.pendiente;
    final profile = AppCard(
      child: Column(children: [
        Container(
          width: 88, height: 88,
          decoration: const BoxDecoration(gradient: brandGradient, shape: BoxShape.circle),
          child: const Icon(Icons.person_outline, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 12),
        Text('Estado de cuenta', style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        StatusBadge.forClient(_status),
        const SizedBox(height: 12),
        const InfoRow('Usuario', 'cperez'),
        const InfoRow('Plan', 'Trimestral'),
        InfoRow('Precio', formatCop(210000)),
      ]),
    );

    final subscription = AppCard(
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
              Expanded(child: Text('Tu plan Trimestral está pendiente de pago (${formatCop(210000)}). Acércate a recepción: el administrador registrará tu pago y activará tu membresía.')),
            ]),
          ),
          const SizedBox(height: 20),
          Text('¿Quieres cambiar de plan?', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Nuevo plan', prefixIcon: Icon(Icons.swap_horiz, size: 20)),
            items: [for (final p in _plans) DropdownMenuItem(value: p.nombre, child: Text('${p.nombre} - ${formatCop(p.precio)} / ${p.duracion} meses', overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _newPlan = v),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Actualizar plan',
            icon: Icons.sync,
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            onPressed: _newPlan == null ? null : () => showToast(context, 'Plan actualizado a $_newPlan'),
          ),
          // Solo para revisar la vista: simula que el admin registró el pago.
          TextButton(onPressed: () => setState(() => _status = ClientStatus.activo), child: const Text('Ver como cliente activo (demo)')),
        ] else ...[
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(child: Text('Tu membresía Trimestral está activa.', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          const Text('Válida hasta: 2026-01-28'),
          TextButton(onPressed: () => setState(() => _status = ClientStatus.pendiente), child: const Text('Ver como cliente pendiente (demo)')),
        ],
      ]),
    );

    final history = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Historial de pagos', icon: Icons.history),
        const SizedBox(height: 8),
        if (_payments.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, message: 'Aún no hay pagos registrados.')
        else
          for (final p in _payments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined, size: 18)),
              title: Text(formatCop(p.$2), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${formatDate(p.$1)} · ${p.$3}'),
            ),
      ]),
    );

    return PageBody(title: 'Mi membresía', children: [
      profile, const SizedBox(height: 20), subscription, const SizedBox(height: 20), history,
    ]);
  }
}
