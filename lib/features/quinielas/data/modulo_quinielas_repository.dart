import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/torneo_model.dart';
import '../models/quiniela_model.dart';

class CrearQuinielaResult {
  final bool success;
  final String? codigo;
  final String? error;
  final String? quinielaId;

  CrearQuinielaResult({
    required this.success,
    this.codigo,
    this.error,
    this.quinielaId,
  });
}

class JoinQuinielaResult {
  final bool success;
  final String? mensaje;
  final String? quinielaId;

  JoinQuinielaResult({
    required this.success,
    this.mensaje,
    this.quinielaId,
  });
}

/// Repositorio del módulo de quinielas (pantallas QuinielasScreen, CrearQuinielaView, UnirseQuinielaView).
class ModuloQuinielasRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la lista de torneos activos para el selector
  Future<List<TorneoModel>> getTorneosActivos() async {
    try {
      // Buscamos torneos en estado PRÓXIMO (1) o EN CURSO (2)
      final response = await _supabase
          .from('torneos')
          .select('id, nombre, estado_id, fecha_inicio, fecha_fin')
          .inFilter('estado_id', [1, 2])
          .order('nombre');

      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return data.map((json) => TorneoModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      // Si no hay con 1 o 2, traemos todos los que no estén finalizados (3)
      final fallback = await _supabase
          .from('torneos')
          .select('id, nombre, estado_id, fecha_inicio, fecha_fin')
          .neq('estado_id', 3)
          .order('nombre');

      return (fallback as List<dynamic>)
          .map((json) => TorneoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Intento final general sin filtros para tolerancia a fallos
      try {
        final all = await _supabase
            .from('torneos')
            .select('id, nombre, estado_id')
            .order('nombre');
        return (all as List<dynamic>)
            .map((json) => TorneoModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (innerError) {
        throw Exception('Error al cargar torneos activos: $innerError');
      }
    }
  }

  /// Crea una nueva quiniela invocando la función RPC `crear_quiniela`
  Future<CrearQuinielaResult> crearQuiniela({
    required String nombre,
    required String torneoId,
    required int limite,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return CrearQuinielaResult(
          success: false,
          error: 'Debes iniciar sesión para crear una quiniela.',
        );
      }

      final res = await _supabase.rpc('crear_quiniela', params: {
        'p_nombre': nombre.trim(),
        'p_torneo_id': torneoId,
        'p_limite': limite,
      });

      if (res == null) {
        return CrearQuinielaResult(
          success: false,
          error: 'No se recibió respuesta del servidor.',
        );
      }

      if (res is String) {
        return CrearQuinielaResult(
          success: true,
          codigo: res.trim(),
        );
      }

      if (res is Map) {
        if (res['success'] == false) {
          final errorMsg = res['mensaje'] ?? res['error'] ?? res['message'] ?? 'Error desconocido al crear quiniela';
          return CrearQuinielaResult(
            success: false,
            error: errorMsg.toString(),
          );
        }

        // Extraer el código generado en diferentes formatos posibles
        final codigo = res['codigo'] ??
            res['codigo_acceso'] ??
            res['codigo_invitacion'] ??
            res['codigo_aleatorio'] ??
            res['codigo_generado'] ??
            res['data']?.toString();

        final quinielaId = res['quiniela_id']?.toString() ?? res['id']?.toString();

        return CrearQuinielaResult(
          success: true,
          codigo: codigo?.toString() ?? 'GENERADO',
          quinielaId: quinielaId,
        );
      }

      return CrearQuinielaResult(
        success: true,
        codigo: res.toString(),
      );
    } on PostgrestException catch (e) {
      return CrearQuinielaResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      return CrearQuinielaResult(
        success: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  /// Se une a una quiniela existente mediante el RPC `join_quiniela`
  Future<JoinQuinielaResult> unirseAQuiniela({
    required String codigoIngresado,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return JoinQuinielaResult(
          success: false,
          mensaje: 'Debes iniciar sesión para unirte a una quiniela.',
        );
      }

      final codigoLimpio = codigoIngresado.trim().toUpperCase();
      if (codigoLimpio.isEmpty) {
        return JoinQuinielaResult(
          success: false,
          mensaje: 'Por favor ingresa un código de invitación válido.',
        );
      }

      final res = await _supabase.rpc('join_quiniela', params: {
        'codigo_ingresado': codigoLimpio,
      });

      if (res == null) {
        return JoinQuinielaResult(
          success: false,
          mensaje: 'No se recibió respuesta del servidor.',
        );
      }

      if (res is Map) {
        final bool isSuccess = res['success'] == true;
        final String? msg = res['mensaje']?.toString() ??
            res['message']?.toString() ??
            res['error']?.toString();
        final String? quinielaId = res['quiniela_id']?.toString();

        if (isSuccess) {
          return JoinQuinielaResult(
            success: true,
            mensaje: msg ?? '¡Te has unido exitosamente a la quiniela!',
            quinielaId: quinielaId,
          );
        } else {
          return JoinQuinielaResult(
            success: false,
            mensaje: msg ?? 'No fue posible unirse a la quiniela.',
          );
        }
      }

      return JoinQuinielaResult(
        success: true,
        mensaje: '¡Te has unido exitosamente a la quiniela!',
      );
    } on PostgrestException catch (e) {
      return JoinQuinielaResult(
        success: false,
        mensaje: e.message,
      );
    } catch (e) {
      return JoinQuinielaResult(
        success: false,
        mensaje: 'Error inesperado: $e',
      );
    }
  }

  /// Obtiene las quinielas en las que el usuario actual participa o es creador
  Future<List<QuinielaModel>> getMisQuinielas() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Traer asociaciones del usuario
      final response = await _supabase
          .from('quiniela_usuarios')
          .select('''
            puntos_totales,
            quiniela_id,
            quinielas (
              id,
              nombre,
              torneo_id,
              codigo_acceso,
              limite_usuarios,
              creador_id,
              creado_en,
              torneos (
                nombre
              )
            )
          ''')
          .eq('usuario_id', user.id);

      final List<dynamic> data = response as List<dynamic>;
      final List<QuinielaModel> lista = [];

      for (var item in data) {
        if (item['quinielas'] != null) {
          final qMap = Map<String, dynamic>.from(item['quinielas'] as Map);
          qMap['puntos_totales'] = item['puntos_totales'];
          lista.add(QuinielaModel.fromJson(qMap));
        }
      }

      return lista;
    } catch (e) {
      // Fallback: intentar consultar directamente la tabla quinielas
      try {
        final qResponse = await _supabase
            .from('quinielas')
            .select('id, nombre, torneo_id, codigo_acceso, limite_usuarios, creador_id, creado_en, torneos(nombre)')
            .order('creado_en', ascending: false);

        return (qResponse as List<dynamic>)
            .map((item) => QuinielaModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }
}
