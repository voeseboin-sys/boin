import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../models/models.dart';
import '../services/database.dart';
import 'auth_provider.dart';

// Provider de productos
final productosProvider = FutureProvider<List<Producto>>((ref) async {
  final db = ref.watch(databaseProvider);
  final productosData = await db.getAllProductos();
  
  return productosData.map((p) => Producto(
    id: p.id,
    nombre: p.nombre,
    descripcion: p.descripcion,
    precioMayorista: p.precioMayorista,
    precioMinorista: p.precioMinorista,
    stock: p.stock,
    costoProduccion: p.costoProduccion,
    mesFabricacion: p.mesFabricacion,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
  )).toList();
});

// Provider de producto por ID
final productoByIdProvider = FutureProvider.family<Producto?, String>((ref, id) async {
  final db = ref.watch(databaseProvider);
  final p = await db.getProductoById(id);
  if (p == null) return null;
  
  return Producto(
    id: p.id,
    nombre: p.nombre,
    descripcion: p.descripcion,
    precioMayorista: p.precioMayorista,
    precioMinorista: p.precioMinorista,
    stock: p.stock,
    costoProduccion: p.costoProduccion,
    mesFabricacion: p.mesFabricacion,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
  );
});

// Notifier para operaciones de productos
class ProductoNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  ProductoNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> crearProducto({
    required String nombre,
    String? descripcion,
    required double precioMayorista,
    required double precioMinorista,
    required int stockInicial,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final now = DateTime.now();
      await _db.insertProducto(ProductosCompanion(
        nombre: Value(nombre),
        descripcion: descripcion != null ? Value(descripcion) : const Value.absent(),
        precioMayorista: Value(precioMayorista),
        precioMinorista: Value(precioMinorista),
        stock: Value(stockInicial),
        mesFabricacion: Value(DateTime(now.year, now.month)),
      ));
      
      _ref.invalidate(productosProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> actualizarProducto({
    required String id,
    required String nombre,
    String? descripcion,
    required double precioMayorista,
    required double precioMinorista,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _db.updateProducto(ProductosCompanion(
        id: Value(id),
        nombre: Value(nombre),
        descripcion: descripcion != null ? Value(descripcion) : const Value.absent(),
        precioMayorista: Value(precioMayorista),
        precioMinorista: Value(precioMinorista),
        updatedAt: Value(DateTime.now()),
      ));
      
      _ref.invalidate(productosProvider);
      _ref.invalidate(productoByIdProvider(id));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> eliminarProducto(String id) async {
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
  final db = ref.watch(databaseProvider);
  return ProductoNotifier(db, ref);
});
