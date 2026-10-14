import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/errores.dart';
import '../../partidos/domain/partido.dart';

// este codigo es exclusivamente para la administración (solo es_admin; lo exige la RLS)
class AdminRepository {
  AdminRepository(this._db);

  final SupabaseClient _db;

  static const bucketEscudos = 'escudos';

  /// La RLS rechaza (42501) a quien no es admin: se traduce a un mensaje propio de esta sección.
  Future<T> _conPermiso<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const MensajeUsuario('No tienes permiso para hacer cambios. Solo los administradores pueden hacerlo.');
      }
      rethrow;
    }
  }

  // --------------------------------------------------------------------------- Torneos

  Future<List<Torneo>> obtenerTorneos() async {
    try {
      final r = await _db.from('torneos').select('id, nombre, formato, estado_activo').order('creado_en', ascending: false);
      return r.map(Torneo.fromMap).toList();
    } catch (_) {
      final r = await _db.from('torneos').select('id, nombre, formato').order('creado_en', ascending: false);
      return r.map(Torneo.fromMap).toList();
    }
  }

  Future<void> guardarTorneo({String? id, required String nombre, required String formato, required bool activo}) =>
      _conPermiso(() async {
        final datos = {'nombre': nombre, 'formato': formato, 'estado_activo': activo};
        id == null ? await _db.from('torneos').insert(datos) : await _db.from('torneos').update(datos).eq('id', id);
      });

  // --------------------------------------------------------------------------- Equipos

  Future<List<Equipo>> obtenerEquipos() async {
    final r = await _db.from('equipos').select('id, nombre, escudo_url').order('nombre');
    return r.map((m) => Equipo.fromMap(m)).toList();
  }

  Future<void> guardarEquipo({String? id, required String nombre, String? escudoUrl}) => _conPermiso(() async {
        final datos = {'nombre': nombre, 'escudo_url': escudoUrl};
        id == null ? await _db.from('equipos').insert(datos) : await _db.from('equipos').update(datos).eq('id', id);
      });

  /// Sube la imagen al bucket público "escudos" y devuelve su URL pública.
  Future<String> subirEscudo(Uint8List bytes, String nombreArchivo) => _conPermiso(() async {
        final extension = nombreArchivo.contains('.') ? nombreArchivo.split('.').last.toLowerCase() : 'png';
        final ruta = '${DateTime.now().millisecondsSinceEpoch}.$extension';
        await _db.storage.from(bucketEscudos).uploadBinary(
              ruta,
              bytes,
              fileOptions: FileOptions(contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}', upsert: true),
            );
        return _db.storage.from(bucketEscudos).getPublicUrl(ruta);
      });

  // --------------------------------------------------------------------------- Partidos

  Future<void> crearPartido({
    required String torneoId,
    required String localId,
    required String visitanteId,
    required DateTime fecha,
  }) =>
      _conPermiso(() async {
        if (localId == visitanteId) throw const MensajeUsuario('El local y el visitante deben ser distintos.');
        if (!fecha.isAfter(DateTime.now())) throw const MensajeUsuario('La fecha debe ser futura.');
        await _db.from('partidos').insert({
          'torneo_id': torneoId,
          'local_id': localId,
          'visitante_id': visitanteId,
          'fecha_hora': fecha.toUtc().toIso8601String(),
          'estado_id': EstadoPartido.futuro.id,
        });
      });

  /// Cambia estado y marcador. Al pasar a FINALIZADO, la función calcular_puntos_partido()
  /// de la base calcula los puntos; la app no calcula nada.
  Future<void> actualizarPartido({
    required String partidoId,
    required EstadoPartido estado,
    int? golesLocal,
    int? golesVisitante,
  }) =>
      _conPermiso(() async {
        if (estado == EstadoPartido.finalizado && (golesLocal == null || golesVisitante == null)) {
          throw const MensajeUsuario('Para finalizar el partido captura los goles de ambos equipos.');
        }
        await _db.from('partidos').update({
          'estado_id': estado.id,
          'goles_local': golesLocal,
          'goles_visitante': golesVisitante,
        }).eq('id', partidoId);
      });
}
