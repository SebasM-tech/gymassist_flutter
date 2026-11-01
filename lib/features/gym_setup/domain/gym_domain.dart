import 'package:gymassist/core/domain/result.dart';

class Gym {
  const Gym({required this.id, required this.adminUserId, required this.name, required this.nit, required this.address, required this.description, required this.bankAccount});
  final String id, adminUserId, name, nit, address, description, bankAccount;
}

abstract interface class GymRepository {
  Future<Gym?> findByAdmin(String adminUserId);
  Future<Gym?> findById(String id);
  Future<Gym> create({required String adminUserId, required String name, required String nit, required String address, required String description, required String bankAccount});
}

class GymService {
  GymService(this._repo);
  final GymRepository _repo;

  Future<Result<Gym>> register({
    required String adminUserId,
    required String name,
    required String nit,
    required String address,
    required String description,
    required String bankAccount,
  }) async {
    final digits = RegExp(r'^\d+$');
    if ([name, address, description].any((s) => s.trim().isEmpty)) {
      return fail(FailureType.validation, 'Completa todos los campos del gimnasio.');
    }
    if (!digits.hasMatch(nit.trim()) || !digits.hasMatch(bankAccount.trim())) {
      return fail(FailureType.validation, 'El NIT y el número de cuenta solo pueden tener números.');
    }
    if (await _repo.findByAdmin(adminUserId) != null) {
      return fail(FailureType.conflict, 'Ya existe un gimnasio para este administrador.');
    }
    return Ok(await _repo.create(
      adminUserId: adminUserId,
      name: name.trim(),
      nit: nit.trim(),
      address: address.trim(),
      description: description.trim(),
      bankAccount: bankAccount.trim(),
    ));
  }
}
