import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/rpc_respaldo.dart';
import '../../../core/utils/errores.dart';
import '../../partidos/data/partidos_repository.dart';
import '../../partidos/domain/partido.dart';
import '../../perfil/domain/perfil.dart';
import '../domain/posiciones.dart';
import '../domain/quiniela_models.dart';

/// Pronóstico reciente del usuario con su partido (actividad del dashboard).
class PronosticoReciente {
  const PronosticoReciente({required this.partido, required this.pronostico});

  final Partido partido;
  final Pronostico pronostico;
}

// este codigo es exclusivamente para el manejo de quinielas y pronósticos
class QuinielasRepository {
  QuinielasRepository(this._db, this._partidos);

  final SupabaseClient _db;
  final PartidosRepository _partidos;

  String get _usuarioId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const MensajeUsuario('Tu sesión expiró. Inicia sesión de nuevo.');
    return id;
  }

  // ---------------------------------------------------------------------------
  // Crear / unirse
  // ---------------------------------------------------------------------------

  /// Crea una quiniela del torneo con el usuario actual como creador y participante.
  /// Solo existen quinielas por torneo; se prueba cada firma de crear_quiniela según el esquema.
  Future<({String id, String codigo})> crearQuiniela({
    required String torneoId,
    required String nombre,
    required int limiteUsuarios,
  }) {
    _usuarioId;
    ({String id, String codigo}) leer(dynamic r) => (id: r['id'].toString(), codigo: r['codigo_acceso'] as String);

    return conRespaldo(
      // Firma de 5 parámetros (migración 03), todo en una transacción
      () async => leer(await _db.rpc('crear_quiniela', params: {
            'p_tipo': 'TORNEO',
            'p_torneo': torneoId,
            'p_partido': null,
            'p_nombre': nombre,
            'p_limite': limiteUsuarios,
          })),
      () => conRespaldo(
        // Firma del proyecto en la nube
        () async => _leerCreada(await _db.rpc('crear_quiniela', params: {
              'p_nombre': nombre,
              'p_torneo_id': torneoId,
              'p_limite': limiteUsuarios,
            })),
        () => conRespaldo(
          () async => leer(await _db.rpc('crear_quiniela', params: {
                'p_torneo': torneoId,
                'p_nombre': nombre,
                'p_limite': limiteUsuarios,
              })),
          () => _crearQuinielaSinRpc(torneoId: torneoId, nombre: nombre, limiteUsuarios: limiteUsuarios),
        ),
      ),
    );
  }

  /// crear_quiniela de la nube puede devolver solo el código (texto) o un objeto.
  Future<({String id, String codigo})> _leerCreada(dynamic res) async {
    if (res is Map) {
      if (res['success'] == false) {
        throw MensajeUsuario((res['mensaje'] ?? res['error'] ?? 'No se pudo crear la quiniela.').toString());
      }
      final codigo = (res['codigo_acceso'] ?? res['codigo']).toString();
      final id = res['quiniela_id'] ?? res['id'];
      if (id != null) return (id: id.toString(), codigo: codigo);
      return _idPorCodigo(codigo);
    }
    return _idPorCodigo(res.toString().trim());
  }

  Future<({String id, String codigo})> _idPorCodigo(String codigo) async {
    final q = await _db.from('quinielas').select('id').eq('codigo_acceso', codigo).single();
    return (id: q['id'].toString(), codigo: codigo);
  }

  /// Camino anterior (dos llamadas, no atómico). Solo si no hay ninguna migración aplicada.
  Future<({String id, String codigo})> _crearQuinielaSinRpc({
    required String torneoId,
    required String nombre,
    required int limiteUsuarios,
  }) async {
    final userId = _usuarioId;
    for (var intento = 0; intento < 5; intento++) {
      final Map<String, dynamic> quiniela;
      try {
        quiniela = await _db
            .from('quinielas')
            .insert({
              'torneo_id': torneoId,
              'creador_id': userId,
              'nombre': nombre,
              'codigo_acceso': generarCodigo(),
              'limite_usuarios': limiteUsuarios,
            })
            .select('id, codigo_acceso')
            .single();
      } on PostgrestException catch (e) {
        if (e.code == '23505') continue; // código repetido: probar otro
        rethrow;
      }
      await unirse(quiniela['codigo_acceso'] as String);
      return (id: quiniela['id'].toString(), codigo: quiniela['codigo_acceso'] as String);
    }
    throw const MensajeUsuario('No se pudo generar un código único. Intenta de nuevo.');
  }

  /// Une al usuario actual a la quiniela con ese código (RPC join_quiniela). Devuelve el id.
  Future<String> unirse(String codigo) async {
    _usuarioId;
    final res = await _db.rpc('join_quiniela', params: {'codigo_ingresado': codigo.trim().toUpperCase()});
    if (res is Map && res['success'] == true) return res['quiniela_id'].toString();
    throw MensajeUsuario((res is Map ? (res['error'] ?? res['mensaje'] ?? res['message'])?.toString() : null) ?? 'No se pudo unir a la quiniela.');
  }

  /// Alfabeto sin 0/O ni 1/I (join_quiniela compara en mayúsculas).
  static const alfabetoCodigo = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const largoCodigo = 8;

  static String generarCodigo() {
    final rnd = Random.secure();
    return List.generate(largoCodigo, (_) => alfabetoCodigo[rnd.nextInt(alfabetoCodigo.length)]).join();
  }

  // ---------------------------------------------------------------------------
  // Lecturas
  // ---------------------------------------------------------------------------

  /// Todas las quinielas del usuario (activas y finalizadas), más reciente primero.
  /// 4 consultas en total: mis quinielas, sus miembros, partidos y mis pronósticos.
  Future<List<ResumenQuiniela>> obtenerMisQuinielas(String usuarioId) async {
    // `*`: unido_en / creado_en existen en la base local pero no en el proyecto en la nube
    final mias = await _db
        .from('quiniela_usuarios')
        .select('*, quinielas ( *, torneos ( * ) )')
        .eq('usuario_id', usuarioId);
    if (mias.isEmpty) return [];
    DateTime fechaDe(Map m) => DateTime.tryParse(m['unido_en'] ?? m['quinielas']['creado_en'] ?? '') ?? DateTime(0);
    mias.sort((a, b) => fechaDe(b).compareTo(fechaDe(a)));

    final quinielaIds = [for (final m in mias) m['quinielas']['id'].toString()];
    final torneoIds = {for (final m in mias) m['quinielas']['torneo_id'].toString()}.toList();

    final (miembros, partidos, pronosticos) = await (
      _db.from('quiniela_usuarios').select('quiniela_id, puntos_totales').inFilter('quiniela_id', quinielaIds),
      _partidos.obtenerPartidos(torneoIds: torneoIds),
      _db.from('pronosticos').select('*').eq('usuario_id', usuarioId).inFilter('quiniela_id', quinielaIds),
    ).wait;

    return mias.map((m) {
      final q = m['quinielas'];
      final id = q['id'].toString();
      final torneoId = q['torneo_id'].toString();

      return ResumenQuiniela(
        id: id,
        nombre: q['nombre'],
        codigoAcceso: q['codigo_acceso'],
        limiteUsuarios: q['limite_usuarios'],
        creadoEn: DateTime.tryParse(q['creado_en'] ?? '')?.toLocal(),
        unidoEn: DateTime.tryParse(m['unido_en'] ?? '')?.toLocal(),
        creadorId: q['creador_id'].toString(),
        torneoId: torneoId,
        torneoNombre: q['torneos']?['nombre'] ?? 'Torneo',
        torneoActivo: torneoEstaActivo(q['torneos']),
        puntos: m['puntos_totales'] as int? ?? 0,
        puntosDeTodos: [
          for (final r in miembros)
            if (r['quiniela_id'].toString() == id) r['puntos_totales'] as int? ?? 0,
        ],
        partidos: partidos.where((p) => p.torneoId == torneoId).toList(),
        pronosticos: {
          for (final r in pronosticos)
            if (r['quiniela_id'].toString() == id) r['partido_id'].toString(): Pronostico.fromMap(r),
        },
      );
    }).toList();
  }

  /// Quiniela + sus partidos + posiciones + mis pronósticos, en paralelo.
  Future<DetalleQuiniela> obtenerDetalle(String quinielaId, String? miId) async {
    final quiniela = QuinielaDetalle.fromMap(
      await _db.from('quinielas').select('*, torneos ( * )').eq('id', quinielaId).single(),
    );

    final (partidos, posiciones, pronosticos) = await (
      _partidos.obtenerPartidos(torneoId: quiniela.torneoId),
      obtenerPosiciones(quinielaId),
      miId == null ? Future.value(<String, Pronostico>{}) : obtenerPronosticos(quinielaId, miId),
    ).wait;

    return DetalleQuiniela(
      quiniela: quiniela,
      partidos: partidos,
      posiciones: posiciones,
      misPronosticos: pronosticos,
      miId: miId,
    );
  }

  /// Tabla de posiciones ordenada por puntos_totales (mayor a menor), con empates compartidos.
  Future<List<Posicion>> obtenerPosiciones(String quinielaId) => conRespaldo(
        () async {
          // Vista v_posiciones (migraciones 02/03): el lugar con empates lo calcula la base con RANK()
          final r = await _db.from('v_posiciones').select('*').eq('quiniela_id', quinielaId).order('lugar');
          return [
            for (final p in r)
              Posicion(
                lugar: p['lugar'] as int,
                usuarioId: p['usuario_id'].toString(),
                nombre: p['nombre'] ?? 'Usuario',
                puntos: p['puntos_totales'] as int? ?? 0,
                esPro: p['es_pro'] ?? false,
                plan: _plan(p),
              ),
          ];
        },
        () => _obtenerPosicionesSinVista(quinielaId),
      );

  static PlanUsuario _plan(Map<String, dynamic> m) {
    final plan = PlanUsuario.desdeCodigo(m['plan'] as String?);
    return (plan == PlanUsuario.gratis && (m['es_pro'] ?? false) == true) ? PlanUsuario.pro : plan;
  }

  Future<List<Posicion>> _obtenerPosicionesSinVista(String quinielaId) async {
    final response = await _db
        .from('quiniela_usuarios')
        .select('usuario_id, puntos_totales, perfiles ( * )')
        .eq('quiniela_id', quinielaId)
        .order('puntos_totales', ascending: false);

    final puntos = [for (final r in response) r['puntos_totales'] as int? ?? 0];
    final lugares = calcularLugares(puntos);

    return [
      for (var i = 0; i < response.length; i++)
        Posicion(
          lugar: lugares[i],
          usuarioId: response[i]['usuario_id'].toString(),
          nombre: response[i]['perfiles']?['nombre'] ?? 'Usuario',
          puntos: puntos[i],
          esPro: response[i]['perfiles']?['es_pro'] ?? false,
          plan: _plan(Map<String, dynamic>.from(response[i]['perfiles'] ?? {})),
        ),
    ];
  }

  /// Pronósticos de un usuario en la quiniela, por partido.
  /// RLS: los propios, o los de otros miembros si el usuario es PRO vigente (migración 03).
  Future<Map<String, Pronostico>> obtenerPronosticos(String quinielaId, String usuarioId) async {
    final response =
        await _db.from('pronosticos').select('*').eq('quiniela_id', quinielaId).eq('usuario_id', usuarioId);

    return {for (final r in response) r['partido_id'].toString(): Pronostico.fromMap(r)};
  }

  /// Pronósticos de TODOS los participantes para un partido de una quiniela, por usuario.
  /// La RLS decide qué se devuelve: un gratis solo recibe el suyo.
  Future<Map<String, Pronostico>> obtenerPronosticosDePartido(String quinielaId, String partidoId) async {
    final response =
        await _db.from('pronosticos').select('*').eq('quiniela_id', quinielaId).eq('partido_id', partidoId);

    return {for (final r in response) r['usuario_id'].toString(): Pronostico.fromMap(r)};
  }

  /// Últimos pronósticos del usuario con su partido (actividad reciente).
  Future<List<PronosticoReciente>> obtenerPronosticosRecientes(String usuarioId, {int limite = 5}) async {
    // Sin .order('actualizado_en'): esa columna no existe en el proyecto en la nube; se ordena aquí
    final response =
        await _db.from('pronosticos').select('*, partidos ( $selectPartido )').eq('usuario_id', usuarioId);

    final recientes = [
      for (final r in response)
        PronosticoReciente(partido: Partido.fromMap(r['partidos']), pronostico: Pronostico.fromMap(r)),
    ];
    DateTime fecha(PronosticoReciente p) => p.pronostico.actualizadoEn ?? p.partido.fecha ?? DateTime(0);
    recientes.sort((a, b) => fecha(b).compareTo(fecha(a)));
    return recientes.take(limite).toList();
  }

  // ---------------------------------------------------------------------------
  // Escrituras
  // ---------------------------------------------------------------------------

  /// RPC guardar_pronostico: valida membresía, que el partido sea de la quiniela, estado FUTURO,
  /// hora de inicio y goles 0..99. Nunca envía puntos.
  Future<void> guardarPronostico({
    required String quinielaId,
    required String partidoId,
    required int golesLocal,
    required int golesVisitante,
  }) {
    _usuarioId;
    return conRespaldo(
      () => _db.rpc('guardar_pronostico', params: {
        'p_quiniela': quinielaId,
        'p_partido': partidoId,
        'p_local': golesLocal,
        'p_visitante': golesVisitante,
      }),
      () => _guardarPronosticoSinRpc(
          quinielaId: quinielaId, partidoId: partidoId, golesLocal: golesLocal, golesVisitante: golesVisitante),
    );
  }

  /// Camino anterior (upsert directo). Solo si la migración 02 no está aplicada.
  Future<void> _guardarPronosticoSinRpc({
    required String quinielaId,
    required String partidoId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    final datos = {
      'usuario_id': _usuarioId,
      'partido_id': partidoId,
      'quiniela_id': quinielaId,
      'pred_goles_local': golesLocal,
      'pred_goles_visitante': golesVisitante,
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await _db.from('pronosticos').upsert(datos, onConflict: 'usuario_id,partido_id,quiniela_id');
    } on PostgrestException catch (e) {
      // El proyecto en la nube no tiene la columna actualizado_en
      if (e.code != 'PGRST204' && e.code != '42703') rethrow;
      datos.remove('actualizado_en');
      await _db.from('pronosticos').upsert(datos, onConflict: 'usuario_id,partido_id,quiniela_id');
    }
  }
}
