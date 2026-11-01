import 'package:flutter/widgets.dart';

/// Validaciones de formulario. TODO(domain): mover las reglas de negocio a value objects del dominio.
class Validators {
  Validators._();

  static String? notEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  static String? email(String? v) {
    final e = notEmpty(v);
    if (e != null) return e;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim())
        ? null
        : 'Correo no válido';
  }

  static double? parse(String? v) =>
      double.tryParse((v ?? '').replaceAll(',', '.'));

  static String? number(String? v) {
    final e = notEmpty(v);
    if (e != null) return e;
    return parse(v) == null ? 'Ingresa un número' : null;
  }

  static String? positive(String? v) {
    final e = number(v);
    if (e != null) return e;
    return parse(v)! > 0 ? null : 'Debe ser mayor que 0';
  }

  static String? Function(String?) minLength(int n) =>
      (v) => (v == null || v.length < n) ? 'Mínimo $n caracteres' : null;

  static String? Function(String?) matches(TextEditingController other,
          [String msg = 'Las contraseñas no coinciden']) =>
      (v) => v == other.text ? null : msg;
}
