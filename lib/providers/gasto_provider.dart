import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../models/models.dart';
// ALIAS IMPORTANTE: 'db' para evitar confusión con el modelo Gasto
import '../services/database.dart' as db;
import 'producto_provider.dart'; // Para reutilizar el databaseProvider

// Provider de Lista de Gastos
final gastosProvider = FutureProvider<List<Gasto>>((ref) async {
  final database = ref.watch(databaseProvider);
  final datosBD = await database.getAllGastos();
  
  // Mapeo: Base de Datos -> Modelo UI
  return datosBD.map((g) => Gasto(
    id: g.id,
    descripcion: g.descripcion,
    monto: g.monto,
    // Convertimos el String de la BD al Enum de la App
    tipo: g.tipo == 'fabrica' ? TipoGasto.fabrica : TipoGasto.personal,
    fecha: g.fecha,
  )).toList();
});

// Provider de Gastos Filtrados por Mes (Para el Dashboard)
final gastosByMesProvider = FutureProvider.family<List<Gasto>, DateTime>((ref, mes) async {
  final database = ref.watch(databaseProvider);
  // Usamos el método getGastosByMes que añadimos a database.dart
  final datosBD = await database.getGastosByMes(mes);
  
  return datosBD.map((g) => Gasto(
    id: g.id,
    descripcion: g.descripcion,
    monto: g.monto,
    tipo: g.tipo == 'fabrica' ? TipoGasto.fabrica : TipoGasto.personal,
    fecha: g.fecha,
  )).toList();
});

// Notifier para Acciones (Crear, Borrar)
class GastoNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase _db;
  final Ref _ref;

  GastoNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> agregarGasto({
    required String descripcion,
    required double monto,
    required TipoGasto tipo,
    required DateTime fecha,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertGasto(db.GastosCompanion(
        descripcion: Value(descripcion),
        monto: Value(monto),
        // Guardamos como texto simple en la base de datos
        tipo: Value(tipo == TipoGasto.fabrica ? 'fabrica' : 'personal'),
        fecha: Value(fecha),
      ));
      
      _ref.invalidate(gastosProvider);
      // También invalidamos el filtro por mes para que el gráfico se actualice
      _ref.invalidate(gastosByMesProvider(fecha)); 
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> eliminarGasto(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteGasto(id);
      _ref.invalidate(gastosProvider);
      // Invalidamos el provider de mes actual por si acaso
      _ref.invalidate(gastosByMesProvider(DateTime.now()));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final gastoNotifierProvider = StateNotifierProvider<GastoNotifier, AsyncValue<void>>((ref) {
  final database = ref.watch(databaseProvider);
  return GastoNotifier(database, ref);
});
