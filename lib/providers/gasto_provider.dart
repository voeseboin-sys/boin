import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../models/models.dart';
import '../services/database.dart';

// Provider de gastos
final gastosProvider = FutureProvider<List<Gasto>>((ref) async {
  final db = ref.watch(databaseProvider);
  final gastosData = await db.getAllGastos();
  
  return gastosData.map((g) => Gasto(
    id: g.id,
    descripcion: g.descripcion,
    monto: g.monto,
    tipo: g.tipo == 'fabrica' ? TipoGasto.fabrica : TipoGasto.personal,
    categoria: g.categoria,
    fecha: g.fecha,
    mesAfectado: g.mesAfectado,
    comprobante: g.comprobante,
    notas: g.notas,
    createdAt: g.createdAt,
  )).toList();
});

// Provider de gastos por mes
final gastosByMesProvider = FutureProvider.family<List<Gasto>, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  final gastosData = await db.getGastosByMes(mes);
  
  return gastosData.map((g) => Gasto(
    id: g.id,
    descripcion: g.descripcion,
    monto: g.monto,
    tipo: g.tipo == 'fabrica' ? TipoGasto.fabrica : TipoGasto.personal,
    categoria: g.categoria,
    fecha: g.fecha,
    mesAfectado: g.mesAfectado,
    comprobante: g.comprobante,
    notas: g.notas,
    createdAt: g.createdAt,
  )).toList();
});

// Provider de gastos de fábrica por mes
final gastosFabricaByMesProvider = FutureProvider.family<List<Gasto>, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  final gastosData = await db.getGastosByMes(mes, tipo: TipoGasto.fabrica);
  
  return gastosData.map((g) => Gasto(
    id: g.id,
    descripcion: g.descripcion,
    monto: g.monto,
    tipo: TipoGasto.fabrica,
    categoria: g.categoria,
    fecha: g.fecha,
    mesAfectado: g.mesAfectado,
    comprobante: g.comprobante,
    notas: g.notas,
    createdAt: g.createdAt,
  )).toList();
});

// Provider de gastos personales por mes
final gastosPersonalesByMesProvider = FutureProvider.family<List<Gasto>, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  final gastosData = await db.getGastosByMes(mes, tipo: TipoGasto.personal);
  
  return gastosData.map((g) => Gasto(
    id: g.id,
    descripcion: g.descripcion,
    monto: g.monto,
    tipo: TipoGasto.personal,
    categoria: g.categoria,
    fecha: g.fecha,
    mesAfectado: g.mesAfectado,
    comprobante: g.comprobante,
    notas: g.notas,
    createdAt: g.createdAt,
  )).toList();
});

// Notifier para operaciones de gastos
class GastoNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  GastoNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> registrarGasto({
    required String descripcion,
    required double monto,
    required TipoGasto tipo,
    required String categoria,
    DateTime? mesAfectado,
    String? comprobante,
    String? notas,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final now = DateTime.now();
      await _db.insertGasto(GastosCompanion(
        descripcion: Value(descripcion),
        monto: Value(monto),
        tipo: Value(tipo == TipoGasto.fabrica ? 'fabrica' : 'personal'),
        categoria: Value(categoria),
        mesAfectado: Value(mesAfectado ?? DateTime(now.year, now.month)),
        comprobante: comprobante != null ? Value(comprobante) : const Value.absent(),
        notas: notas != null ? Value(notas) : const Value.absent(),
      ));
      
      _ref.invalidate(gastosProvider);
      _ref.invalidate(gastosByMesProvider(DateTime.now()));
      _ref.invalidate(metricasProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> eliminarGasto(String id) async {
    state = const AsyncValue.loading();
    
    try {
      await _db.deleteGasto(id);
      _ref.invalidate(gastosProvider);
      _ref.invalidate(metricasProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final gastoNotifierProvider = StateNotifierProvider<GastoNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return GastoNotifier(db, ref);
});
