import 'package:flutter/material.dart';
import 'package:gymassist/core/mock/mock_data.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

class _PhotoDraft {
  final desc = TextEditingController();
  String? file;
}

/// Formulario compartido para crear y editar rutinas.
class RoutineForm extends StatefulWidget {
  const RoutineForm({super.key, this.initial, required this.submitLabel, required this.onSaved});
  final MockRoutine? initial;
  final String submitLabel;
  final VoidCallback onSaved;

  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> {
  final _key = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.initial?.ejercicio);
  late final _reps = TextEditingController(text: widget.initial?.repeticiones);
  late final _series = TextEditingController(text: widget.initial?.series);
  late String? _grupo = widget.initial?.grupo;
  final _drafts = <_PhotoDraft>[_PhotoDraft()];
  final _toDelete = <int>{};

  @override
  void dispose() {
    for (final c in [_nombre, _reps, _series]) {
      c.dispose();
    }
    for (final d in _drafts) {
      d.desc.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    // TODO(routines): SaveRoutine use case (copia las imágenes al almacenamiento local y guarda rutas relativas).
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.initial?.fotos ?? const <String>[];
    return Form(
      key: _key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdaptiveGrid(minItemWidth: 240, children: [
          AppTextField(label: 'Nombre del ejercicio', icon: Icons.sell_outlined, controller: _nombre, validator: Validators.notEmpty),
          DropdownButtonFormField<String>(
            value: _grupo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Grupo muscular', prefixIcon: Icon(Icons.accessibility_new, size: 20)),
            items: [for (final g in muscleGroups) DropdownMenuItem(value: g, child: Text(g))],
            onChanged: (v) => _grupo = v,
            validator: (v) => v == null ? 'Selecciona un grupo' : null,
          ),
          AppTextField(label: 'Repeticiones', icon: Icons.repeat, controller: _reps, validator: Validators.notEmpty),
          AppTextField(label: 'Series', icon: Icons.layers_outlined, controller: _series, validator: Validators.notEmpty),
        ]),
        const SizedBox(height: 24),
        if (existing.isNotEmpty) ...[
          const CardTitle('Fotos actuales', icon: Icons.photo_library_outlined),
          const SizedBox(height: 12),
          for (var i = 0; i < existing.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.image_outlined, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(existing[i])),
                Checkbox(value: _toDelete.contains(i), onChanged: (v) => setState(() => v! ? _toDelete.add(i) : _toDelete.remove(i))),
                const Text('Eliminar'),
              ]),
            ),
          const SizedBox(height: 16),
        ],
        CardTitle(existing.isEmpty ? 'Fotos de la rutina' : 'Agregar nuevas fotos', icon: Icons.add_photo_alternate_outlined),
        const SizedBox(height: 12),
        for (var i = 0; i < _drafts.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: context.border), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(children: [
                OutlinedButton.icon(
                  // TODO(routines): image_picker -> copiar a getApplicationDocumentsDirectory()/routines/
                  onPressed: () => setState(() => _drafts[i].file = 'imagen_${i + 1}.jpg'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Seleccionar archivo'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_drafts[i].file ?? 'Ningún archivo', overflow: TextOverflow.ellipsis, style: TextStyle(color: context.muted))),
                if (_drafts.length > 1)
                  IconButton(tooltip: 'Quitar', onPressed: () => setState(() => _drafts.removeAt(i).desc.dispose()), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              AppTextField(label: 'Descripción breve', icon: Icons.short_text, controller: _drafts[i].desc),
            ]),
          ),
        Row(children: [
          OutlinedButton.icon(onPressed: () => setState(() => _drafts.add(_PhotoDraft())), icon: const Icon(Icons.add), label: const Text('Agregar foto')),
          const Spacer(),
          GradientButton(label: widget.submitLabel, icon: Icons.save_outlined, onPressed: _save),
        ]),
      ]),
    );
  }
}
