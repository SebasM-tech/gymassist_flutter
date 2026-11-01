import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

String formatCop(num v) =>
    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0).format(v);
String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Contenedor de página: título + contenido con scroll y ancho máximo.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.title, required this.children, this.maxWidth = 640, this.trailing});
  final String title;
  final List<Widget> children;
  final double maxWidth;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: context.tt.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 24),
            ...children,
          ]),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? .35 : .05),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// Tarjeta con franja de color a la izquierda (estado / riesgo).
class StripeCard extends StatelessWidget {
  const StripeCard({super.key, required this.color, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 16});
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.border),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: color),
          Expanded(child: Padding(padding: padding, child: child)),
        ]),
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        if (icon != null) ...[Icon(icon, color: AppColors.accent), const SizedBox(width: 10)],
        Flexible(child: Text(text, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
      ]);
}

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, this.icon, this.onPressed, this.expanded = false, this.gradient = brandGradient});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final btn = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : Colors.grey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(.3), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class SmallActionButton extends StatelessWidget {
  const SmallActionButton(this.label, this.icon, this.color, this.onPressed, {super.key});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.color = AppColors.accent, this.caption});
  final IconData icon;
  final String label, value;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(label, style: context.tt.bodySmall?.copyWith(color: context.muted, fontWeight: FontWeight.w600)),
          if (caption != null) Text(caption!, style: context.tt.bodySmall?.copyWith(color: context.muted)),
        ]),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, this.color, {super.key});
  final String label;
  final Color color;

  factory StatusBadge.forClient(ClientStatus s) => switch (s) {
        ClientStatus.activo => const StatusBadge('Activo', AppColors.success),
        ClientStatus.pendiente => const StatusBadge('Pendiente', AppColors.warning),
        ClientStatus.suspendido => const StatusBadge('Suspendido', AppColors.danger),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.label, this.icon, this.controller, this.obscure = false, this.keyboardType, this.validator, this.maxLines = 1, this.hint, this.readOnly = false, this.onChanged});
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscure, readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: obscure ? 1 : maxLines,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon, size: 20),
        ),
      );
}

/// Formulario en hoja inferior (patrón móvil). Devuelve true si se guardó y las validaciones pasaron.
Future<bool> showFormDialog(BuildContext context,
    {required String title, required IconData icon, required List<Widget> fields, String submitLabel = 'Guardar cambios'}) async {
  final key = GlobalKey<FormState>();
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: ctx.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 16),
            for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 14), child: f),
            const SizedBox(height: 8),
            GradientButton(
              label: submitLabel,
              icon: Icons.save_outlined,
              expanded: true,
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(ctx, true);
              },
            ),
            SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar'))),
          ]),
        ),
      ),
    ),
  );
  return r ?? false;
}

Future<bool> showConfirm(BuildContext context,
    {required String title, required String message, String confirmLabel = 'Confirmar', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

void showToast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.danger : null,
    ));
}

/// Tarjeta de lista móvil: título, insignia, líneas de detalle y acciones.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.title, this.badge, this.lines = const [], this.actions = const []});
  final String title;
  final Widget? badge;
  final List<(IconData, String)> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            if (badge != null) badge!,
          ]),
          if (lines.isNotEmpty) const SizedBox(height: 8),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(l.$1, size: 16, color: context.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(l.$2, style: context.tt.bodyMedium?.copyWith(color: context.muted))),
              ]),
            ),
          if (actions.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: actions)],
        ]),
      );
}

class CardList extends StatelessWidget {
  const CardList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < children.length; i++) ...[children[i], if (i < children.length - 1) const SizedBox(height: 12)],
      ]);
}

/// Cuadrícula que ajusta el número de columnas al ancho disponible.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({super.key, required this.children, this.minItemWidth = 260, this.spacing = 16});
  final List<Widget> children;
  final double minItemWidth, spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, cons) {
        final cols = math.max(1, ((cons.maxWidth + spacing) / (minItemWidth + spacing)).floor());
        final w = (cons.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [
          for (final c in children) SizedBox(width: w, child: c),
        ]);
      });
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: context.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: context.tt.bodyLarge?.copyWith(color: context.muted)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

/// Mancuerna animada de las pantallas de bienvenida (respeta "reducir movimiento").
class LiftingDumbbell extends StatefulWidget {
  const LiftingDumbbell({super.key, this.size = 110});
  final double size;
  @override
  State<LiftingDumbbell> createState() => _LiftingDumbbellState();
}

class _LiftingDumbbellState extends State<LiftingDumbbell> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.fitness_center, size: widget.size, color: AppColors.accent);
    if (MediaQuery.disableAnimationsOf(context)) return icon;
    return SizedBox(
      height: widget.size + 50,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final v = _c.value < .5 ? _c.value * 2 : (1 - _c.value) * 2;
          final t = Curves.easeInOut.transform(v);
          return Transform.translate(
            offset: Offset(0, 40 - 40 * t),
            child: Transform.rotate(angle: .3 * t, child: child),
          );
        },
        child: icon,
      ),
    );
  }
}

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.name, required this.subtitle});
  final String name, subtitle;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('Bienvenido,', style: context.tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accent)),
          Text(name, textAlign: TextAlign.center, style: context.tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: context.tt.titleMedium?.copyWith(color: context.muted)),
          const SizedBox(height: 24),
          const LiftingDumbbell(),
        ]),
      );
}
