import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../models/models.dart';
// ALIAS IMPORTANTE: 'db' para la base de datos
import '../services/database.dart' as db;

// Provider de la Base de Datos
final databaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase();
});

// Provider de Lista de Productos
final productosProvider = FutureProvider<List<Producto>>((ref) async {
  final database = ref.watch(databaseProvider);
  final datosBD = await database.getAllProductos();
  
  // Convertimos de la BD (Drift) -> Modelo UI
  return datosBD.map((p) => Producto(
    id: p.id,
    nombre: p.nombre,
    precioMayorista: p.precioMayorista,
    precioMinorista: p.precioMinorista,
    stock: p.stock,
  )).toList();
});

// Provider de Producto Individual (por ID)
final productoByIdProvider = FutureProvider.family<Producto?, int>((ref, id) async {
  final database = ref.watch(databaseProvider);
  final p = await database.getProductoById(id);
  
  return Producto(
    id: p.id,
    nombre: p.nombre,
    precioMayorista: p.precioMayorista,
    precioMinorista: p.precioMinorista,
    stock: p.stock,
  );
});

// Notifier para Acciones (Crear, Editar, Borrar)
class ProductoNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase _db;
  final Ref _ref;

  ProductoNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> crearProducto({
    required String nombre,
    required double costo,
    required double precioMayorista,
    required double precioMinorista,
    required int stockInicial,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertProducto(db.ProductosCompanion(
        nombre: Value(nombre),
        costoUnitario: Value(costo),
        precioMayorista: Value(precioMayorista),
        precioMinorista: Value(precioMinorista),
        stock: Value(stockInicial),
      ));
      
      _ref.invalidate(productosProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> actualizarProducto({
    required int id,
    required String nombre,
    required double costo,
    required double precioMayorista,
    required double precioMinorista,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateProducto(db.ProductosCompanion(
        id: Value(id),
        nombre: Value(nombre),
        costoUnitario: Value(costo),
        precioMayorista: Value(precioMayorista),
        precioMinorista: Value(precioMinorista),
      ));
      
      _ref.invalidate(productosProvider);
      _ref.invalidate(productoByIdProvider(id));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> eliminarProducto(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteProducto(id);
      _ref.invalidate(productosProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final productoNotifierProvider = StateNotifierProvider<ProductoNotifier, AsyncValue<void>>((ref) {
  final database = ref.watch(databaseProvider);
  return ProductoNotifier(database, ref);
});
