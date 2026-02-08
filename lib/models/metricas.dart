import 'package:freezed_annotation/freezed_annotation.dart';

part 'metricas.freezed.dart';
part 'metricas.g.dart';

@freezed
class MetricasDashboard with _$MetricasDashboard {
  const factory MetricasDashboard({
    required double dineroTotal,
    required double ventasMes,
    required double gastosFabricaMes,
    required double gastosPersonalesMes,
    required double costoProductoMes,
    required int unidadesFabricadasMes,
    required int unidadesVendidasMes,
    required double utilidadMes,
    required DateTime mes,
  }) = _MetricasDashboard;

  factory MetricasDashboard.fromJson(Map<String, dynamic> json) =>
      _$MetricasDashboardFromJson(json);
}

extension MetricasDashboardExtension on MetricasDashboard {
  String get dineroTotalFormateado => 'Gs. ${dineroTotal.toStringAsFixed(0)}';
  String get ventasMesFormateado => 'Gs. ${ventasMes.toStringAsFixed(0)}';
  String get gastosFabricaMesFormateado => 'Gs. ${gastosFabricaMes.toStringAsFixed(0)}';
  String get gastosPersonalesMesFormateado => 'Gs. ${gastosPersonalesMes.toStringAsFixed(0)}';
  String get costoProductoMesFormateado => 'Gs. ${costoProductoMes.toStringAsFixed(0)}';
  String get utilidadMesFormateado => 'Gs. ${utilidadMes.toStringAsFixed(0)}';
  String get mesFormateado => 
      '${mes.month.toString().padLeft(2, '0')}/${mes.year}';
  
  double get margenUtilidad {
    if (ventasMes == 0) return 0;
    return (utilidadMes / ventasMes) * 100;
  }
  
  String get margenUtilidadFormateado => '${margenUtilidad.toStringAsFixed(1)}%';
}

// Modelo para extracto mensual PDF
@freezed
class ExtractoMensual with _$ExtractoMensual {
  const factory ExtractoMensual({
    required DateTime mes,
    required double balanceInicial,
    required double totalVentas,
    required double totalGastosFabrica,
    required double totalGastosPersonales,
    required double balanceFinal,
    required int totalUnidadesProducidas,
    required int totalUnidadesVendidas,
    required List<Map<String, dynamic>> detalleVentas,
    required List<Map<String, dynamic>> detalleProduccion,
    required List<Map<String, dynamic>> detalleGastos,
  }) = _ExtractoMensual;

  factory ExtractoMensual.fromJson(Map<String, dynamic> json) =>
      _$ExtractoMensualFromJson(json);
}
