import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/perfil.dart';

// este codigo es exclusivamente para leer el perfil del usuario
// (la edición del perfil vive en perfil_screen.dart y no se toca)
class PerfilRepository {
  PerfilRepository(this._db);

  final SupabaseClient _db;

  Future<Perfil?> obtenerPerfil(String usuarioId) async {
    // select('*') para no fallar si la columna es_admin todavía no existe
    final response = await _db.from('perfiles').select('*').eq('id', usuarioId).maybeSingle();
    return response == null ? null : Perfil.fromMap(response);
  }
}
