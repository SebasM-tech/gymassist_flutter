enum UserRole { admin, client }

enum PaymentMethod {
  efectivo('Efectivo'),
  transferencia('Transferencia'),
  tarjeta('Tarjeta'),
  otro('Otro');

  const PaymentMethod(this.label);
  final String label;
}

enum MuscleGroup {
  pecho('Pecho'),
  espalda('Espalda'),
  cuadriceps('Cuádriceps'),
  femoral('Femoral'),
  gluteos('Glúteos'),
  biceps('Bíceps'),
  triceps('Tríceps'),
  hombros('Hombros');

  const MuscleGroup(this.label);
  final String label;
}
