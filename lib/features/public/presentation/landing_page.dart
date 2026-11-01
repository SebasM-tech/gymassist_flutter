import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hero = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Construye tu cuerpo y', style: context.tt.headlineMedium),
        Text('¡sé tu mejor versión!',
            style: context.tt.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accent, height: 1.1)),
        const SizedBox(height: 16),
        Text(
          'Libera tu potencial y emprende un viaje hacia una versión más fuerte, en forma y segura de ti. '
          'Gestiona tu membresía, tus rutinas y tu progreso en un solo lugar, incluso sin conexión.',
          style: context.tt.titleMedium?.copyWith(color: context.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        GradientButton(label: 'Iniciar sesión', icon: Icons.login, onPressed: () => context.go('/login')),
      ],
    );
    final art = Container(
      height: 280,
      decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(32)),
      child: const Center(child: Icon(Icons.fitness_center, size: 140, color: Colors.white)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.fitness_center, color: AppColors.accent), SizedBox(width: 8), Text('GymAssist', style: TextStyle(fontWeight: FontWeight.w800))]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [hero, const SizedBox(height: 32), art]),
                const SizedBox(height: 64),
                Text('Conócenos', style: context.tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Un equipo de instructores expertos y motivadores que combina cardio, fuerza y ejercicio funcional.',
                    style: context.tt.bodyLarge?.copyWith(color: context.muted)),
                const SizedBox(height: 24),
                const AdaptiveGrid(minItemWidth: 300, spacing: 20, children: [
                  _Feature(Icons.door_front_door_outlined, 'Política de puertas abiertas', 'Acceso para todas las personas, sin importar su nivel físico, edad o antecedentes.'),
                  _Feature(Icons.verified_user_outlined, 'Totalmente asegurado', 'Tu tranquilidad es nuestra prioridad en cada parte de tu proceso.'),
                  _Feature(Icons.sports_gymnastics, 'Entrenador personal', 'Planes de entrenamiento adaptados a tus necesidades.'),
                ]),
                const SizedBox(height: 48),
                const AdaptiveGrid(minItemWidth: 300, spacing: 20, children: [
                  _InfoCard(Icons.flag_outlined, 'Sobre nosotros', 'Nuestra misión, visión y los valores que nos impulsan a ayudarte a alcanzar tus metas.'),
                  _InfoCard(Icons.groups_outlined, 'Nuestro equipo', 'Entrenadores y profesionales comprometidos con tu bienestar y rendimiento.'),
                  _InfoCard(Icons.tune, 'Servicios y planes', 'Clases, rutinas y seguimiento para transformar tu estilo de vida.'),
                ]),
                const SizedBox(height: 48),
                Center(child: Text('Copyright © 2025 GymAssist. Todos los derechos reservados.', style: context.tt.bodySmall?.copyWith(color: context.muted))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.text);
  final IconData icon;
  final String title, text;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accent, width: 2)),
          child: Icon(icon, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(color: context.muted)),
          ]),
        ),
      ]);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.icon, this.title, this.text);
  final IconData icon;
  final String title, text;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          CircleAvatar(radius: 32, backgroundColor: AppColors.accent.withOpacity(.12), child: Icon(icon, color: AppColors.accent, size: 30)),
          const SizedBox(height: 16),
          Text(title, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
        ]),
      );
}
