import 'package:gymassist/core/domain/ports.dart';
import 'package:gymassist/core/utils/date_utils.dart';
import 'package:gymassist/features/clients/domain/client_domain.dart';
import 'package:gymassist/features/clients/domain/client_status.dart';
import 'package:gymassist/features/payments/domain/payment_domain.dart';

class MonthlyIncome {
  const MonthlyIncome(this.year, this.month, this.totalCop);
  final int year, month, totalCop;
}

class DashboardData {
  const DashboardData({required this.incomeMonth, required this.incomeWeek, required this.incomeTotal, required this.newClientsMonth, required this.activeClients, required this.expiringSoon, required this.statusDistribution, required this.incomeTrend});
  final int incomeMonth, incomeWeek, incomeTotal, newClientsMonth, activeClients, expiringSoon;
  final Map<ClientStatus, int> statusDistribution;
  final List<MonthlyIncome> incomeTrend; // últimos 6 meses, del más antiguo al actual
}

/// Reemplaza `DashboardService` + el esquema estrella de PostgreSQL + Power BI.
/// Mejora: los ingresos salen de PAGOS REALES, no de "precio del plan × clientes".
class DashboardService {
  DashboardService({required this.clients, required this.payments, required this.clock});
  final ClientRepository clients;
  final PaymentRepository payments;
  final Clock clock;

  Future<DashboardData> load(String gymId) async {
    final list = await clients.listByGym(gymId);
    final pays = await payments.listByGym(gymId);
    return compute(list, pays, clock());
  }

  static DashboardData compute(List<Client> clients, List<Payment> payments, DateTime now) {
    final today = dateOnly(now);
    final weekStart = today.subtract(Duration(days: today.weekday - 1)); // lunes
    final weekEnd = weekStart.add(const Duration(days: 6));
    bool sameMonth(DateTime d) => d.year == today.year && d.month == today.month;
    int sum(Iterable<Payment> p) => p.fold(0, (a, b) => a + b.amountCop);

    final trend = [
      for (var i = 5; i >= 0; i--)
        () {
          final m = addMonths(DateTime(today.year, today.month, 1), -i);
          return MonthlyIncome(m.year, m.month, sum(payments.where((p) => p.paidAt.year == m.year && p.paidAt.month == m.month)));
        }(),
    ];

    return DashboardData(
      incomeMonth: sum(payments.where((p) => sameMonth(p.paidAt))),
      incomeWeek: sum(payments.where((p) {
        final d = dateOnly(p.paidAt);
        return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
      })),
      incomeTotal: sum(payments),
      newClientsMonth: clients.where((c) => sameMonth(c.joinedAt)).length,
      activeClients: clients.where((c) => c.status == ClientStatus.activo).length,
      expiringSoon: clients.where((c) {
        final end = c.membershipEnd;
        if (c.status != ClientStatus.activo || end == null) return false;
        final e = dateOnly(end);
        return !e.isBefore(today) && !e.isAfter(today.add(const Duration(days: 7)));
      }).length,
      statusDistribution: {for (final s in ClientStatus.values) s: clients.where((c) => c.status == s).length},
      incomeTrend: trend,
    );
  }
}
