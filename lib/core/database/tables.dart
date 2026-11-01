import 'package:drift/drift.dart';
import 'package:gymassist/core/database/converters.dart';
import 'package:gymassist/core/domain/enums.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';

/// Columnas comunes. `updatedAt` y `deletedAt` (borrado lógico) dejan lista la sincronización futura.
mixin SyncColumns on Table {
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Unifica `user` + credenciales duplicadas en `client` + `admin` de Mongo.
@DataClassName('UserRow')
class Users extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get username => text().unique()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => textEnum<UserRole>()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GymRow')
class Gyms extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get adminUserId => text().unique().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get nit => text()();
  TextColumn get address => text()();
  TextColumn get description => text()();
  TextColumn get bankAccount => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlanRow')
class Plans extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get gymId => text().references(Gyms, #id)();
  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get priceCop => integer()();
  IntColumn get durationMonths => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClientRow')
@TableIndex(name: 'idx_clients_gym', columns: {#gymId})
@TableIndex(name: 'idx_clients_status', columns: {#status})
class Clients extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().unique().references(Users, #id)();
  TextColumn get gymId => text().references(Gyms, #id)();
  // Si se elimina un plan, el cliente queda sin plan (regla de PlanService.deletePlanById).
  TextColumn get planId => text().nullable().references(Plans, #id, onDelete: KeyAction.setNull)();
  TextColumn get fullName => text()();
  TextColumn get documentId => text()();
  TextColumn get phone => text()();
  TextColumn get status => textEnum<ClientStatus>()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get membershipStart => dateTime().nullable()();
  DateTimeColumn get membershipEnd => dateTime().nullable()();
  IntColumn get missedCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttendanceRow')
@TableIndex(name: 'idx_attendances_client_date', columns: {#clientId, #date})
class Attendances extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get muscles => text().map(const MuscleListConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MeasurementRow')
@TableIndex(name: 'idx_measurements_client', columns: {#clientId})
class Measurements extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id, onDelete: KeyAction.cascade)();
  RealColumn get weightKg => real()();
  RealColumn get heightM => real()();
  DateTimeColumn get measuredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoutineRow')
class Routines extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get gymId => text().references(Gyms, #id)();
  TextColumn get name => text()();
  TextColumn get muscleGroup => textEnum<MuscleGroup>()();
  TextColumn get reps => text()();
  TextColumn get sets => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoutinePhotoRow')
class RoutinePhotos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get relativePath => text()();
  TextColumn get description => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla nueva: el backend original no guardaba pagos (MercadoPago los activaba y se perdían).
@DataClassName('PaymentRow')
@TableIndex(name: 'idx_payments_client', columns: {#clientId})
class Payments extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id, onDelete: KeyAction.cascade)();
  TextColumn get planId => text().nullable().references(Plans, #id, onDelete: KeyAction.setNull)();
  IntColumn get amountCop => integer()();
  TextColumn get method => textEnum<PaymentMethod>()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  TextColumn get registeredBy => text().references(Users, #id)();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cola de cambios pendientes de sincronizar (se llena en la fase de sync; hoy queda vacía).
@DataClassName('OutboxOpRow')
class OutboxOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()(); // insert | update | delete
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
