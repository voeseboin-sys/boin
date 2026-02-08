import 'package:freezed_annotation/freezed_annotation.dart';
import 'producto.dart';

part 'venta.freezed.dart';
part 'venta.g.dart';

enum TipoPrecio {
  mayorista,
  minorista,
}

@freezed
class VentaItem with _$VentaItem {
  const factory VentaItem({
    required String id,
    required String productoId,
    required String nombreProducto,
    required int cantidad,
    required double precioUnitario,
    required TipoPrecio tipoPrecio,
    required double subtotal,
  }) = _VentaItem;

  factory VentaItem.fromJson(Map<String, dynamic> json) =>
      _$VentaItemFromJson(json);
}

@freezed
class Venta with _$Venta {
  const factory Venta({
    required String id,
    required List<VentaItem> items,
    required double subtotal,
    required double descuento,
    required double total,
    required DateTime fecha,
    String? cliente,
    String? notas,
    required String vendedorId,
    required String nombreVendedor,
  }) = _Venta;

  factory Venta.fromJson(Map<String, dynamic> json) => _$VentaFromJson(json);
}

extension VentaExtension on Venta {
  String get totalFormateado => 'Gs. ${total.toStringAsFixed(0)}';
  String get subtotalFormateado => 'Gs. ${subtotal.toStringAsFixed(0)}';
  String get descuentoFormateado => 'Gs. ${descuento.toStringAsFixed(0)}';
  String get fechaFormateada => 
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  int get totalUnidades => items.fold(0, (sum, item) => sum + item.cantidad);
}
