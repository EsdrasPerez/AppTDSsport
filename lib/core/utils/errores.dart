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
      '42501' => 'El partido ya comenzó: los pronósticos están cerrados.',
      // Valor duplicado (clave única)
      '23505' => 'Ya eres parte de esta quiniela.',
      // raise exception dentro de una RPC: el mensaje ya está escrito para el usuario
      'P0001' => e.message,
      'PGRST116' => 'No se encontró la información solicitada.',
      _ => 'No se pudo completar la operación. Inténtalo de nuevo.',
    };

String _mensajeAuth(AuthException e) => switch (e.code) {
      'invalid_credentials' => 'Correo o contraseña incorrectos.',
      'email_not_confirmed' => 'Debes confirmar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.',
      'user_already_exists' || 'email_exists' => 'Ya existe una cuenta con ese correo.',
      'weak_password' => 'La contraseña es demasiado débil.',
      'over_email_send_rate_limit' || 'over_request_rate_limit' =>
        'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
      'validation_failed' => 'Revisa los datos ingresados.',
      'user_not_found' => 'No existe una cuenta con ese correo.',
      'session_expired' || 'refresh_token_not_found' => 'Tu sesión expiró. Inicia sesión de nuevo.',
      _ => _mensajeAuthPorTexto(e.message.toLowerCase()),
    };

/// Servidores sin código de error: se reconoce por el texto del mensaje.
String _mensajeAuthPorTexto(String msg) {
  if (msg.contains('email not confirmed')) return _mensajeAuth(AuthException('', code: 'email_not_confirmed'));
  if (msg.contains('invalid login credentials')) return _mensajeAuth(AuthException('', code: 'invalid_credentials'));
  if (msg.contains('already registered')) return _mensajeAuth(AuthException('', code: 'user_already_exists'));
  return 'No se pudo completar la autenticación. Inténtalo de nuevo.';
}
