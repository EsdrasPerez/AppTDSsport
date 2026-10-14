import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lectura tipada de las variables de .env. Solo la anon key: nunca la service_role.
class Env {
  Env._();

  static Future<void> cargar() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _requerida('SUPABASE_URL');
  static String get supabaseAnonKey => _requerida('SUPABASE_ANON_KEY');

  static String _requerida(String nombre) {
    final valor = dotenv.env[nombre];
    if (valor == null || valor.isEmpty) {
      throw StateError('Falta la variable $nombre en el archivo .env');
    }
    return valor;
  }
}
