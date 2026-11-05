import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});
  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  String _query = '';
  ClientStatus? _filtro;

  void _reload() {
    ref.invalidate(adminClientesProvider);
    ref.invalidate(adminResumenProvider);
  }

  Future<void> _add() async {
    List<Plan> planes;
    try {
      planes = await ref.read(gymApiProvider).planesAdmin();
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
      return;
    }
    if (!mounted) return;
    if (planes.isEmpty) {
      showToast(context, 'Primero crea un plan en "Planes".', error: true);
      return;
    }
    final nombre = TextEditingController(), correo = TextEditingController(), doc = TextEditingController();
    final tel = TextEditingController(), user = TextEditingController(), pass = TextEditingController();
    String? planId;
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
          decoration: const InputDecoration(labelText: 'Plan', prefixIcon: Icon(Icons.card_membership_outlined, size: 20)),
          items: [
            for (final p in planes)
              DropdownMenuItem(value: p.id, child: Text('${p.nombre} - ${formatCop(p.precio)} / ${p.duracionMeses} meses', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => planId = v,
          validator: (v) => v == null ? 'Selecciona un plan' : null,
        ),
        AppTextField(label: 'Nombre de usuario', icon: Icons.alternate_email, controller: user, validator: Validators.notEmpty),
        AppTextField(label: 'Contraseña', icon: Icons.lock_outline, controller: pass, obscure: true, validator: Validators.minLength(6)),
      ],
    );
    final v = (nombre.text.trim(), correo.text.trim(), doc.text.trim(), tel.text.trim(), user.text.trim(), pass.text);
    for (final x in [nombre, correo, doc, tel, user, pass]) {
      x.dispose();
    }
    if (!ok || !mounted || planId == null) return;
    final done = await runAction(
      context,
      () => ref.read(gymApiProvider).crearCliente(
            nombre: v.$1, correo: v.$2, documento: v.$3, telefono: v.$4, planId: planId!, username: v.$5, password: v.$6),
      ok: 'Cliente agregado (queda pendiente de pago)',
    );
    if (done) _reload();
  }

  Future<void> _estado(Cliente c, String estado, String msg) async {
    if (await runAction(context, () => ref.read(gymApiProvider).cambiarEstado(c.id, estado), ok: msg)) _reload();
  }

  Future<void> _pago(Cliente c) async {
    final ok = await showConfirm(context,
        title: 'Registrar pago',
        message: '¿${c.nombre} pagó ${c.planPrecio == null ? 'su plan' : formatCop(c.planPrecio!)} en efectivo o transferencia? '
            'Su membresía quedará activa por ${c.planDuracionMeses ?? 1} ${c.planDuracionMeses == 1 ? 'mes' : 'meses'}.',
        confirmLabel: 'Sí, registrar');
    if (!ok || !mounted) return;
    if (await runAction(context, () => ref.read(gymApiProvider).pagoManual(c.id), ok: 'Pago registrado, membresía activa')) _reload();
  }

  List<Widget> _actions(Cliente c) => [
        if (c.estado != ClientStatus.activo)
          SmallActionButton('Registrar pago', Icons.payments_outlined, AppColors.success, () => _pago(c)),
        if (c.estado == ClientStatus.activo)
          SmallActionButton('Renovar', Icons.autorenew, AppColors.success, () => _pago(c)),
        if (c.estado == ClientStatus.activo)
          SmallActionButton('Detener', Icons.pause_circle_outline, AppColors.warning, () => _estado(c, 'PENDIENTE', 'Membresía detenida')),
        if (c.estado != ClientStatus.suspendido)
          SmallActionButton('Suspender', Icons.block, AppColors.danger, () async {
            final ok = await showConfirm(context, title: 'Suspender cliente', message: '¿Suspender a ${c.nombre}?', confirmLabel: 'Suspender', danger: true);
            if (ok && mounted) _estado(c, 'SUSPENDIDO', 'Cliente suspendido');
          }),
        if (c.estado == ClientStatus.suspendido)
          SmallActionButton('Reactivar', Icons.check_circle_outline, AppColors.info, () => _estado(c, 'ACTIVO', 'Cliente activado')),
      ];

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(adminClientesProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminClientesProvider.future),
      child: PageBody(
        title: 'Clientes',
        trailing: GradientButton(label: 'Agregar', icon: Icons.add, onPressed: _add),
        children: asyncChildren(clientes, onRetry: _reload, data: (all) {
          int count(ClientStatus s) => all.where((c) => c.estado == s).length;
          final q = _query.toLowerCase();
          final list = all
              .where((c) => _filtro == null || c.estado == _filtro)
              .where((c) => q.isEmpty || c.nombre.toLowerCase().contains(q) || c.username.toLowerCase().contains(q) || c.documento.contains(q))
              .toList()
            ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
          return [
            AdaptiveGrid(minItemWidth: 150, children: [
              StatCard(icon: Icons.how_to_reg_outlined, label: 'Activos', value: '${count(ClientStatus.activo)}', color: AppColors.success, caption: 'Con membresía vigente'),
              StatCard(icon: Icons.hourglass_bottom, label: 'Pendientes', value: '${count(ClientStatus.pendiente)}', color: AppColors.warning, caption: 'Sin pago'),
              StatCard(icon: Icons.person_off_outlined, label: 'Suspendidos', value: '${count(ClientStatus.suspendido)}', color: AppColors.danger, caption: 'Sin acceso'),
              StatCard(icon: Icons.groups_outlined, label: 'Totales', value: '${all.length}', caption: 'Todos los registrados'),
            ]),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre, usuario o documento'),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Todos'), selected: _filtro == null, onSelected: (_) => setState(() => _filtro = null)),
              for (final s in ClientStatus.values)
                ChoiceChip(label: Text(s.name[0].toUpperCase() + s.name.substring(1)), selected: _filtro == s, onSelected: (_) => setState(() => _filtro = s)),
            ]),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(icon: Icons.person_search_outlined, message: 'No hay clientes con ese filtro.'))
            else
              CardList(children: [
                for (final c in list)
                  ListCard(
                    title: c.nombre,
                    badge: StatusBadge.forClient(c.estado),
                    lines: [
                      (Icons.mail_outline, c.correo),
                      (Icons.phone_outlined, c.telefono),
                      (Icons.badge_outlined, 'Documento ${c.documento}'),
                      (Icons.card_membership_outlined, 'Plan ${c.planNombre ?? '-'} · @${c.username}'),
                      if (c.fechaFinMembresia != null) (Icons.event_outlined, 'Vence: ${formatDate(c.fechaFinMembresia!)}'),
                      (Icons.event_available_outlined, '${c.totalAsistencias} asistencias · ${c.inasistencias} inasistencias'),
                    ],
                    actions: _actions(c),
                  ),
              ]),
          ];
        }),
      ),
    );
  }
}
