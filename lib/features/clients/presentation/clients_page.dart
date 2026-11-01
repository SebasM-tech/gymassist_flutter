import 'package:flutter/material.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});
  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  // TODO(clients): reemplazar por ClientsViewModel (Riverpod) + ClientRepository.
  final _clients = mockClients();
  final _plans = mockPlans();

  Future<void> _add() async {
    final nombre = TextEditingController(), correo = TextEditingController(), doc = TextEditingController();
    final tel = TextEditingController(), user = TextEditingController(), pass = TextEditingController();
    String? plan;
    final ok = await showFormDialog(
      context,
      title: 'Agregar cliente',
      icon: Icons.person_add_alt_1,
      submitLabel: 'Agregar cliente',
      fields: [
        AppTextField(label: 'Nombre completo', icon: Icons.person_outline, controller: nombre, validator: Validators.notEmpty),
        AppTextField(label: 'Correo electrónico', icon: Icons.mail_outline, controller: correo, keyboardType: TextInputType.emailAddress, validator: Validators.email),
        AppTextField(label: 'Número de documento', icon: Icons.badge_outlined, controller: doc, keyboardType: TextInputType.number, validator: Validators.notEmpty),
        AppTextField(label: 'Número telefónico', icon: Icons.phone_outlined, controller: tel, keyboardType: TextInputType.phone, validator: Validators.notEmpty),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de plan', prefixIcon: Icon(Icons.card_membership_outlined, size: 20)),
          items: [
            for (final p in _plans)
              DropdownMenuItem(value: p.nombre, child: Text('${p.nombre} - ${formatCop(p.precio)} / ${p.duracion} meses', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => plan = v,
          validator: (v) => v == null ? 'Selecciona un plan' : null,
        ),
        AppTextField(label: 'Nombre de usuario', icon: Icons.alternate_email, controller: user, validator: Validators.notEmpty),
        AppTextField(label: 'Contraseña', icon: Icons.lock_outline, controller: pass, obscure: true, validator: Validators.minLength(6)),
      ],
    );
    final c = (nombre.text, correo.text, doc.text, tel.text, user.text);
    for (final x in [nombre, correo, doc, tel, user, pass]) {
      x.dispose();
    }
    if (!ok || !mounted) return;
    // TODO(clients): CreateClient use case (valida email/username únicos, calcula fechas de membresía).
    setState(() => _clients.add(MockClient(
        nombre: c.$1, correo: c.$2, documento: c.$3, telefono: c.$4, plan: plan!, username: c.$5, estado: ClientStatus.pendiente)));
    showToast(context, 'Cliente agregado');
  }

  void _set(MockClient c, ClientStatus s, String msg) {
    setState(() => c.estado = s);
    showToast(context, msg);
  }

  List<Widget> _actions(MockClient c) => [
        if (c.estado == ClientStatus.pendiente)
          SmallActionButton('Registrar pago', Icons.payments_outlined, AppColors.success, () => _set(c, ClientStatus.activo, 'Pago registrado')),
        if (c.estado == ClientStatus.activo)
          SmallActionButton('Detener', Icons.pause_circle_outline, AppColors.warning, () => _set(c, ClientStatus.pendiente, 'Membresía detenida')),
        if (c.estado != ClientStatus.suspendido)
          SmallActionButton('Suspender', Icons.block, AppColors.danger, () async {
            final ok = await showConfirm(context, title: 'Suspender cliente', message: '¿Suspender a ${c.nombre}?', confirmLabel: 'Suspender', danger: true);
            if (ok && mounted) _set(c, ClientStatus.suspendido, 'Cliente suspendido');
          }),
        if (c.estado == ClientStatus.suspendido)
          SmallActionButton('Activar', Icons.check_circle_outline, AppColors.info, () => _set(c, ClientStatus.activo, 'Cliente activado')),
      ];

  @override
  Widget build(BuildContext context) {
    int count(ClientStatus s) => _clients.where((c) => c.estado == s).length;
    return PageBody(
      title: 'Clientes',
      trailing: GradientButton(label: 'Agregar', icon: Icons.add, onPressed: _add),
      children: [
        AdaptiveGrid(minItemWidth: 150, children: [
          StatCard(icon: Icons.how_to_reg_outlined, label: 'Usuarios activos', value: '${count(ClientStatus.activo)}', color: AppColors.success, caption: 'Con membresía vigente'),
          StatCard(icon: Icons.person_off_outlined, label: 'Usuarios suspendidos', value: '${count(ClientStatus.suspendido)}', color: AppColors.danger, caption: 'Sin acceso al gimnasio'),
          StatCard(icon: Icons.groups_outlined, label: 'Usuarios totales', value: '${_clients.length}', caption: 'Todos los registrados'),
        ]),
        const SizedBox(height: 24),
        CardList(children: [
          for (final c in _clients)
            ListCard(
              title: c.nombre,
              badge: StatusBadge.forClient(c.estado),
              lines: [
                (Icons.mail_outline, c.correo),
                (Icons.phone_outlined, c.telefono),
                (Icons.badge_outlined, 'Documento ${c.documento}'),
                (Icons.card_membership_outlined, 'Plan ${c.plan} · @${c.username}'),
              ],
              actions: _actions(c),
            ),
        ]),
      ],
    );
  }
}
