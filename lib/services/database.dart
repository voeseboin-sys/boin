import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'dart:ffi';

part 'database.g.dart';

// --- TABLAS ---

class Usuarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get nombre => text()();
  TextColumn get rol => text()(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Productos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  RealColumn get costoUnitario => real()();
  RealColumn get precioMayorista => real()();
  RealColumn get precioMinorista => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
}

class Ventas extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get total => real()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  IntColumn get usuarioId => integer().references(Usuarios, #id)();
}

// Tabla intermedia para guardar qué productos se vendieron en cada venta
class VentaItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ventaId => integer().references(Ventas, #id)();
  IntColumn get productoId => integer().references(Productos, #id)();
  IntColumn get cantidad => integer()();
  RealColumn get precioAplicado => real()();
}

class Gastos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get descripcion => text()();
  RealColumn get monto => real()();
  TextColumn get tipo => text()(); // 'fabrica' o 'personal'
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
}

class Produccion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer().references(Productos, #id)();
  IntColumn get cantidad => integer()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
}

// --- BASE DE DATOS PRINCIPAL ---

@DriftDatabase(tables: [Usuarios, Productos, Ventas, VentaItems, Gastos, Produccion])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // === MÉTODOS QUE FALTABAN (SOLUCIÓN A TUS ERRORES) ===

  // 1. Usuarios
  Future<Usuario?> login(String email, String password) =>
      (select(usuarios)..where((u) => u.email.equals(email) & u.password.equals(password)))
          .getSingleOrNull();

  // 2. Productos
  Future<List<Producto>> getAllProductos() => select(productos).get();
  Future<int> insertProducto(ProductosCompanion entry) => into(productos).insert(entry);
  Future updateProducto(ProductosCompanion entry) => update(productos).replace(entry);
  Future deleteProducto(int id) => (delete(productos)..where((p) => p.id.equals(id))).go();

  // 3. Ventas
  Future<List<Venta>> getAllVentas() => select(ventas).get();
  
  // Transacción compleja: Crea la venta y descuenta stock automáticamente
  Future<void> insertVenta(VentasCompanion venta, List<VentaItemsCompanion> items) {
    return transaction(() async {
      final ventaId = await into(ventas).insert(venta);
      for (var item in items) {
        await into(ventaItems).insert(item.copyWith(ventaId: Value(ventaId)));
        // Descontar Stock (Query SQL directa para restar)
        customUpdate(
          'UPDATE productos SET stock = stock - ? WHERE id = ?',
          variables: [Variable(item.cantidad.value), Variable(item.productoId.value)],
          updates: {productos},
        );
      }
    });
  }
  Future deleteVenta(int id) => (delete(ventas)..where((v) => v.id.equals(id))).go();

  // 4. Gastos
  Future<List<Gasto>> getAllGastos() => select(gastos).get();
  Future<int> insertGasto(GastosCompanion entry) => into(gastos).insert(entry);
  Future deleteGasto(int id) => (delete(gastos)..where((g) => g.id.equals(id))).go();

  // 5. Producción
  Future<List<ProduccionData>> getAllProduccion() => select(produccion).get();
  Future<int> insertProduccion(ProduccionCompanion entry) {
    return transaction(() async {
      await into(produccion).insert(entry);
      // Aumentar Stock
      customUpdate(
        'UPDATE productos SET stock = stock + ? WHERE id = ?',
        variables: [Variable(entry.cantidad.value), Variable(entry.productoId.value)],
        updates: {productos},
      );
      return 1;
    });
  }
  Future deleteProduccion(int id) => (delete(produccion)..where((p) => p.id.equals(id))).go();

  // 6. Métricas Dashboard
  Future<List<Venta>> getVentasByMes(DateTime mes) {
    final start = DateTime(mes.year, mes.month, 1);
    final end = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    return (select(ventas)..where((t) => t.fecha.isBetween(start, end))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db_fabrica.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
