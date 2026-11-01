import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppColors {
  AppColors._();
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFF3B82F6);
  static const accentDark = Color(0xFF1E40AF);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);
}

const brandGradient = LinearGradient(
    colors: [AppColors.accentDark, AppColors.accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
const authGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
const navGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
const navGradientDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
const sidebarGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter);
const sidebarGradientDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter);

/// Tema claro/oscuro. TODO(settings): persistir con shared_preferences.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class AppTheme {
  AppTheme._();
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final border = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fill = dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    OutlineInputBorder outline(Color c, [double w = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w));
    final scheme = ColorScheme.fromSeed(
            seedColor: AppColors.accent, brightness: b)
        .copyWith(
      primary: dark ? AppColors.accentLight : AppColors.accent,
      surface: dark ? const Color(0xFF1E293B) : Colors.white,
      outlineVariant: border,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: fill,
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(AppColors.accent, 2),
        errorBorder: outline(AppColors.danger),
        focusedErrorBorder: outline(AppColors.danger, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get border => cs.outlineVariant;
  Color get muted => cs.onSurface.withOpacity(.62);
}
