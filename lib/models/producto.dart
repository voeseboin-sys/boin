import 'package:freezed_annotation/freezed_annotation.dart';

part 'producto.freezed.dart';
part 'producto.g.dart';

@freezed
class Producto with _$Producto {
  const factory Producto({
    required String id,
    required String nombre,
    String? descripcion,
    required double precioMayorista,
    required double precioMinorista,
    required int stock,
    required double costoProduccion,
    required DateTime mesFabricacion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Producto;

  factory Producto.fromJson(Map<String, dynamic> json) =>
      _$ProductoFromJson(json);
}

extension ProductoExtension on Producto {
  String get precioMayoristaFormateado => 'Gs. ${precioMayorista.toStringAsFixed(0)}';
  String get precioMinoristaFormateado => 'Gs. ${precioMinorista.toStringAsFixed(0)}';
  String get costoProduccionFormateado => 'Gs. ${costoProduccion.toStringAsFixed(0)}';
  String get mesFabricacionFormateado => 
      '${mesFabricacion.month.toString().padLeft(2, '0')}/${mesFabricacion.year}';
}
