import 'package:flutter/material.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});
  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
  final _key = GlobalKey<FormState>();
  final _mail = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_mail, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    // TODO(auth): UpdateAdminCredentials use case (re-hash de contraseña con bcrypt).
    showToast(context, 'Datos actualizados correctamente');
  }

  @override
  Widget build(BuildContext context) => PageBody(title: 'Cuenta', maxWidth: 600, children: [
        AppCard(
          child: Form(
            key: _key,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('Cambio de información', icon: Icons.manage_accounts_outlined),
              const SizedBox(height: 20),
              AppTextField(label: 'Correo electrónico', hint: 'correo@ejemplo.com', icon: Icons.mail_outline, controller: _mail, keyboardType: TextInputType.emailAddress, validator: Validators.email),
              const SizedBox(height: 14),
              AppTextField(label: 'Nueva contraseña (opcional)', icon: Icons.lock_outline, controller: _pass, obscure: true,
                  validator: (v) => (v == null || v.isEmpty) ? null : Validators.minLength(6)(v)),
              const SizedBox(height: 14),
              AppTextField(label: 'Confirmar contraseña', icon: Icons.lock_outline, controller: _confirm, obscure: true,
                  validator: (v) => _pass.text.isEmpty ? null : Validators.matches(_pass)(v)),
              const SizedBox(height: 24),
              GradientButton(label: 'Actualizar datos', icon: Icons.save_outlined, expanded: true, onPressed: _save),
            ]),
          ),
        ),
      ]);
}
