// este codigo es exclusivamente para el manejo de la autenticacion

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // Iniciar sesión
  Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.session != null) {
        return null; // Éxito
      }
      return 'No se pudo iniciar sesión. Verifica tu cuenta.';
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        return 'Debes confirmar tu correo electrónico antes de entrar. Revisa tu bandeja de entrada o la carpeta de spam en $email.';
      } else if (msg.contains('invalid login credentials')) {
        return 'Correo o contraseña incorrectos. Verifica tus credenciales.';
      }
      return 'Error de autenticación: ${e.message}';
    } catch (e) {
      return 'Error de conexión. Inténtalo más tarde.';
    }
  }

  // Registrar usuario
  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'nombre': nombre.trim()},
      );

      if (response.user != null) {
        // Si Supabase requiere confirmación de email, response.session es null
        if (response.session == null) {
          return 'REQUIERE_CONFIRMACION';
        }
        return null; // Usuario creado y sesión iniciada
      }
      return 'Error desconocido al crear la cuenta.';
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('user already registered') || msg.contains('already registered')) {
        return 'Este correo ya se encuentra registrado. Intenta iniciar sesión.';
      }
      return e.message;
    } catch (e) {
      return 'Error de conexión. Inténtalo más tarde.';
    }
  }
}
