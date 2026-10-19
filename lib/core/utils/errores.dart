import 'package:supabase_flutter/supabase_flutter.dart';

/// Convierte cualquier excepción en un texto apto para el usuario.
/// Nunca devuelve el toString() crudo de la excepción.
String mensajeDeExcepcion(Object e) {
  if (e is MensajeUsuario) return e.mensaje;
  if (e is AuthException) return _mensajeAuth(e);
  if (e is PostgrestException) return _mensajePostgrest(e);

  final texto = e.toString();
  if (texto.contains('SocketException') ||
      texto.contains('Failed host lookup') ||
      texto.contains('ClientException') ||
      texto.contains('TimeoutException')) {
    return 'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
  }
  if (e is Exception) {
    final limpio = texto.replaceFirst('Exception: ', '').trim();
    if (limpio.isNotEmpty && !limpio.startsWith('Instance of')) {
      return limpio;
    }
  }
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

/// Excepción cuyo mensaje ya está pensado para mostrarse al usuario.
class MensajeUsuario implements Exception {
  const MensajeUsuario(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

String _mensajePostgrest(PostgrestException e) => switch (e.code) {
      // RLS: el partido ya no acepta pronósticos (o la acción no está permitida)
      '42501' => 'El partido ya comenzó o no tienes permisos para esta acción.',
      // Valor duplicado (clave única)
      '23505' => 'El registro ya existe en el sistema.',
      // raise exception dentro de una RPC: el mensaje ya está escrito para el usuario
      'P0001' => e.message,
      'PGRST116' => 'No se encontró la información solicitada.',
      _ => e.message.isNotEmpty ? e.message : 'No se pudo completar la operación. Inténtalo de nuevo.',
    };

String _mensajeAuth(AuthException e) => switch (e.code) {
      'invalid_credentials' => 'Correo o contraseña incorrectos.',
      'email_not_confirmed' => 'Debes confirmar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.',
      'user_already_exists' || 'email_exists' => 'Ya existe una cuenta con ese correo electrónico.',
      'weak_password' => 'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.',
      'over_email_send_rate_limit' || 'over_request_rate_limit' =>
        'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
      'validation_failed' => 'Revisa los datos ingresados: correo o contraseña inválidos.',
      'user_not_found' => 'No existe una cuenta con ese correo.',
      'session_expired' || 'refresh_token_not_found' => 'Tu sesión expiró. Inicia sesión de nuevo.',
      _ => _mensajeAuthPorTexto(e.message, original: e.message),
    };

/// Servidores sin código de error: se reconoce por el texto del mensaje.
String _mensajeAuthPorTexto(String msg, {String? original}) {
  final m = msg.toLowerCase();
  if (m.contains('email not confirmed')) return 'Debes confirmar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.';
  if (m.contains('invalid login credentials') || m.contains('invalid credentials')) return 'Correo o contraseña incorrectos.';
  if (m.contains('already registered') || m.contains('already in use') || m.contains('user already exists') || m.contains('email already')) {
    return 'Ya existe una cuenta con ese correo electrónico.';
  }
  if (m.contains('password') && (m.contains('least') || m.contains('short') || m.contains('characters') || m.contains('weak'))) {
    return 'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.';
  }
  if (m.contains('valid email') || m.contains('invalid email') || m.contains('email address: invalid')) {
    return 'El formato del correo electrónico no es válido.';
  }
  if (m.contains('rate limit') || m.contains('too many requests')) {
    return 'Demasiados intentos. Espera un momento y vuelve a intentarlo.';
  }
  if (m.contains('signup is disabled') || m.contains('signups not allowed')) {
    return 'El registro de nuevos usuarios está deshabilitado temporalmente.';
  }
  if (original != null && original.trim().isNotEmpty) {
    return original.trim();
  }
  return 'No se pudo completar la autenticación. Inténtalo de nuevo.';
}
