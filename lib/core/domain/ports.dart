/// Reloj inyectable: permite probar reglas que dependen de la fecha (vencimientos, inasistencias).
typedef Clock = DateTime Function();

/// Ejecuta varias operaciones de repositorios como una sola transacción atómica.
abstract interface class Transactor {
  Future<T> run<T>(Future<T> Function() action);
}
