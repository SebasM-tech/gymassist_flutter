import 'package:drift/drift.dart';
import 'package:gymassist/core/domain/enums.dart';

/// Lista de grupos musculares guardada como "pecho,triceps" (reemplaza la lista embebida de Mongo).
class MuscleListConverter extends TypeConverter<List<MuscleGroup>, String> {
  const MuscleListConverter();

  @override
  List<MuscleGroup> fromSql(String fromDb) =>
      fromDb.isEmpty ? const [] : [for (final n in fromDb.split(',')) MuscleGroup.values.byName(n)];

  @override
  String toSql(List<MuscleGroup> value) => value.map((e) => e.name).join(',');
}
