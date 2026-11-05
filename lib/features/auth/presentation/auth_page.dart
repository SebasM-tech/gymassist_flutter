import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _loginKey = GlobalKey<FormState>();
  final _regKey = GlobalKey<FormState>();
  final _lUser = TextEditingController();
  final _lPass = TextEditingController();
  final _rUser = TextEditingController();
  final _rMail = TextEditingController();
  final _rPass = TextEditingController();
  final _rConfirm = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_lUser, _lPass, _rUser, _rMail, _rPass, _rConfirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      final s = await ref.read(sessionProvider.notifier).login(_lUser.text, _lPass.text);
      if (mounted) context.go(homeFor(s));
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doRegister() async {
    if (!_regKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      final s = await ref.read(sessionProvider.notifier).registerAdmin(username: _rUser.text, email: _rMail.text, password: _rPass.text);
      if (mounted) {
        showToast(context, 'Cuenta creada. Ahora registra tu gimnasio.');
        context.go(homeFor(s));
      }
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: authGradient),
        child: SafeArea(
          child: Stack(children: [
            Positioned(
              left: 8, top: 8,
              child: IconButton.filledTonal(tooltip: 'Volver al inicio', onPressed: () => context.go('/'), icon: const Icon(Icons.arrow_back)),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AppCard(
                    padding: const EdgeInsets.all(32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _register ? _registerForm(context) : _loginForm(context),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title, String subtitle) => Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.fitness_center, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
        const SizedBox(height: 24),
      ]);

  Widget _loginForm(BuildContext context) => Form(
        key: _loginKey,
        child: Column(key: const ValueKey('login'), mainAxisSize: MainAxisSize.min, children: [
          _header(context, 'Iniciar sesión', 'Ingresa con tu usuario y contraseña'),
          AppTextField(label: 'Usuario', icon: Icons.person_outline, controller: _lUser, validator: Validators.notEmpty),
          const SizedBox(height: 14),
          AppTextField(label: 'Contraseña', icon: Icons.lock_outline, controller: _lPass, obscure: true, validator: Validators.notEmpty),
          const SizedBox(height: 22),
          GradientButton(label: _busy ? 'Ingresando…' : 'Iniciar sesión', icon: Icons.login, expanded: true, onPressed: _busy ? null : _login),
          const SizedBox(height: 8),
          TextButton(onPressed: () => setState(() => _register = true), child: const Text('¿Aún no tienes cuenta? Regístrate')),
        ]),
      );

  Widget _registerForm(BuildContext context) => Form(
        key: _regKey,
        child: Column(key: const ValueKey('register'), mainAxisSize: MainAxisSize.min, children: [
          _header(context, 'Crear cuenta', 'Regístrate como administrador de tu gimnasio'),
          AppTextField(label: 'Usuario', icon: Icons.person_outline, controller: _rUser, validator: Validators.notEmpty),
          const SizedBox(height: 14),
          AppTextField(label: 'Correo electrónico', icon: Icons.mail_outline, controller: _rMail, keyboardType: TextInputType.emailAddress, validator: Validators.email),
          const SizedBox(height: 14),
          AppTextField(label: 'Contraseña', icon: Icons.lock_outline, controller: _rPass, obscure: true, validator: Validators.minLength(6)),
          const SizedBox(height: 14),
          AppTextField(label: 'Confirmar contraseña', icon: Icons.lock_outline, controller: _rConfirm, obscure: true, validator: Validators.matches(_rPass)),
          const SizedBox(height: 22),
          GradientButton(label: _busy ? 'Creando…' : 'Crear cuenta', icon: Icons.person_add_alt_1, expanded: true, onPressed: _busy ? null : _doRegister),
          const SizedBox(height: 8),
          TextButton(onPressed: () => setState(() => _register = false), child: const Text('¿Ya tienes cuenta? Inicia sesión')),
        ]),
      );
}
