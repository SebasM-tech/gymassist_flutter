import 'package:flutter/material.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});
  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final _plans = mockPlans(); // TODO(plans): PlansViewModel + PlanRepository
  final _key = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _duracion = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nombre, _precio, _duracion, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  void _create() {
    if (!_key.currentState!.validate()) return;
    setState(() => _plans.add(MockPlan(_nombre.text.trim(), _desc.text.trim(), Validators.parse(_precio.text)!, int.parse(_duracion.text), 0)));
    _key.currentState!.reset();
    for (final c in [_nombre, _precio, _duracion, _desc]) {
      c.clear();
    }
    showToast(context, 'Plan registrado');
  }

  Future<void> _edit(MockPlan p) async {
    final n = TextEditingController(text: p.nombre), d = TextEditingController(text: p.descripcion);
    final pr = TextEditingController(text: p.precio.toStringAsFixed(0)), du = TextEditingController(text: '${p.duracion}');
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
    setState(() {
      p.nombre = vals.$1;
      p.descripcion = vals.$2;
      p.precio = Validators.parse(vals.$3)!;
      p.duracion = double.parse(vals.$4).round();
    });
    showToast(context, 'Plan actualizado');
  }

  Future<void> _delete(MockPlan p) async {
    final ok = await showConfirm(context,
        title: '¿Eliminar plan?',
        message: 'Los ${p.suscriptores} clientes con "${p.nombre}" quedarán sin plan.',
        confirmLabel: 'Sí, eliminar',
        danger: true);
    if (ok && mounted) {
      setState(() => _plans.remove(p));
      showToast(context, 'Plan eliminado');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            GradientButton(label: 'Registrar plan', icon: Icons.add, onPressed: _create),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      if (_plans.isEmpty)
        const AppCard(child: EmptyState(icon: Icons.card_membership_outlined, message: 'Aún no hay planes. Registra el primero arriba.'))
      else
        CardList(children: [
          for (final p in _plans)
            ListCard(
              title: p.nombre,
              badge: StatusBadge(formatCop(p.precio), AppColors.accent),
              lines: [
                (Icons.notes, p.descripcion),
                (Icons.schedule, '${p.duracion} ${p.duracion == 1 ? 'mes' : 'meses'}'),
                (Icons.people_outline, '${p.suscriptores} suscriptores'),
              ],
              actions: [
                SmallActionButton('Editar', Icons.edit_outlined, AppColors.accent, () => _edit(p)),
                SmallActionButton('Eliminar', Icons.delete_outline, AppColors.danger, () => _delete(p)),
              ],
            ),
        ]),
    ]);
  }
}
