import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/partido.dart';

/// Columnas de partidos con sus relaciones, usadas en todas las consultas.
const selectPartido = '''
  id,
  torneo_id,
  fecha_hora,
  goles_local,
  goles_visitante,
  estado_id,
  torneos ( id, nombre ),
  local:equipos!local_id ( id, nombre, escudo_url ),
  visitante:equipos!visitante_id ( id, nombre, escudo_url )
''';

// este codigo es exclusivamente para leer partidos y torneos de supabase
class PartidosRepository {
  PartidosRepository(this._db);

  final SupabaseClient _db;

  /// Todos los partidos, o solo los de un torneo ([torneoId]) o varios ([torneoIds]).
  Future<List<Partido>> obtenerPartidos({String? torneoId, List<String>? torneoIds}) async {
    var query = _db.from('partidos').select(selectPartido);
    if (torneoId != null) query = query.eq('torneo_id', torneoId);
    if (torneoIds != null) query = query.inFilter('torneo_id', torneoIds);

    final response = await query.order('fecha_hora', ascending: true);
    return response.map(Partido.fromMap).toList();
  }

  Future<List<Torneo>> obtenerTorneosActivos() async {
    try {
      final response = await _db
          .from('torneos')
          .select('id, nombre, formato, estado_activo')
          .eq('estado_activo', true)
          .order('nombre');
      return response.map(Torneo.fromMap).toList();
    } catch (_) {
      final response = await _db
          .from('torneos')
          .select('id, nombre, formato')
          .order('nombre');
      return response.map(Torneo.fromMap).toList();
    }
  }

  Future<int> contarTorneosActivos() async {
    try {
      final response = await _db.from('torneos').select('id').eq('estado_activo', true).count(CountOption.exact);
      return response.count;
    } catch (_) {
      final response = await _db.from('torneos').select('id').count(CountOption.exact);
      return response.count;
    }
  }
}
