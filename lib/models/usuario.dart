import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario.freezed.dart';
part 'usuario.g.dart';

enum RolUsuario {
  dueno,
  vendedor,
}

@freezed
class Usuario with _$Usuario {
  const factory Usuario({
    required String id,
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
    DateTime? createdAt,
  }) = _Usuario;

  factory Usuario.fromJson(Map<String, dynamic> json) =>
      _$UsuarioFromJson(json);
}

// Usuario por defecto para demo
const usuarioDuenoDemo = Usuario(
  id: '1',
  nombre: 'Administrador',
  email: 'admin@fabrica.com',
  password: 'admin123',
  rol: RolUsuario.dueno,
);

const usuarioVendedorDemo = Usuario(
  id: '2',
  nombre: 'Vendedor',
  email: 'vendedor@fabrica.com',
  password: 'vendedor123',
  rol: RolUsuario.vendedor,
);
