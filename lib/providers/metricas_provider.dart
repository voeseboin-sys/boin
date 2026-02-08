import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/database.dart';

// Provider del mes seleccionado
final mesSeleccionadoProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// Provider de métricas del dashboard
final metricasProvider = FutureProvider.family<MetricasDashboard, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  return db.getMetricasDashboard(mes);
});

// Provider de dinero total
final dineroTotalProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getDineroTotal();
});

// Provider para historial de métricas (últimos 6 meses)
final historialMetricasProvider = FutureProvider<List<MetricasDashboard>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final meses = <MetricasDashboard>[];
  
  for (int i = 5; i >= 0; i--) {
    final mes = DateTime(now.year, now.month - i);
    final metricas = await db.getMetricasDashboard(mes);
    meses.add(metricas);
  }
  
  return meses;
});
