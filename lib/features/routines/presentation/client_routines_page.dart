import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/api/data_providers.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/widgets/async_view.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

const _descriptions = {
  'Pecho': 'Grupo muscular del torso que se entrena para ganar fuerza y volumen.',
  'Espalda': 'Grupo muscular del torso que se entrena para ganar fuerza y amplitud.',
  'Cuádriceps': 'Músculo del muslo que se entrena para ganar fuerza y potencia en las piernas.',
  'Femoral': 'Músculo posterior del muslo que da fuerza y estabilidad a las piernas.',
  'Glúteos': 'Grupo muscular del torso inferior que se entrena para ganar volumen y tonificación.',
  'Bíceps': 'Músculo del brazo que se entrena para ganar fuerza y volumen.',
  'Tríceps': 'Músculo del brazo que se entrena para ganar fuerza y definición.',
  'Hombros': 'Grupo muscular que da fuerza y movilidad a la parte superior del cuerpo.',
};

const _palettes = [
  [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
  [Color(0xFFB45309), Color(0xFFF59E0B)],
];

class ClientRoutinesPage extends StatelessWidget {
  const ClientRoutinesPage({super.key});

  @override
  Widget build(BuildContext context) => PageBody(title: 'Rutinas', children: [
        Text('Toca o pasa el cursor sobre un grupo muscular para ver más.', style: TextStyle(color: context.muted)),
        const SizedBox(height: 20),
        AdaptiveGrid(minItemWidth: 230, children: [
          for (var i = 0; i < gruposMusculares.length; i++)
            _FlipCard(
              group: gruposMusculares[i].$2,
              description: _descriptions[gruposMusculares[i].$2] ?? '',
              colors: _palettes[i % _palettes.length],
              onOpen: () => context.go('/cliente/rutinas/grupo/${Uri.encodeComponent(gruposMusculares[i].$1)}'),
            ),
        ]),
      ]);
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.group, required this.description, required this.colors, required this.onOpen});
  final String group, description;
  final List<Color> colors;
  final VoidCallback onOpen;
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _flipped = false;

  Widget _face({required List<Color> colors, required Widget child}) => Container(
        height: 240,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final front = _face(
      colors: widget.colors,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.fitness_center, color: Colors.white70, size: 40),
        const SizedBox(height: 12),
        Text(widget.group.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      ]),
    );
    final back = _face(
      colors: const [Color(0xFFCEDCE7), Color(0xFF0E75B9)],
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(widget.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        FilledButton(onPressed: widget.onOpen, child: const Text('Ver rutinas')),
      ]),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _flipped = true),
      onExit: (_) => setState(() => _flipped = false),
      child: GestureDetector(
        onTap: () => setState(() => _flipped = !_flipped),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _flipped ? 1 : 0),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (_, t, __) {
            final angle = t * math.pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
              child: angle > math.pi / 2 ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back) : front,
            );
          },
        ),
      ),
    );
  }
}

class GroupRoutinesPage extends ConsumerWidget {
  const GroupRoutinesPage({super.key, required this.grupo});
  final String grupo;

  static Widget _img(String url, {double? height, double? width}) => Image.network(
        url,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, p) => p == null ? child : SizedBox(height: height, child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: AppColors.accent.withOpacity(.1),
          child: const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.accent)),
        ),
      );

  void _details(BuildContext context, Rutina r) => showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
                decoration: const BoxDecoration(gradient: brandGradient),
                child: Row(children: [
                  const Icon(Icons.fitness_center, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.series} series · ${r.repeticiones} repeticiones', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    if (r.fotos.isEmpty) const Text('Esta rutina no tiene fotos.'),
                    Wrap(spacing: 16, runSpacing: 16, children: [
                      for (final f in r.fotos)
                        SizedBox(
                          width: 300,
                          child: Column(children: [
                            ClipRRect(borderRadius: BorderRadius.circular(12), child: _img(f.url, height: 200)),
                            const SizedBox(height: 8),
                            Text(f.descripcion, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ]),
                        ),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valor = grupoValor(grupo) ?? grupo;
    final rutinas = ref.watch(rutinasClienteProvider);
    return PageBody(title: 'Rutinas de ${grupoLabel(valor)}', children: asyncChildren(rutinas, onRetry: () => ref.invalidate(rutinasClienteProvider), data: (all) {
      final routines = all.where((r) => r.grupoMuscular.toLowerCase() == valor.toLowerCase()).toList();
      return [
      if (routines.isEmpty)
        AppCard(
          child: EmptyState(
            icon: Icons.fitness_center,
            message: 'No hay rutinas disponibles para este grupo muscular.',
            action: GradientButton(label: 'Volver a todas las rutinas', icon: Icons.arrow_back, onPressed: () => context.go('/cliente/rutinas')),
          ),
        )
      else ...[
        AdaptiveGrid(minItemWidth: 260, children: [
          for (final r in routines)
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                r.fotos.isEmpty
                    ? Container(
                        height: 140,
                        color: AppColors.accent.withOpacity(.1),
                        child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppColors.accent)),
                      )
                    : _img(r.fotos.first.url, height: 140),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.nombre, style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${r.series} series · ${r.repeticiones} repeticiones', style: TextStyle(color: context.muted)),
                    const SizedBox(height: 12),
                    FilledButton.tonal(onPressed: () => _details(context, r), child: const Text('Ver detalles')),
                  ]),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: () => context.go('/cliente/rutinas'), icon: const Icon(Icons.arrow_back), label: const Text('Volver a todas las rutinas')),
      ],
      ];
    }));
  }
}
