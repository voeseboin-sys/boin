import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../models/models.dart';
import '../services/database.dart';

// Provider de producción
final produccionProvider = FutureProvider<List<Produccion>>((ref) async {
  final db = ref.watch(databaseProvider);
  final produccionData = await db.getAllProduccion();
  
  return produccionData.map((p) => Produccion(
    id: p.id,
    productoId: p.productoId,
    nombreProducto: p.nombreProducto,
    cantidad: p.cantidad,
    fecha: p.fecha,
    mes: p.mes,
    costoUnitarioCalculado: p.costoUnitarioCalculado,
    notas: p.notas,
    createdAt: p.createdAt,
  )).toList();
});

// Provider de producción por mes
final produccionByMesProvider = FutureProvider.family<List<Produccion>, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  final produccionData = await db.getProduccionByMes(mes);
  
  return produccionData.map((p) => Produccion(
    id: p.id,
    productoId: p.productoId,
    nombreProducto: p.nombreProducto,
    cantidad: p.cantidad,
    fecha: p.fecha,
    mes: p.mes,
    costoUnitarioCalculado: p.costoUnitarioCalculado,
    notas: p.notas,
    createdAt: p.createdAt,
  )).toList();
});

// Provider de unidades producidas por mes
final unidadesProducidasMesProvider = FutureProvider.family<int, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  return db.getTotalUnidadesProducidasMes(mes);
});

// Notifier para operaciones de producción
class ProduccionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  ProduccionNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> registrarProduccion({
    required String productoId,
    required String nombreProducto,
    required int cantidad,
    DateTime? mes,
    String? notas,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final now = DateTime.now();
      await _db.insertProduccion(ProduccionCompanion(
        productoId: Value(productoId),
        nombreProducto: Value(nombreProducto),
        cantidad: Value(cantidad),
        mes: Value(mes ?? DateTime(now.year, now.month)),
        notas: notas != null ? Value(notas) : const Value.absent(),
      ));
      
      _ref.invalidate(produccionProvider);
      _ref.invalidate(produccionByMesProvider(DateTime.now()));
      _ref.invalidate(unidadesProducidasMesProvider(DateTime.now()));
      _ref.invalidate(productosProvider);
      _ref.invalidate(metricasProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> eliminarProduccion(String id) async {
    state = const AsyncValue.loading();
    
    try {
      await _db.deleteProduccion(id);
      _ref.invalidate(produccionProvider);
      _ref.invalidate(produccionByMesProvider(DateTime.now()));
      _ref.invalidate(unidadesProducidasMesProvider(DateTime.now()));
      _ref.invalidate(productosProvider);
      _ref.invalidate(metricasProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final produccionNotifierProvider = StateNotifierProvider<ProduccionNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return ProduccionNotifier(db, ref);
});
