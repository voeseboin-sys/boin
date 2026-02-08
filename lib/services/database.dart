import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

// ==================== TABLAS ====================

class Usuarios extends Table {
  TextColumn get id => text().withDefault(Constant(_uuid.v4()))();
  TextColumn get nombre => text()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get rol => text()(); // 'dueno' o 'vendedor'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Productos extends Table {
  TextColumn get id => text().withDefault(Constant(_uuid.v4()))();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  RealColumn get precioMayorista => real()();
  RealColumn get precioMinorista => real()();
  IntegerColumn get stock => integer().withDefault(Constant(0))();
  RealColumn get costoProduccion => real().withDefault(Constant(0))();
  DateTimeColumn get mesFabricacion => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Ventas extends Table {
  TextColumn get id => text().withDefault(Constant(_uuid.v4()))();
  RealColumn get subtotal => real()();
  RealColumn get descuento => real().withDefault(Constant(0))();
  RealColumn get total => real()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  TextColumn get cliente => text().nullable()();
  TextColumn get notas => text().nullable()();
  TextColumn get vendedorId => text()();
  TextColumn get nombreVendedor => text()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class VentaItems extends Table {
  TextColumn get id => text().withDefault(Constant(_uuid.v4()))();
  TextColumn get ventaId => text().references(Ventas, #id, onDelete: KeyAction.cascade)();
  TextColumn get productoId => text().references(Productos, #id)();
  TextColumn get nombreProducto => text()();
  IntegerColumn get cantidad => integer()();
  RealColumn get precioUnitario => real()();
  TextColumn get tipoPrecio => text()(); // 'mayorista' o 'minorista'
  RealColumn get subtotal => real()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Gastos extends Table {
  TextColumn get id => text().withDefault(Constant(_uuid.v4()))();
  TextColumn get descripcion => text()();
  RealColumn get monto => real()();
  TextColumn get tipo => text()(); // 'fabrica' o 'personal'
  TextColumn get categoria => text()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get mesAfectado => dateTime()();
  TextColumn get comprobante => text().nullable()();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Produccion extends Table {
  TextColumn get id => text().withDefault(Constant(_uuid.v4()))();
  TextColumn get productoId => text().references(Productos, #id)();
  TextColumn get nombreProducto => text()();
  IntegerColumn get cantidad => integer()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get mes => dateTime()();
  RealColumn get costoUnitarioCalculado => real().nullable()();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Configuracion extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();
  
  @override
  Set<Column> get primaryKey => {clave};
}

// ==================== DATABASE ====================

@DriftDatabase(tables: [
  Usuarios,
  Productos,
  Ventas,
  VentaItems,
  Gastos,
  Produccion,
  Configuracion,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Insertar usuarios demo
      await into(usuarios).insertOnConflictUpdate(UsuariosCompanion(
        id: const Value('1'),
        nombre: const Value('Administrador'),
        email: const Value('admin@fabrica.com'),
        password: const Value('admin123'),
        rol: const Value('dueno'),
      ));
      await into(usuarios).insertOnConflictUpdate(UsuariosCompanion(
        id: const Value('2'),
        nombre: const Value('Vendedor'),
        email: const Value('vendedor@fabrica.com'),
        password: const Value('vendedor123'),
        rol: const Value('vendedor'),
      ));
      // Inicializar dinero total
      await into(configuracion).insertOnConflictUpdate(ConfiguracionCompanion(
        clave: const Value('dinero_total'),
        valor: const Value('0'),
      ));
    },
  );

  // ==================== USUARIOS ====================
  
  Future<Usuario?> login(String email, String password) async {
    final query = select(usuarios)
      ..where((u) => u.email.equals(email) & u.password.equals(password));
    return query.getSingleOrNull();
  }

  Future<List<Usuario>> getAllUsuarios() => select(usuarios).get();

  Future<Usuario?> getUsuarioById(String id) {
    return (select(usuarios)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  // ==================== PRODUCTOS ====================
  
  Future<List<Producto>> getAllProductos() => select(productos).get();

  Future<Producto?> getProductoById(String id) {
    return (select(productos)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertProducto(ProductosCompanion producto) {
    return into(productos).insert(producto);
  }

  Future<bool> updateProducto(ProductosCompanion producto) {
    return update(productos).replace(producto);
  }

  Future<int> deleteProducto(String id) {
    return (delete(productos)..where((p) => p.id.equals(id))).go();
  }

  Future<int> updateStock(String productoId, int nuevaCantidad) {
    return (update(productos)..where((p) => p.id.equals(productoId)))
        .write(ProductosCompanion(stock: Value(nuevaCantidad)));
  }

  // ==================== VENTAS ====================
  
  Future<List<Venta>> getAllVentas() async {
    final ventasList = await select(ventas).get();
    final result = <Venta>[];
    
    for (final v in ventasList) {
      final items = await getVentaItems(v.id);
      result.add(Venta(
        id: v.id,
        subtotal: v.subtotal,
        descuento: v.descuento,
        total: v.total,
        fecha: v.fecha,
        cliente: v.cliente,
        notas: v.notas,
        vendedorId: v.vendedorId,
        nombreVendedor: v.nombreVendedor,
        items: items,
      ));
    }
    
    return result;
  }

  Future<List<VentaItem>> getVentaItems(String ventaId) async {
    final items = await (select(ventaItems)
      ..where((vi) => vi.ventaId.equals(ventaId)))
      .get();
    
    return items.map((i) => VentaItem(
      id: i.id,
      productoId: i.productoId,
      nombreProducto: i.nombreProducto,
      cantidad: i.cantidad,
      precioUnitario: i.precioUnitario,
      tipoPrecio: i.tipoPrecio == 'mayorista' ? TipoPrecio.mayorista : TipoPrecio.minorista,
      subtotal: i.subtotal,
    )).toList();
  }

  Future<List<Venta>> getVentasByMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    final ventasList = await (select(ventas)
      ..where((v) => v.fecha.isBetweenValues(inicioMes, finMes)))
      .get();
    
    final result = <Venta>[];
    for (final v in ventasList) {
      final items = await getVentaItems(v.id);
      result.add(Venta(
        id: v.id,
        subtotal: v.subtotal,
        descuento: v.descuento,
        total: v.total,
        fecha: v.fecha,
        cliente: v.cliente,
        notas: v.notas,
        vendedorId: v.vendedorId,
        nombreVendedor: v.nombreVendedor,
        items: items,
      ));
    }
    
    return result;
  }

  Future<String> insertVenta(VentasCompanion venta, List<VentaItemsCompanion> items) async {
    return transaction(() async {
      final ventaId = await into(ventas).insert(venta);
      
      for (final item in items) {
        await into(ventaItems).insert(item.copyWith(ventaId: Value(ventaId)));
        
        // Actualizar stock
        final producto = await getProductoById(item.productoId.value);
        if (producto != null) {
          await updateStock(
            producto.id, 
            producto.stock - item.cantidad.value
          );
        }
      }
      
      // Actualizar dinero total
      await _actualizarDineroTotal(venta.total.value);
      
      return ventaId;
    });
  }

  Future<int> deleteVenta(String id) async {
    return transaction(() async {
      // Obtener la venta para restar del dinero total
      final venta = await (select(ventas)..where((v) => v.id.equals(id))).getSingleOrNull();
      if (venta != null) {
        await _actualizarDineroTotal(-venta.total);
        
        // Restaurar stock
        final items = await getVentaItems(id);
        for (final item in items) {
          final producto = await getProductoById(item.productoId);
          if (producto != null) {
            await updateStock(producto.id, producto.stock + item.cantidad);
          }
        }
      }
      
      return (delete(ventas)..where((v) => v.id.equals(id))).go();
    });
  }

  // ==================== GASTOS ====================
  
  Future<List<Gasto>> getAllGastos() => select(gastos).get();

  Future<List<Gasto>> getGastosByMes(DateTime mes, {TipoGasto? tipo}) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    var query = select(gastos)
      ..where((g) => g.mesAfectado.isBetweenValues(inicioMes, finMes));
    
    if (tipo != null) {
      query = select(gastos)
        ..where((g) => g.mesAfectado.isBetweenValues(inicioMes, finMes) 
            & g.tipo.equals(tipo == TipoGasto.fabrica ? 'fabrica' : 'personal'));
    }
    
    return query.get();
  }

  Future<int> insertGasto(GastosCompanion gasto) async {
    return transaction(() async {
      final id = await into(gastos).insert(gasto);
      
      // Si es gasto personal, restar del dinero total
      if (gasto.tipo.value == 'personal') {
        await _actualizarDineroTotal(-gasto.monto.value);
      }
      
      return id;
    });
  }

  Future<int> deleteGasto(String id) async {
    return transaction(() async {
      final gasto = await (select(gastos)..where((g) => g.id.equals(id))).getSingleOrNull();
      
      if (gasto != null && gasto.tipo == 'personal') {
        // Restaurar dinero total si era gasto personal
        await _actualizarDineroTotal(gasto.monto);
      }
      
      return (delete(gastos)..where((g) => g.id.equals(id))).go();
    });
  }

  // ==================== PRODUCCION ====================
  
  Future<List<ProduccionData>> getAllProduccion() => select(produccion).get();

  Future<List<ProduccionData>> getProduccionByMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    return (select(produccion)
      ..where((p) => p.mes.isBetweenValues(inicioMes, finMes)))
      .get();
  }

  Future<int> getTotalUnidadesProducidasMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    final result = await customSelect(
      'SELECT SUM(cantidad) as total FROM produccion WHERE mes BETWEEN ? AND ?',
      variables: [Variable<DateTime>(inicioMes), Variable<DateTime>(finMes)],
    ).getSingleOrNull();
    
    return result?.data['total'] as int? ?? 0;
  }

  Future<String> insertProduccion(ProduccionCompanion prod) async {
    return transaction(() async {
      final id = await into(produccion).insert(prod);
      
      // Actualizar stock del producto
      final producto = await getProductoById(prod.productoId.value);
      if (producto != null) {
        await updateStock(
          producto.id, 
          producto.stock + prod.cantidad.value
        );
        
        // Actualizar mes de fabricación
        await (update(productos)..where((p) => p.id.equals(producto.id)))
            .write(ProductosCompanion(mesFabricacion: prod.mes));
      }
      
      // Recalcular costo de producción
      await _recalcularCostoProduccion(prod.mes.value);
      
      return id;
    });
  }

  Future<int> deleteProduccion(String id) async {
    return transaction(() async {
      final prod = await (select(produccion)..where((p) => p.id.equals(id))).getSingleOrNull();
      
      if (prod != null) {
        // Restar stock
        final producto = await getProductoById(prod.productoId);
        if (producto != null) {
          await updateStock(producto.id, producto.stock - prod.cantidad);
        }
        
        // Recalcular costo
        await _recalcularCostoProduccion(prod.mes);
      }
      
      return (delete(produccion)..where((p) => p.id.equals(id))).go();
    });
  }

  // ==================== CONFIGURACION / DINERO TOTAL ====================
  
  Future<double> getDineroTotal() async {
    final config = await (select(configuracion)
      ..where((c) => c.clave.equals('dinero_total')))
      .getSingleOrNull();
    return double.tryParse(config?.valor ?? '0') ?? 0;
  }

  Future<void> _actualizarDineroTotal(double monto) async {
    final actual = await getDineroTotal();
    final nuevo = actual + monto;
    await into(configuracion).insertOnConflictUpdate(
      ConfiguracionCompanion(
        clave: const Value('dinero_total'),
        valor: Value(nuevo.toString()),
      ),
    );
  }

  // ==================== METRICAS ====================
  
  Future<double> getTotalVentasMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    final result = await customSelect(
      'SELECT SUM(total) as total FROM ventas WHERE fecha BETWEEN ? AND ?',
      variables: [Variable<DateTime>(inicioMes), Variable<DateTime>(finMes)],
    ).getSingleOrNull();
    
    return result?.data['total'] as double? ?? 0;
  }

  Future<double> getTotalGastosFabricaMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    final result = await customSelect(
      'SELECT SUM(monto) as total FROM gastos WHERE mes_afectado BETWEEN ? AND ? AND tipo = ?',
      variables: [
        Variable<DateTime>(inicioMes), 
        Variable<DateTime>(finMes),
        const Variable<String>('fabrica'),
      ],
    ).getSingleOrNull();
    
    return result?.data['total'] as double? ?? 0;
  }

  Future<double> getTotalGastosPersonalesMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    final result = await customSelect(
      'SELECT SUM(monto) as total FROM gastos WHERE mes_afectado BETWEEN ? AND ? AND tipo = ?',
      variables: [
        Variable<DateTime>(inicioMes), 
        Variable<DateTime>(finMes),
        const Variable<String>('personal'),
      ],
    ).getSingleOrNull();
    
    return result?.data['total'] as double? ?? 0;
  }

  Future<int> getTotalUnidadesVendidasMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    final result = await customSelect(
      '''SELECT SUM(vi.cantidad) as total 
         FROM venta_items vi 
         INNER JOIN ventas v ON vi.venta_id = v.id 
         WHERE v.fecha BETWEEN ? AND ?''',
      variables: [Variable<DateTime>(inicioMes), Variable<DateTime>(finMes)],
    ).getSingleOrNull();
    
    return result?.data['total'] as int? ?? 0;
  }

  Future<double> getCostoProduccionMes(DateTime mes) async {
    final gastosFabrica = await getTotalGastosFabricaMes(mes);
    final unidades = await getTotalUnidadesProducidasMes(mes);
    
    if (unidades == 0) return 0;
    return gastosFabrica / unidades;
  }

  Future<void> _recalcularCostoProduccion(DateTime mes) async {
    final costo = await getCostoProduccionMes(mes);
    
    // Actualizar costo en productos fabricados este mes
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    
    await (update(productos)
      ..where((p) => p.mesFabricacion.isBetweenValues(inicioMes, finMes)))
      .write(ProductosCompanion(costoProduccion: Value(costo)));
    
    // Actualizar costo en producción
    await (update(produccion)
      ..where((p) => p.mes.isBetweenValues(inicioMes, finMes)))
      .write(ProduccionCompanion(costoUnitarioCalculado: Value(costo)));
  }

  Future<MetricasDashboard> getMetricasDashboard(DateTime mes) async {
    final dineroTotal = await getDineroTotal();
    final ventasMes = await getTotalVentasMes(mes);
    final gastosFabricaMes = await getTotalGastosFabricaMes(mes);
    final gastosPersonalesMes = await getTotalGastosPersonalesMes(mes);
    final costoProductoMes = await getCostoProduccionMes(mes);
    final unidadesFabricadasMes = await getTotalUnidadesProducidasMes(mes);
    final unidadesVendidasMes = await getTotalUnidadesVendidasMes(mes);
    
    // Calcular utilidad: ventas - (costo * unidades vendidas) - gastos personales
    final costoVentas = costoProductoMes * unidadesVendidasMes;
    final utilidadMes = ventasMes - costoVentas - gastosPersonalesMes;

    return MetricasDashboard(
      dineroTotal: dineroTotal,
      ventasMes: ventasMes,
      gastosFabricaMes: gastosFabricaMes,
      gastosPersonalesMes: gastosPersonalesMes,
      costoProductoMes: costoProductoMes,
      unidadesFabricadasMes: unidadesFabricadasMes,
      unidadesVendidasMes: unidadesVendidasMes,
      utilidadMes: utilidadMes,
      mes: mes,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gestion_fabrica.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// Extensiones para conversión
extension on VentaItem {
  VentaItemsCompanion toCompanion(String ventaId) {
    return VentaItemsCompanion(
      ventaId: Value(ventaId),
      productoId: Value(productoId),
      nombreProducto: Value(nombreProducto),
      cantidad: Value(cantidad),
      precioUnitario: Value(precioUnitario),
      tipoPrecio: Value(tipoPrecio == TipoPrecio.mayorista ? 'mayorista' : 'minorista'),
      subtotal: Value(subtotal),
    );
  }
}

// Importar modelos
import '../models/models.dart';
