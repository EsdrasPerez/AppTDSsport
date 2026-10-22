import 'package:supabase_flutter/supabase_flutter.dart';

import '../../suscripcion/data/suscripcion_vigente.dart';
import '../domain/perfil.dart';

// este codigo es exclusivamente para leer y editar el perfil del usuario
class PerfilRepository {
  PerfilRepository(this._db);

  final SupabaseClient _db;

  Future<Perfil?> obtenerPerfil(String usuarioId) async {
    final response = await obtenerDatosEditables(usuarioId);
    return response == null ? null : Perfil.fromMap({...response, ...await _planDeSuscripcion(usuarioId, response)});
  }

  /// Plan, vencimiento y renovación según la suscripción vigente (tabla suscripciones):
  /// el plan dura hasta vence_en aunque se cancele; al vencer vuelve a gratis.
  /// Sin suscripciones (usuarios PRO de antes) o si no se pueden leer, se deja lo que diga perfiles.
  Future<Map<String, dynamic>> _planDeSuscripcion(String usuarioId, Map<String, dynamic> perfil) async {
    try {
      final vigente = await leerSuscripcionVigente(_db, usuarioId);
      if (vigente != null) {
        return {
          'plan': (vigente.plan?.tipo ?? PlanUsuario.pro).codigo,
          'plan_vence_en': vigente.venceEn.toIso8601String(),
          'plan_renovar': vigente.renovar,
        };
      }
      if (!await tuvoSuscripcion(_db, usuarioId)) return {};
      // Ya venció: deja de ser PRO también en la base (es_pro lo usan las reglas de la base).
      // Si la base no deja actualizarlo, en la app igual vuelve a gratis.
      if (perfil['es_pro'] == true) {
        try {
          await _db.from('perfiles').update({'es_pro': false}).eq('id', usuarioId);
        } on PostgrestException {
          // sin permiso para actualizar perfiles: no bloquea
        }
      }
      return {'es_pro': false, 'plan': PlanUsuario.gratis.codigo};
    } on PostgrestException {
      return {};
    }
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
