import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/models.dart';
import 'package:gymassist/core/api/session.dart';

// Datos del backend Spring Boot. Cada pantalla los observa y, tras crear/editar,
// hace ref.invalidate(...) para volver a pedirlos.

// ---- admin
final adminResumenProvider = FutureProvider.autoDispose<ResumenAdmin>((ref) => ref.watch(gymApiProvider).resumen());
final adminClientesProvider = FutureProvider.autoDispose<List<Cliente>>((ref) => ref.watch(gymApiProvider).clientes());
final adminPlanesProvider = FutureProvider.autoDispose<List<Plan>>((ref) => ref.watch(gymApiProvider).planesAdmin());
final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(gymApiProvider).dashboard());
final adminRutinasProvider = FutureProvider.autoDispose<List<Rutina>>((ref) => ref.watch(gymApiProvider).rutinasAdmin());

// ---- cliente
final perfilProvider = FutureProvider.autoDispose<PerfilCliente>((ref) => ref.watch(gymApiProvider).perfil());
final planesClienteProvider = FutureProvider.autoDispose<List<Plan>>((ref) => ref.watch(gymApiProvider).planesCliente());
final rutinasClienteProvider = FutureProvider.autoDispose<List<Rutina>>((ref) => ref.watch(gymApiProvider).rutinasCliente());
final asistenciasProvider = FutureProvider.autoDispose<AsistenciasInfo>((ref) => ref.watch(gymApiProvider).asistencias());
final medicionesProvider = FutureProvider.autoDispose<List<Medicion>>((ref) => ref.watch(gymApiProvider).mediciones());
