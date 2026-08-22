// este codigo es exclusivamente para el manejo de la autenticacion

import 'package:supabase_flutter/supabase_flutter.dart';

//esta es una clase para el manejo de la autenticacion
class AuthRepository {
  final _supabase = Supabase.instance.client;

  // esta parte de codigo es para iniciar sesion
  Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        return null;
      }
      return 'Error desconocido al iniciar sesión.';
    } on AuthException catch (_) {
      return 'Error: Correo o contraseña incorrectos.';
    } catch (e) {
      return 'Error de conexión. Inténtalo más tarde.';
    }
  }

  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': nombre},
      );

      if (response.user != null) {
        return null;
      }
      return 'Error desconocido al crear la cuenta.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de conexión. Inténtalo más tarde.';
    }
  }
}
