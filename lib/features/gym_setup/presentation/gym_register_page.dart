import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

/// Se muestra una sola vez: el admin sin gimnasio es redirigido aquí tras iniciar sesión.
class GymRegisterPage extends ConsumerStatefulWidget {
  const GymRegisterPage({super.key});
  @override
  ConsumerState<GymRegisterPage> createState() => _GymRegisterPageState();
}

class _GymRegisterPageState extends ConsumerState<GymRegisterPage> {
  bool _busy = false;
  final _key = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _nit = TextEditingController();
  final _direccion = TextEditingController();
  final _descripcion = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nombre, _nit, _direccion, _descripcion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(gymApiProvider).registrarGimnasio(
            nombre: _nombre.text.trim(),
            nit: _nit.text.trim(),
            direccion: _direccion.text.trim(),
            descripcion: _descripcion.text.trim(),
          );
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) {
        showToast(context, 'Gimnasio registrado');
        context.go('/admin');
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: AppCard(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _key,
                    child: Column(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.fitness_center, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text('Bienvenido a GymAssist', style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Antes de comenzar, cuéntanos sobre tu gimnasio', style: TextStyle(color: context.muted)),
                      const SizedBox(height: 24),
                      AppTextField(label: 'Nombre del gimnasio', hint: 'Ej: FitLife Gym', icon: Icons.fitness_center, controller: _nombre, validator: Validators.notEmpty),
                      const SizedBox(height: 14),
                      AppTextField(label: 'NIT', icon: Icons.badge_outlined, controller: _nit, keyboardType: TextInputType.number, validator: Validators.positive),
                      const SizedBox(height: 14),
                      AppTextField(label: 'Dirección', hint: 'Ej: Calle 123 #45-67', icon: Icons.place_outlined, controller: _direccion, validator: Validators.notEmpty),
                      const SizedBox(height: 14),
                      AppTextField(label: 'Descripción', hint: 'Servicios, horarios…', icon: Icons.notes, controller: _descripcion, maxLines: 4, validator: Validators.notEmpty),
                      const SizedBox(height: 24),
                      GradientButton(label: _busy ? 'Registrando…' : 'Registrar gimnasio', icon: Icons.check_circle_outline, expanded: true, onPressed: _busy ? null : _submit),
                      TextButton(onPressed: () => ref.read(sessionProvider.notifier).logout(), child: const Text('Cerrar sesión')),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
