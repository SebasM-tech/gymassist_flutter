import 'package:gymassist/core/domain/result.dart';

class Plan {
  const Plan({required this.id, required this.gymId, required this.name, required this.description, required this.priceCop, required this.durationMonths});
  final String id, gymId, name, description;
  final int priceCop, durationMonths;

  Plan copyWith({String? name, String? description, int? priceCop, int? durationMonths}) => Plan(
        id: id,
        gymId: gymId,
        name: name ?? this.name,
        description: description ?? this.description,
        priceCop: priceCop ?? this.priceCop,
        durationMonths: durationMonths ?? this.durationMonths,
      );
}

class PlanSummary {
  const PlanSummary({required this.plan, required this.subscribers});
  final Plan plan;
  final int subscribers;
}

abstract interface class PlanRepository {
  Stream<List<PlanSummary>> watchByGym(String gymId);
  Future<List<Plan>> listByGym(String gymId);
  Future<Plan?> findById(String id);
  Future<Plan> create({required String gymId, required String name, required String description, required int priceCop, required int durationMonths});
  Future<void> update(Plan plan);

  /// Borrado lógico; los clientes del plan quedan sin plan (misma regla que `PlanService.deletePlanById`).
  Future<void> delete(String id);
}

class PlanService {
  PlanService(this._repo);
  final PlanRepository _repo;

  Result<void>? _validate(String name, String description, int price, int months) {
    if (name.trim().isEmpty || description.trim().isEmpty) return fail(FailureType.validation, 'El nombre y la descripción son obligatorios.');
    if (price <= 0) return fail(FailureType.validation, 'El precio debe ser mayor que 0.');
    if (months < 1) return fail(FailureType.validation, 'La duración mínima es 1 mes.');
    return null;
  }

  Future<Result<Plan>> create({required String gymId, required String name, required String description, required int priceCop, required int durationMonths}) async {
    final invalid = _validate(name, description, priceCop, durationMonths);
    if (invalid != null) return fail(FailureType.validation, invalid.failureOrNull!.message);
    final existing = await _repo.listByGym(gymId);
    if (existing.any((p) => p.name.toLowerCase() == name.trim().toLowerCase())) {
      return fail(FailureType.conflict, 'Ya existe un plan con ese nombre.');
    }
    return Ok(await _repo.create(gymId: gymId, name: name.trim(), description: description.trim(), priceCop: priceCop, durationMonths: durationMonths));
  }

  Future<Result<Plan>> update(String id, {required String name, required String description, required int priceCop, required int durationMonths}) async {
    final invalid = _validate(name, description, priceCop, durationMonths);
    if (invalid != null) return fail(FailureType.validation, invalid.failureOrNull!.message);
    final current = await _repo.findById(id);
    if (current == null) return fail(FailureType.notFound, 'Plan no encontrado.');
    final clash = (await _repo.listByGym(current.gymId)).any((p) => p.id != id && p.name.toLowerCase() == name.trim().toLowerCase());
    if (clash) return fail(FailureType.conflict, 'Ya existe un plan con ese nombre.');
    final updated = current.copyWith(name: name.trim(), description: description.trim(), priceCop: priceCop, durationMonths: durationMonths);
    await _repo.update(updated);
    return Ok(updated);
  }

  Future<Result<void>> delete(String id) async {
    if (await _repo.findById(id) == null) return fail(FailureType.notFound, 'Plan no encontrado.');
    await _repo.delete(id);
    return const Ok(null);
  }
}
