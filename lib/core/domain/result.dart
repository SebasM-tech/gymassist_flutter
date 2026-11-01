enum FailureType { validation, notFound, conflict, unauthorized, forbidden }

class Failure {
  const Failure(this.type, this.message);
  final FailureType type;
  final String message;

  @override
  String toString() => 'Failure($type): $message';
}

/// Resultado de un caso de uso: éxito con valor o fallo con mensaje apto para mostrar al usuario.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  T? get valueOrNull => switch (this) { Ok<T>(:final value) => value, Err<T>() => null };
  Failure? get failureOrNull => switch (this) { Err<T>(:final failure) => failure, Ok<T>() => null };

  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) => switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

Err<T> fail<T>(FailureType type, String message) => Err<T>(Failure(type, message));
