import 'package:flutter_test/flutter_test.dart';
import 'package:gymassist/core/utils/date_utils.dart';

void main() {
  test('addMonths ajusta al último día del mes', () {
    expect(addMonths(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 28));
    expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    expect(addMonths(DateTime(2025, 10, 15), 3), DateTime(2026, 1, 15));
  });

  test('addMonths con meses negativos cruza el año correctamente', () {
    expect(addMonths(DateTime(2025, 2, 1), -5), DateTime(2024, 9, 1));
    expect(addMonths(DateTime(2025, 1, 1), -1), DateTime(2024, 12, 1));
  });

  test('daysBetween cuenta días calendario', () {
    expect(daysBetween(DateTime(2025, 10, 1, 23), DateTime(2025, 10, 4, 1)), 3);
    expect(daysBetween(DateTime(2025, 10, 4), DateTime(2025, 10, 1)), -3);
  });
}
