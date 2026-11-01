import 'dart:math' as math;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Suma meses ajustando al último día del mes (31-ene + 1 mes = 28/29-feb), igual que `LocalDate.plusMonths` de Java.
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + (total / 12).floor(); // floor: también correcto con meses negativos
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(d.day, lastDay));
}

/// Días calendario entre dos fechas (positivo si [b] es posterior a [a]); inmune a cambios de horario.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
