import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../models/models.dart';
import '../services/database.dart';
import 'auth_provider.dart';

// Provider de ventas
final ventasProvider = FutureProvider<List<Venta>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllVentas();
});

// Provider de ventas por mes
final ventasByMesProvider = FutureProvider.family<List<Venta>, DateTime>((ref, mes) async {
  final db = ref.watch(databaseProvider);
  return db.getVentasByMes(mes);
});

// Notifier para carrito de ventas
class CarritoVentaNotifier extends StateNotifier<List<VentaItem>> {
  CarritoVentaNotifier() : super([]);

  void agregarItem({
    required Producto producto,
    required int cantidad,
    required TipoPrecio tipoPrecio,
  }) {
    final precio = tipoPrecio == TipoPrecio.mayorista 
        ? producto.precioMayorista 
        : producto.precioMinorista;
    
    final itemExistente = state.indexWhere(
      (i) => i.productoId == producto.id && i.tipoPrecio == tipoPrecio
    );
    
    if (itemExistente >= 0) {
      // Actualizar cantidad si ya existe
      final item = state[itemExistente];
      final nuevaCantidad = item.cantidad + cantidad;
      final nuevoSubtotal = nuevaCantidad * precio;
      
      state = [
        ...state.sublist(0, itemExistente),
        item.copyWith(
          cantidad: nuevaCantidad,
          subtotal: nuevoSubtotal,
        ),
        ...state.sublist(itemExistente + 1),
      ];
    } else {
      // Agregar nuevo item
      state = [
        ...state,
        VentaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productoId: producto.id,
          nombreProducto: producto.nombre,
          cantidad: cantidad,
          precioUnitario: precio,
          tipoPrecio: tipoPrecio,
          subtotal: cantidad * precio,
        ),
      ];
    }
  }

  void actualizarCantidad(String itemId, int nuevaCantidad) {
    final index = state.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      final item = state[index];
      state = [
        ...state.sublist(0, index),
        item.copyWith(
          cantidad: nuevaCantidad,
          subtotal: nuevaCantidad * item.precioUnitario,
        ),
        ...state.sublist(index + 1),
      ];
    }
  }

  void eliminarItem(String itemId) {
    state = state.where((i) => i.id != itemId).toList();
  }

  void limpiar() {
    state = [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.subtotal);
  int get totalItems => state.fold(0, (sum, item) => sum + item.cantidad);
}

final carritoVentaProvider = StateNotifierProvider<CarritoVentaNotifier, List<VentaItem>>((ref) {
  return CarritoVentaNotifier();
});

// Provider para descuento
final descuentoVentaProvider = StateProvider<double>((ref) => 0);

// Notifier para operaciones de ventas
class VentaNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  VentaNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<void> registrarVenta({
    required List<VentaItem> items,
    required double subtotal,
    required double descuento,
    required double total,
    String? cliente,
    String? notas,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final auth = _ref.read(authProvider);
      final vendedorId = auth.usuario?.id ?? '1';
      final nombreVendedor = auth.usuario?.nombre ?? 'Sistema';
      
      final ventaCompanion = VentasCompanion(
        subtotal: Value(subtotal),
        descuento: Value(descuento),
        total: Value(total),
        cliente: cliente != null ? Value(cliente) : const Value.absent(),
        notas: notas != null ? Value(notas) : const Value.absent(),
        vendedorId: Value(vendedorId),
        nombreVendedor: Value(nombreVendedor),
      );
      
      final itemsCompanion = items.map((item) => VentaItemsCompanion(
        productoId: Value(item.productoId),
        nombreProducto: Value(item.nombreProducto),
        cantidad: Value(item.cantidad),
        precioUnitario: Value(item.precioUnitario),
        tipoPrecio: Value(item.tipoPrecio == TipoPrecio.mayorista ? 'mayorista' : 'minorista'),
        subtotal: Value(item.subtotal),
      )).toList();
      
      await _db.insertVenta(ventaCompanion, itemsCompanion);
      
      _ref.invalidate(ventasProvider);
      _ref.invalidate(ventasByMesProvider(DateTime.now()));
      _ref.invalidate(metricasProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> eliminarVenta(String id) async {
    state = const AsyncValue.loading();
    
    try {
      await _db.deleteVenta(id);
      _ref.invalidate(ventasProvider);
      _ref.invalidate(metricasProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final ventaNotifierProvider = StateNotifierProvider<VentaNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return VentaNotifier(db, ref);
});
