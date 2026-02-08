import 'package:freezed_annotation/freezed_annotation.dart';

part 'produccion.freezed.dart';
part 'produccion.g.dart';

@freezed
class Produccion with _$Produccion {
  const factory Produccion({
    required String id,
    required String productoId,
    required String nombreProducto,
    required int cantidad,
    required DateTime fecha,
    required DateTime mes,
    double? costoUnitarioCalculado,
    String? notas,
    DateTime? createdAt,
  }) = _Produccion;

  factory Produccion.fromJson(Map<String, dynamic> json) =>
      _$ProduccionFromJson(json);
}

extension ProduccionExtension on Produccion {
  String get fechaFormateada => 
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  String get mesFormateado => 
      '${mes.month.toString().padLeft(2, '0')}/${mes.year}';
  String get costoUnitarioFormateado => 
      costoUnitarioCalculado != null 
          ? 'Gs. ${costoUnitarioCalculado!.toStringAsFixed(0)}' 
          : 'Pendiente';
}

// Modelo para resumen mensual de producción
@freezed
class ResumenProduccionMensual with _$ResumenProduccionMensual {
  const factory ResumenProduccionMensual({
    required DateTime mes,
    required int totalUnidades,
    required double gastosFabrica,
    required double costoUnitarioPromedio,
    required Map<String, int> unidadesPorProducto,
  }) = _ResumenProduccionMensual;

  factory ResumenProduccionMensual.fromJson(Map<String, dynamic> json) =>
      _$ResumenProduccionMensualFromJson(json);
}
