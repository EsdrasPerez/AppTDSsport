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
  jornada,
  estadio,
  torneos ( * ),
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

  /// Torneos activos. El filtro se hace aquí porque la base local usa `estado_activo`
  /// y el proyecto en la nube `estado_id` (ver torneoEstaActivo).
  Future<List<Torneo>> obtenerTorneosActivos() async {
    List<Map<String, dynamic>> response;
    try {
      // En la nube el formato es un catálogo (formatos_torneo)
      response = await _db.from('torneos').select('*, formatos_torneo ( nombre )').order('nombre');
    } on PostgrestException {
      response = await _db.from('torneos').select('*').order('nombre');
    }
    return response.map(Torneo.fromMap).where((t) => t.activo).toList();
  }
}
