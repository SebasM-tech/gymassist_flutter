import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/widgets/common.dart';

class AdminAccountPage extends ConsumerStatefulWidget {
  const AdminAccountPage({super.key});
  @override
  ConsumerState<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends ConsumerState<AdminAccountPage> {
  final _key = GlobalKey<FormState>();
  late final _mail = TextEditingController(text: ref.read(sessionProvider).valueOrNull?.email);
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_mail, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    final ok = await runAction(context, () => ref.read(gymApiProvider).actualizarCuentaAdmin(correo: _mail.text.trim(), password: _pass.text),
        ok: 'Datos actualizados correctamente');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _pass.clear();
      _confirm.clear();
      ref.read(sessionProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider).valueOrNull;
    return PageBody(title: 'Cuenta', maxWidth: 600, children: [
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('Mi gimnasio', icon: Icons.storefront_outlined),
          const SizedBox(height: 12),
          InfoRow('Usuario', '@${s?.username ?? ''}'),
          InfoRow('Gimnasio', s?.gym?.nombre ?? '-'),
          InfoRow('NIT', '${s?.gym?.nit ?? '-'}'),
          InfoRow('Dirección', s?.gym?.direccion ?? '-'),
        ]),
      ),
      const SizedBox(height: 16),
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
            GradientButton(label: _busy ? 'Guardando…' : 'Actualizar datos', icon: Icons.save_outlined, expanded: true, onPressed: _busy ? null : _save),
          ]),
        ),
      ),
    ]);
  }
}
