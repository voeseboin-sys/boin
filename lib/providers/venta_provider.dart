import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'; // Necesario para 'Value'
import '../models/models.dart';
// ALIAS CRÍTICO: 'db' para diferenciar la base de datos de tus modelos
import '../services/database.dart' as db;
import 'auth_provider.dart';
import 'producto_provider.dart'; // Para recargar el stock después de vender

// 1. Provider de la Base de Datos (Reutilizable)
final databaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase();
});

// 2. Provider para ver el Historial de Ventas
final ventasProvider = FutureProvider<List<Venta>>((ref) async {
  final database = ref.watch(databaseProvider);
  
  // Usamos getAllVentas del archivo database.dart
  final ventasData = await database.getAllVentas();
  
  // Convertimos los datos de Drift a tu Modelo Venta
  return ventasData.map((v) => Venta(
    id: v.id,
    total: v.total,
    fecha: v.fecha,
    usuarioId: v.usuarioId,
    // Nota: Por ahora dejamos la lista de items vacía en la vista general 
    // para no hacer consultas pesadas innecesarias.
    items: [], 
  )).toList();
});

// 3. Notifier del CARRITO (Maneja la lista temporal antes de vender)
class CarritoNotifier extends StateNotifier<List<VentaItem>> {
  CarritoNotifier() : super([]);

  void agregarItem(Producto producto, int cantidad, double precioAplicado) {
    // Buscamos si el producto ya está en el carrito
    final index = state.indexWhere((item) => item.productoId == producto.id);

    if (index >= 0) {
      // Si ya existe, sumamos la cantidad
      final itemExistente = state[index];
      final nuevaCantidad = itemExistente.cantidad + cantidad;
      
      final itemsActualizados = [...state];
      itemsActualizados[index] = VentaItem(
        productoId: producto.id,
        nombreProducto: producto.nombre,
        cantidad: nuevaCantidad,
        precioUnitario: precioAplicado,
        subtotal: nuevaCantidad * precioAplicado,
      );
      state = itemsActualizados;
    } else {
      // Si es nuevo, lo agregamos
      state = [
        ...state,
        VentaItem(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          cantidad: cantidad,
          precioUnitario: precioAplicado,
          subtotal: cantidad * precioAplicado,
        ),
      ];
    }
  }

  void quitarItem(int productoId) {
    state = state.where((item) => item.productoId != productoId).toList();
  }

  void limpiarCarrito() {
    state = [];
  }
  
  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final carritoProvider = StateNotifierProvider<CarritoNotifier, List<VentaItem>>((ref) {
  return CarritoNotifier();
});

// 4. Notifier para CONFIRMAR la Venta (La acción de guardar)
class VentaActionNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase _db;
  final Ref _ref;

  VentaActionNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> confirmarVenta() async {
    state = const AsyncValue.loading();
    
    try {
      // Obtenemos los datos necesarios de otros providers
      final items = _ref.read(carritoProvider);
      final authState = _ref.read(authProvider); // Asumimos que authProvider expone el estado
      final usuario = authState.usuario; // Ajusta esto según cómo expongas el usuario
      
      if (items.isEmpty) throw Exception("El carrito está vacío");
      // Si no hay usuario logueado, usamos ID 1 por defecto para evitar crash
      final usuarioId = usuario?.id ?? 1; 

      final totalVenta = items.fold(0.0, (sum, item) => sum + item.subtotal);

      // A) Preparamos la cabecera de la venta (VentasCompanion)
      final ventaCompanion = db.VentasCompanion(
        total: Value(totalVenta),
        fecha: Value(DateTime.now()),
        usuarioId: Value(usuarioId),
      );

      // B) Preparamos los items (Lista de VentaItemsCompanion)
      final itemsCompanion = items.map((item) => db.VentaItemsCompanion(
        productoId: Value(item.productoId),
        cantidad: Value(item.cantidad),
        precioAplicado: Value(item.precioUnitario),
        // El ventaId se asigna automático dentro de la transacción en database.dart
      )).toList();

      // C) ¡GUARDAMOS! Llamamos a la transacción que creamos en el Paso 1
      await _db.insertVenta(ventaCompanion, itemsCompanion);

      // D) Limpieza y Actualización
      _ref.read(carritoProvider.notifier).limpiarCarrito();
      _ref.invalidate(ventasProvider);     // Refrescar historial ventas
      _ref.invalidate(productosProvider);  // CRÍTICO: Refrescar stock de productos
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final ventaActionProvider = StateNotifierProvider<VentaActionNotifier, AsyncValue<void>>((ref) {
  final database = ref.watch(databaseProvider);
  return VentaActionNotifier(database, ref);
});
