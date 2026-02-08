import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/database.dart';

// Provider de la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Estado de autenticación
class AuthState {
  final Usuario? usuario;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.usuario,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    Usuario? usuario,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => usuario != null;
  bool get isDueno => usuario?.rol == RolUsuario.dueno;
  bool get isVendedor => usuario?.rol == RolUsuario.vendedor;
}

// Notifier de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AppDatabase _db;

  AuthNotifier(this._db) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final usuario = await _db.login(email, password);
      
      if (usuario != null) {
        state = state.copyWith(
          usuario: Usuario(
            id: usuario.id,
            nombre: usuario.nombre,
            email: usuario.email,
            password: '', // No guardar password en memoria
            rol: usuario.rol == 'dueno' ? RolUsuario.dueno : RolUsuario.vendedor,
            createdAt: usuario.createdAt,
          ),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Credenciales incorrectas',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al iniciar sesión: $e',
      );
    }
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(databaseProvider);
  return AuthNotifier(db);
});
