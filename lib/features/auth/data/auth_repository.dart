// este codigo es exclusivamente para el manejo de la autenticacion

import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de un registro: con sesión (entra directo) o pendiente de confirmar el correo.
enum ResultadoRegistro { conSesion, confirmarCorreo }

// Lanza excepciones; la UI las convierte en texto con mensajeDeExcepcion().
class AuthRepository {
  AuthRepository(this._db);

  final SupabaseClient _db;

  /// La contraseña NO se recorta: los espacios son parte de ella.
  Future<void> iniciarSesion({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// El perfil se crea con el trigger handle_new_user a partir de data.nombre.
  Future<ResultadoRegistro> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final response = await _db.auth.signUp(email: email.trim(), password: password, data: {'nombre': nombre.trim()});
    // Con "confirmar correo" activo en Supabase, signUp devuelve usuario SIN sesión.
    return response.session != null ? ResultadoRegistro.conSesion : ResultadoRegistro.confirmarCorreo;
  }

  Future<void> recuperarContrasena(String email) async {
    await _db.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> cerrarSesion() => _db.auth.signOut();
}
