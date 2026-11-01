import 'package:flutter/material.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

class ClientAccountPage extends StatefulWidget {
  const ClientAccountPage({super.key});
  @override
  State<ClientAccountPage> createState() => _ClientAccountPageState();
}

class _ClientAccountPageState extends State<ClientAccountPage> {
  // TODO(auth): datos reales desde ClientRepository.
  String _correo = 'carlos.perez@mail.com';
  String _usuario = 'cperez';

  Future<void> _edit() async {
    final mail = TextEditingController(text: _correo), user = TextEditingController(text: _usuario);
    final pass = TextEditingController(), confirm = TextEditingController();
    final ok = await showFormDialog(context, title: 'Editar información', icon: Icons.edit_outlined, fields: [
      AppTextField(label: 'Correo electrónico', icon: Icons.mail_outline, controller: mail, keyboardType: TextInputType.emailAddress, validator: Validators.email),
      AppTextField(label: 'Nombre de usuario', icon: Icons.person_outline, controller: user, validator: Validators.notEmpty),
      AppTextField(label: 'Nueva contraseña (opcional)', icon: Icons.lock_outline, controller: pass, obscure: true,
          validator: (v) => (v == null || v.isEmpty) ? null : Validators.minLength(6)(v)),
      AppTextField(label: 'Confirmar contraseña', icon: Icons.lock_outline, controller: confirm, obscure: true,
          validator: (v) => pass.text.isEmpty ? null : Validators.matches(pass)(v)),
    ]);
    final vals = (mail.text.trim(), user.text.trim());
    for (final c in [mail, user, pass, confirm]) {
      c.dispose();
    }
    if (!ok || !mounted) return;
    setState(() {
      _correo = vals.$1;
      _usuario = vals.$2;
    });
    showToast(context, 'Datos actualizados correctamente');
  }

  @override
  Widget build(BuildContext context) => PageBody(title: 'Cuenta', maxWidth: 600, children: [
        AppCard(
          child: Column(children: [
            Container(
              width: 104, height: 104,
              decoration: const BoxDecoration(gradient: brandGradient, shape: BoxShape.circle),
              child: const Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 16),
            Text('Estado de cuenta', style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StatusBadge.forClient(ClientStatus.activo),
            const SizedBox(height: 16),
            InfoRow('Usuario', _usuario),
            const Divider(height: 1),
            InfoRow('Correo', _correo),
            const Divider(height: 1),
            const InfoRow('Teléfono', '3109876543'),
            const Divider(height: 1),
            const InfoRow('Plan actual', 'Trimestral'),
            const SizedBox(height: 20),
            GradientButton(label: 'Editar información', icon: Icons.edit_outlined, expanded: true, onPressed: _edit),
          ]),
        ),
      ]);
}
