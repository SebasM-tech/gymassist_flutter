import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';

class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});
  @override
  ConsumerState<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends ConsumerState<PlansPage> {
  final _key = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _duracion = TextEditingController();
  final _desc = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_nombre, _precio, _duracion, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reload() {
    ref.invalidate(adminPlanesProvider);
    ref.invalidate(adminResumenProvider);
  }

  static String _num(String v) => Validators.parse(v)!.round().toString();

  Future<void> _create() async {
    if (!_key.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(gymApiProvider).guardarPlan(
            nombre: _nombre.text.trim(),
            descripcion: _desc.text.trim(),
            precio: _num(_precio.text),
            duracionMeses: _num(_duracion.text),
          ),
      ok: 'Plan registrado',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _key.currentState!.reset();
      for (final c in [_nombre, _precio, _duracion, _desc]) {
        c.clear();
      }
      _reload();
    }
  }

  Future<void> _edit(Plan p) async {
    final n = TextEditingController(text: p.nombre), d = TextEditingController(text: p.descripcion);
    final pr = TextEditingController(text: p.precio.toStringAsFixed(0)), du = TextEditingController(text: '${p.duracionMeses}');
    final ok = await showFormDialog(context, title: 'Editar plan', icon: Icons.edit_outlined, fields: [
      AppTextField(label: 'Nombre del plan', icon: Icons.sell_outlined, controller: n, validator: Validators.notEmpty),
      AppTextField(label: 'Descripción', icon: Icons.notes, controller: d, validator: Validators.notEmpty),
      AppTextField(label: 'Precio', icon: Icons.attach_money, controller: pr, keyboardType: TextInputType.number, validator: Validators.positive),
      AppTextField(label: 'Duración (meses)', icon: Icons.schedule, controller: du, keyboardType: TextInputType.number, validator: Validators.positive),
    ]);
    final vals = (n.text.trim(), d.text.trim(), pr.text, du.text);
    for (final c in [n, d, pr, du]) {
      c.dispose();
    }
    if (!ok || !mounted) return;
    final done = await runAction(
      context,
      () => ref.read(gymApiProvider).guardarPlan(id: p.id, nombre: vals.$1, descripcion: vals.$2, precio: _num(vals.$3), duracionMeses: _num(vals.$4)),
      ok: 'Plan actualizado',
    );
    if (done) _reload();
  }

  Future<void> _delete(Plan p) async {
    final ok = await showConfirm(context,
        title: '¿Eliminar plan?',
        message: 'Los ${p.suscriptores} clientes con "${p.nombre}" quedarán sin plan.',
        confirmLabel: 'Sí, eliminar',
        danger: true);
    if (!ok || !mounted) return;
    if (await runAction(context, () => ref.read(gymApiProvider).borrarPlan(p.id), ok: 'Plan eliminado')) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final planes = ref.watch(adminPlanesProvider);
    return PageBody(title: 'Membresías', children: [
      AppCard(
        child: Form(
          key: _key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('Registro de membresías del gimnasio', icon: Icons.add_card_outlined),
            const SizedBox(height: 20),
            AdaptiveGrid(minItemWidth: 240, children: [
              AppTextField(label: 'Nombre del plan', icon: Icons.sell_outlined, controller: _nombre, validator: Validators.notEmpty),
              AppTextField(label: 'Precio', icon: Icons.attach_money, controller: _precio, keyboardType: TextInputType.number, validator: Validators.positive),
              AppTextField(label: 'Duración (meses)', icon: Icons.schedule, controller: _duracion, keyboardType: TextInputType.number, validator: Validators.positive),
            ]),
            const SizedBox(height: 16),
            AppTextField(label: 'Descripción', icon: Icons.notes, controller: _desc, maxLines: 3, validator: Validators.notEmpty),
            const SizedBox(height: 20),
            GradientButton(label: _busy ? 'Guardando…' : 'Registrar plan', icon: Icons.add, onPressed: _busy ? null : _create),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      ...asyncChildren(planes, onRetry: _reload, data: (list) => [
            if (list.isEmpty)
              const AppCard(child: EmptyState(icon: Icons.card_membership_outlined, message: 'Aún no hay planes. Registra el primero arriba.'))
            else
              CardList(children: [
                for (final p in list)
                  ListCard(
                    title: p.nombre,
                    badge: StatusBadge(formatCop(p.precio), AppColors.accent),
                    lines: [
                      (Icons.notes, p.descripcion),
                      (Icons.schedule, '${p.duracionMeses} ${p.duracionMeses == 1 ? 'mes' : 'meses'}'),
                      (Icons.people_outline, '${p.suscriptores} suscriptores'),
                    ],
                    actions: [
                      SmallActionButton('Editar', Icons.edit_outlined, AppColors.accent, () => _edit(p)),
                      SmallActionButton('Eliminar', Icons.delete_outline, AppColors.danger, () => _delete(p)),
                    ],
                  ),
              ]),
          ]),
    ]);
  }
}
