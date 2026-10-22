import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plan_suscripcion.dart';

/// Suscripción que todavía cubre al usuario: la más reciente ACTIVA o CANCELADA cuyo vence_en no ha pasado.
/// Una cancelada sigue valiendo hasta vence_en (ya estaba pagada); solo deja de renovarse.
class SuscripcionVigente {
  const SuscripcionVigente({required this.id, required this.venceEn, required this.renovar, this.plan});

  final String id;
  final DateTime venceEn;

  /// false si el usuario la canceló.
  final bool renovar;

  /// Plan de la tabla planes (null si plan_id está vacío o el plan ya no existe).
  final PlanSuscripcion? plan;
}

/// Lee la suscripción vigente de [usuarioId] (null si no tiene). Lanza PostgrestException si no se puede leer.
Future<SuscripcionVigente?> leerSuscripcionVigente(SupabaseClient db, String usuarioId) async {
  final s = await db
      .from('suscripciones')
      .select('id, plan_id, vence_en, estado, renovacion_automatica')
      .eq('usuario_id', usuarioId)
      .inFilter('estado', ['ACTIVA', 'CANCELADA'])
      .gt('vence_en', DateTime.now().toUtc().toIso8601String())
      .order('vence_en', ascending: false)
      .limit(1)
      .maybeSingle();
  if (s == null) return null;

  final planId = s['plan_id'];
  final plan = planId == null ? null : await db.from('planes').select('*').eq('id', planId).maybeSingle();
  return SuscripcionVigente(
    id: s['id'].toString(),
    venceEn: DateTime.parse(s['vence_en'] as String).toLocal(),
    renovar: s['estado'] == 'ACTIVA' && (s['renovacion_automatica'] ?? true) == true,
    plan: plan == null ? null : PlanSuscripcion.fromMap(plan),
  );
}

/// ¿El usuario ha tenido alguna suscripción (vigente o vencida)?
Future<bool> tuvoSuscripcion(SupabaseClient db, String usuarioId) async =>
    (await db.from('suscripciones').select('id').eq('usuario_id', usuarioId).limit(1)).isNotEmpty;
