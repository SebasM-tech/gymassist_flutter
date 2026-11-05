import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymassist/core/api/api_client.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/utils/validators.dart';
import 'package:gymassist/core/widgets/common.dart';

class _PhotoDraft {
  final desc = TextEditingController();
  XFile? file;
  Uint8List? bytes;
}

/// Lo que sale del formulario (las fotos solo se usan al crear).
class RoutineFormResult {
  const RoutineFormResult({required this.nombre, required this.grupo, required this.repeticiones, required this.series, this.fotos = const [], this.descripciones = const []});
  final String nombre, grupo, repeticiones, series;
  final List<UploadFile> fotos;
  final List<String> descripciones;
}

/// Formulario compartido para crear y editar rutinas. Las fotos se suben a S3 a través de Spring Boot.
class RoutineForm extends StatefulWidget {
  const RoutineForm({super.key, this.initial, required this.submitLabel, required this.onSubmit});
  final Rutina? initial;
  final String submitLabel;

  /// Devuelve true si se guardó (para limpiar el formulario).
  final Future<bool> Function(RoutineFormResult r) onSubmit;

  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> {
  final _key = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.initial?.nombre);
  late final _reps = TextEditingController(text: widget.initial?.repeticiones);
  late final _series = TextEditingController(text: widget.initial?.series);
  late String? _grupo = grupoValor(widget.initial?.grupoMuscular);
  final _drafts = <_PhotoDraft>[_PhotoDraft()];
  bool _busy = false;

  bool get _editing => widget.initial != null;

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

  Future<void> _pick(_PhotoDraft d) async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        d.file = f;
        d.bytes = bytes;
      });
    } catch (e) {
      if (mounted) showToast(context, 'No se pudo abrir la imagen: $e', error: true);
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    final withFile = _drafts.where((d) => d.bytes != null).toList();
    final ok = await widget.onSubmit(RoutineFormResult(
      nombre: _nombre.text.trim(),
      grupo: _grupo!,
      repeticiones: _reps.text.trim(),
      series: _series.text.trim(),
      fotos: [for (final d in withFile) UploadFile(field: 'fotos', bytes: d.bytes!, filename: d.file!.name)],
      descripciones: [for (final d in withFile) d.desc.text.trim().isEmpty ? 'Sin descripción' : d.desc.text.trim()],
    ));
    if (mounted) setState(() => _busy = false);
    if (ok && mounted && !_editing) {
      _key.currentState!.reset();
      for (final c in [_nombre, _reps, _series]) {
        c.clear();
      }
      setState(() {
        _grupo = null;
        for (final d in _drafts) {
          d.desc.dispose();
        }
        _drafts
          ..clear()
          ..add(_PhotoDraft());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.initial?.fotos ?? const <Foto>[];
    return Form(
      key: _key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdaptiveGrid(minItemWidth: 240, children: [
          AppTextField(label: 'Nombre del ejercicio', icon: Icons.sell_outlined, controller: _nombre, validator: Validators.notEmpty),
          DropdownButtonFormField<String>(
            value: _grupo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Grupo muscular', prefixIcon: Icon(Icons.accessibility_new, size: 20)),
            items: [for (final g in gruposMusculares) DropdownMenuItem(value: g.$1, child: Text(g.$2))],
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
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final f in existing)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(f.url, width: 96, height: 96, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 96, height: 96, color: AppColors.accent.withOpacity(.1), child: const Icon(Icons.broken_image_outlined))),
              ),
          ]),
          const SizedBox(height: 16),
        ],
        if (!_editing) ...[
          const CardTitle('Fotos de la rutina', icon: Icons.add_photo_alternate_outlined),
          const SizedBox(height: 12),
          for (var i = 0; i < _drafts.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: context.border), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Row(children: [
                  if (_drafts[i].bytes != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_drafts[i].bytes!, width: 52, height: 52, fit: BoxFit.cover),
                      ),
                    ),
                  OutlinedButton.icon(onPressed: () => _pick(_drafts[i]), icon: const Icon(Icons.upload_file), label: const Text('Seleccionar')),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_drafts[i].file?.name ?? 'Ningún archivo', overflow: TextOverflow.ellipsis, style: TextStyle(color: context.muted))),
                  if (_drafts.length > 1)
                    IconButton(tooltip: 'Quitar', onPressed: () => setState(() => _drafts.removeAt(i).desc.dispose()), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 12),
                AppTextField(label: 'Descripción breve', icon: Icons.short_text, controller: _drafts[i].desc),
              ]),
            ),
        ],
        Row(children: [
          if (!_editing) OutlinedButton.icon(onPressed: () => setState(() => _drafts.add(_PhotoDraft())), icon: const Icon(Icons.add), label: const Text('Agregar foto')),
          const Spacer(),
          GradientButton(label: _busy ? 'Guardando…' : widget.submitLabel, icon: Icons.save_outlined, onPressed: _busy ? null : _save),
        ]),
      ]),
    );
  }
}
