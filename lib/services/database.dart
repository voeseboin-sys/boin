import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'dart:ffi';

// Esta línea es CRÍTICA para que funcione la generación de código
part 'database.g.dart';

// --- TABLAS DE LA BASE DE DATOS ---

// Tabla de Usuarios (Para roles: Dueño / Vendedor)
class Usuarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()(); // En producción usar hash
  TextColumn get nombre => text()();
  TextColumn get rol => text()(); // 'admin' o 'vendedor'
  DateTimeColumn get fechaRegistro => dateTime().withDefault(currentDateAndTime)();
}

// Tabla de Productos
class Productos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  RealColumn get costoUnitario => real()(); // Se actualiza cada mes según producción
  RealColumn get precioMayorista => real()();
  RealColumn get precioMinorista => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  DateTimeColumn get ultimaActualizacion => dateTime().nullable()();
}

// Tabla de Producción (Registro de lo fabricado)
class Producciones extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer().references(Productos, #id)();
  IntColumn get cantidad => integer()();
  RealColumn get costoTotalLote => real()(); // Gastos de fábrica del mes / cantidad
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  IntColumn get mes => integer()(); // Para filtrar fácil
  IntColumn get anio => integer()();
}

// Tabla de Gastos
class Gastos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get descripcion => text()();
  RealColumn get monto => real()();
  TextColumn get tipo => text()(); // 'fabrica' o 'personal'
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  IntColumn get mes => integer()();
  IntColumn get anio => integer()();
}

// Tabla de Ventas
class Ventas extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get total => real()();
  RealColumn get descuento => real().withDefault(const Constant(0.0))();
  IntColumn get usuarioId => integer().references(Usuarios, #id)(); // Quién vendió
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  IntColumn get mes => integer()();
  IntColumn get anio => integer()();
}

// Detalle de Venta (Qué productos se vendieron en cada venta)
class DetalleVentas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ventaId => integer().references(Ventas, #id)();
  IntColumn get productoId => integer().references(Productos, #id)();
  IntColumn get cantidad => integer()();
  RealColumn get precioAplicado => real()(); // Precio al momento de la venta
  TextColumn get tipoPrecio => text()(); // 'mayorista' o 'minorista'
}

// --- CLASE PRINCIPAL DE LA BASE DE DATOS ---

@DriftDatabase(tables: [Usuarios, Productos, Producciones, Gastos, Ventas, DetalleVentas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  
  // Aquí puedes agregar funciones de consulta (Queries) más adelante
}

// --- CONEXIÓN CON EL ARCHIVO FÍSICO ---

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db_fabrica.sqlite'));
    
    // Configuración específica para Android/Windows
    if (Platform.isAndroid) {
       // Workaround para viejos dispositivos Android
    }
    
    return NativeDatabase.createInBackground(file);
  });
}
