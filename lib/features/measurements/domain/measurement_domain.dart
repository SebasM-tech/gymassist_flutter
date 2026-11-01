import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/core/domain/result.dart';
import 'package:gymassist/features/measurements/domain/imc_calculator.dart';

class Measurement {
  const Measurement({required this.id, required this.clientId, required this.weightKg, required this.heightM, required this.measuredAt});
  final String id, clientId;
  final double weightKg, heightM;
  final DateTime measuredAt;

  double get imc => ImcCalculator.calculate(weightKg, heightM);
  String get imcLabel => ImcCalculator.interpret(imc);
}

abstract interface class MeasurementRepository {
  Stream<List<Measurement>> watchByClient(String clientId); // más reciente primero
  Future<Measurement?> latest(String clientId);
  Future<Measurement> add({required String clientId, required double weightKg, required double heightM, required DateTime measuredAt});
}

class MeasurementService {
  MeasurementService(this._repo, this._clock);
  final MeasurementRepository _repo;
  final Clock _clock;

  Future<Result<Measurement>> save({required String clientId, required double weightKg, required double heightM}) async {
    if (weightKg < 20 || weightKg > 400) return fail(FailureType.validation, 'El peso debe estar entre 20 y 400 kg.');
    if (heightM < 0.5 || heightM > 2.5) return fail(FailureType.validation, 'La estatura debe estar entre 0,5 y 2,5 m.');
    return Ok(await _repo.add(clientId: clientId, weightKg: weightKg, heightM: heightM, measuredAt: _clock()));
  }
}
