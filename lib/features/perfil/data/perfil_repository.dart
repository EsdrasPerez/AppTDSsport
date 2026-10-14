import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/perfil.dart';

// este codigo es exclusivamente para leer y editar el perfil del usuario
class PerfilRepository {
  PerfilRepository(this._db);

  final SupabaseClient _db;

  Future<Perfil?> obtenerPerfil(String usuarioId) async {
    final response = await obtenerDatosEditables(usuarioId);
    return response == null ? null : Perfil.fromMap(response);
  }

  /// Fila completa de perfiles (nombre, teléfono, fecha de nacimiento…) para la pantalla "Editar mi perfil".
  /// select('*'): es_admin o fecha_nacimiento pueden no existir según el esquema.
  Future<Map<String, dynamic>?> obtenerDatosEditables(String usuarioId) =>
      _db.from('perfiles').select('*').eq('id', usuarioId).maybeSingle();

  /// [fechaNacimiento] solo se envía si [conFechaNacimiento] (el proyecto en la nube no tiene la columna).
  Future<void> actualizarPerfil({
    required String usuarioId,
    required String nombre,
    required String telefono,
    required DateTime? fechaNacimiento,
    required bool conFechaNacimiento,
  }) async {
    final fecha = fechaNacimiento == null
        ? null
        : '${fechaNacimiento.year}-${fechaNacimiento.month.toString().padLeft(2, '0')}-'
            '${fechaNacimiento.day.toString().padLeft(2, '0')}';
    await _db.from('perfiles').update({
      'nombre': nombre,
      'telefono': telefono,
      if (conFechaNacimiento) 'fecha_nacimiento': fecha,
    }).eq('id', usuarioId);
  }
}
