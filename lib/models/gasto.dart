import 'package:freezed_annotation/freezed_annotation.dart';

part 'gasto.freezed.dart';
part 'gasto.g.dart';

enum TipoGasto {
  fabrica,
  personal,
}

enum CategoriaGastoFabrica {
  materiaPrima,
  manoObra,
  servicios,
  mantenimiento,
  otros,
}

enum CategoriaGastoPersonal {
  salario,
  viaticos,
  inversion,
  otros,
}

@freezed
class Gasto with _$Gasto {
  const factory Gasto({
    required String id,
    required String descripcion,
    required double monto,
    required TipoGasto tipo,
    required String categoria,
    required DateTime fecha,
    required DateTime mesAfectado,
    String? comprobante,
    String? notas,
    DateTime? createdAt,
  }) = _Gasto;

  factory Gasto.fromJson(Map<String, dynamic> json) => _$GastoFromJson(json);
}

extension GastoExtension on Gasto {
  String get montoFormateado => 'Gs. ${monto.toStringAsFixed(0)}';
  String get fechaFormateada => 
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  String get mesAfectadoFormateado => 
      '${mesAfectado.month.toString().padLeft(2, '0')}/${mesAfectado.year}';
  
  String get nombreCategoria {
    switch (categoria) {
      case 'materiaPrima':
        return 'Materia Prima';
      case 'manoObra':
        return 'Mano de Obra';
      case 'servicios':
        return 'Servicios';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'salario':
        return 'Salario';
      case 'viaticos':
        return 'Viáticos';
      case 'inversion':
        return 'Inversión';
      default:
        return 'Otros';
    }
  }
  
  String get tipoTexto {
    switch (tipo) {
      case TipoGasto.fabrica:
        return 'Gasto de Fábrica';
      case TipoGasto.personal:
        return 'Gasto Personal';
    }
  }
}
