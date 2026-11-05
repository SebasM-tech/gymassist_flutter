import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';

class ClientAccountPage extends ConsumerWidget {
  const ClientAccountPage({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, String correo, String usuario) async {
    final mail = TextEditingController(text: correo), user = TextEditingController(text: usuario);
    final pass = TextEditingController(), confirm = TextEditingController();
    final ok = await showFormDialog(context, title: 'Editar información', icon: Icons.edit_outlined, fields: [
      AppTextField(label: 'Correo electrónico', icon: Icons.mail_outline, controller: mail, keyboardType: TextInputType.emailAddress, validator: Validators.email),
      AppTextField(label: 'Nombre de usuario', icon: Icons.person_outline, controller: user, validator: Validators.notEmpty),
      AppTextField(label: 'Nueva contraseña (opcional)', icon: Icons.lock_outline, controller: pass, obscure: true,
          validator: (v) => (v == null || v.isEmpty) ? null : Validators.minLength(6)(v)),
      AppTextField(label: 'Confirmar contraseña', icon: Icons.lock_outline, controller: confirm, obscure: true,
          validator: (v) => pass.text.isEmpty ? null : Validators.matches(pass)(v)),
    ]);
    final vals = (mail.text.trim(), user.text.trim(), pass.text);
    for (final c in [mail, user, pass, confirm]) {
      c.dispose();
    }
    if (!ok || !context.mounted) return;
    final done = await runAction(context, () async {
      final token = await ref.read(gymApiProvider).actualizarCuenta(correo: vals.$1, username: vals.$2, password: vals.$3);
      await ref.read(sessionProvider.notifier).replaceToken(token);
    }, ok: 'Datos actualizados correctamente');
    if (done) ref.invalidate(perfilProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider);
    return PageBody(title: 'Cuenta', maxWidth: 600, children: asyncChildren(perfil, onRetry: () => ref.invalidate(perfilProvider), data: (p) {
      final c = p.cliente;
      return [
        AppCard(
          child: Column(children: [
            Container(
              width: 104, height: 104,
              decoration: const BoxDecoration(gradient: brandGradient, shape: BoxShape.circle),
              child: const Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 16),
            Text(c.nombre, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StatusBadge.forClient(c.estado),
            const SizedBox(height: 16),
            InfoRow('Usuario', c.username),
            const Divider(height: 1),
            InfoRow('Correo', c.correo),
            const Divider(height: 1),
            InfoRow('Teléfono', c.telefono),
            const Divider(height: 1),
            InfoRow('Documento', c.documento),
            const Divider(height: 1),
            InfoRow('Plan actual', c.planNombre ?? 'Sin plan'),
            const Divider(height: 1),
            InfoRow('Gimnasio', p.gym?.nombre ?? '-'),
            const SizedBox(height: 20),
            GradientButton(label: 'Editar información', icon: Icons.edit_outlined, expanded: true, onPressed: () => _edit(context, ref, c.correo, c.username)),
          ]),
        ),
      ];
    }));
  }
}
