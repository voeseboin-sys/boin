class AppConstants {
  // Nombre de la app
  static const String appName = 'Gestión Fábrica';
  static const String appVersion = '1.0.0';
  
  // Moneda
  static const String currencySymbol = 'Gs.';
  static const String currencyName = 'Guaraníes';
  
  // Formatos de fecha
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MM/yyyy';
  
  // Roles
  static const String rolDueno = 'Dueño';
  static const String rolVendedor = 'Vendedor';
  
  // Categorías de gastos
  static const Map<String, String> categoriasGastoFabrica = {
    'materiaPrima': 'Materia Prima',
    'manoObra': 'Mano de Obra',
    'servicios': 'Servicios',
    'mantenimiento': 'Mantenimiento',
    'otros': 'Otros',
  };
  
  static const Map<String, String> categoriasGastoPersonal = {
    'salario': 'Salario',
    'viaticos': 'Viáticos',
    'inversion': 'Inversión',
    'otros': 'Otros',
  };
  
  // Mensajes
  static const String msgLoginSuccess = '¡Bienvenido!';
  static const String msgLoginError = 'Credenciales incorrectas';
  static const String msgLogoutSuccess = 'Sesión cerrada';
  static const String msgSaveSuccess = 'Guardado correctamente';
  static const String msgDeleteSuccess = 'Eliminado correctamente';
  static const String msgErrorGeneric = 'Ha ocurrido un error';
  static const String msgNoData = 'No hay datos disponibles';
  static const String msgConfirmDelete = '¿Estás seguro de eliminar este registro?';
  static const String msgStockInsufficient = 'Stock insuficiente';
  
  // Validaciones
  static const String valRequired = 'Este campo es obligatorio';
  static const String valEmail = 'Ingrese un email válido';
  static const String valMinLength = 'Mínimo {0} caracteres';
  static const String valPositiveNumber = 'Ingrese un número positivo';
  static const String valGreaterThanZero = 'Debe ser mayor a cero';
}

// Extensiones útiles
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  String toCurrency() {
    final value = double.tryParse(this) ?? 0;
    return '${AppConstants.currencySymbol} ${value.toStringAsFixed(0)}';
  }
}

extension DoubleExtension on double {
  String toCurrency() {
    return '${AppConstants.currencySymbol} ${toStringAsFixed(0)}';
  }
  
  String toPercentage() {
    return '${toStringAsFixed(1)}%';
  }
}

extension IntExtension on int {
  String toFormattedString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
  
  String toMonthYearString() {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[month - 1]} $year';
  }
  
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }
  
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }
}
