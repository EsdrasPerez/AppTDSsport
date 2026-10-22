import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/rpc_respaldo.dart';
import '../../../core/utils/errores.dart';
import '../domain/limite_quinielas.dart';
import '../domain/pasarela_pago.dart';
import '../domain/plan_suscripcion.dart';
import '../domain/tarjeta.dart';
import 'suscripcion_vigente.dart';

// este codigo es exclusivamente para pagos y suscripción (plan del perfil).
// Solo se envían plan, marca y últimos 4 dígitos; nunca el número completo, el vencimiento ni el CVV.
class PagosRepository {
  PagosRepository(this._db);

  final SupabaseClient _db;

  String get _usuarioId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const MensajeUsuario('Tu sesión expiró. Inicia sesión de nuevo.');
    return id;
  }

  /// Proveedor que se guarda en metodos_pago y pagos mientras no haya un procesador real.
  static const _proveedor = 'interna';

  /// Planes que se pueden contratar (planes.activo), del más barato al más caro.
  Future<List<PlanSuscripcion>> obtenerPlanes() async {
    final r = await _db.from('planes').select('*').eq('activo', true).order('precio', ascending: true);
    return r.map(PlanSuscripcion.fromMap).where((p) => p.precio > 0).toList();
  }

  /// Límite de quinielas del plan del usuario: el de su suscripción vigente (planes.limite_quinielas),
  /// aunque la haya cancelado, hasta que venza. Sin suscripción vigente, o si no se puede leer, el del Plan Gratuito.
  Future<LimiteQuinielas> obtenerLimiteQuinielas() async {
    try {
      final plan = (await leerSuscripcionVigente(_db, _usuarioId))?.plan;
      return plan == null ? const LimiteQuinielas.gratis() : LimiteQuinielas.dePlan(plan);
    } on PostgrestException {
      return const LimiteQuinielas.gratis();
    }
  }

  /// Registra el cobro en las tablas del volcado inicial, en este orden:
  /// metodos_pago (marca, últimos 4, titular y vencimiento) → suscripciones (activa, 1 mes) → pagos (aprobado),
  /// y activa el plan en perfiles (es_pro). Nunca se envían el número completo ni el CVV.
  /// El precio y la moneda son los del plan en la tabla planes.
  Future<ResultadoPago> procesarPago({required PlanSuscripcion plan, required DatosTarjeta tarjeta}) async {
    final id = _usuarioId;
    final ahora = DateTime.now();
    final venceEn = DateTime(ahora.year, ahora.month + 1, ahora.day);
    final monto = plan.precio;
    final referencia = 'TDS-${ahora.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    final vence = tarjeta.mesYAnio;

    try {
      final metodo = await _db
          .from('metodos_pago')
          .insert({
            'usuario_id': id,
            'marca': nombreMarca(tarjeta.marca),
            'ultimos4': tarjeta.ultimos4,
            'titular': tarjeta.titular.trim(),
            'mes_vence': vence?.mes,
            'anio_vence': vence?.anio,
            'predeterminada': true,
            'proveedor': _proveedor,
          })
          .select('id')
          .single();

      final suscripcion = await _db
          .from('suscripciones')
          .insert({
            'usuario_id': id,
            'plan_id': plan.id,
            'metodo_pago_id': metodo['id'],
            'precio': monto,
            'moneda': plan.moneda,
            'estado': 'ACTIVA',
            'inicia_en': ahora.toUtc().toIso8601String(),
            'vence_en': venceEn.toUtc().toIso8601String(),
            'renovacion_automatica': true,
          })
          .select('id')
          .single();

      await _db.from('pagos').insert({
        'usuario_id': id,
        'suscripcion_id': suscripcion['id'],
        'importe': monto,
        'moneda': plan.moneda,
        'estado': 'APROBADO',
        'proveedor': _proveedor,
        'referencia_externa': referencia,
        'confirmado_en': ahora.toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      // RLS: la tabla existe pero no permite que el usuario inserte sus propios registros
      if (e.code == '42501') {
        throw const MensajeUsuario('No se pudo registrar el pago: la base no permite guardarlo (permisos).');
      }
      rethrow;
    }

    await conRespaldo(
      () => _db.rpc('activar_pro_demo'),
      () => _db.from('perfiles').update({'es_pro': true}).eq('id', id),
    );

    return ResultadoPago(
      referencia: referencia,
      plan: plan.tipo,
      monto: monto,
      fecha: ahora,
      venceEn: venceEn,
      marca: tarjeta.marca,
      ultimos4: tarjeta.ultimos4,
    );
  }

  /// Cancela la suscripción vigente: queda CANCELADA y sin renovación, pero el plan sigue hasta vence_en
  /// porque ese mes ya está pagado. Sin suscripción (usuarios PRO de antes), se quita el plan como antes.
  Future<void> cancelarSuscripcion() async {
    final id = _usuarioId;
    final vigente = await leerSuscripcionVigente(_db, id);
    if (vigente != null) {
      await _db.from('suscripciones').update({
        'estado': 'CANCELADA',
        'cancelada_en': DateTime.now().toUtc().toIso8601String(),
        'renovacion_automatica': false,
      }).eq('id', vigente.id);
      return;
    }
    await conRespaldo(
      () => _db.rpc('cancelar_pro_demo'),
      () => _db.from('perfiles').update({'es_pro': false}).eq('id', id),
    );
  }

  /// Historial "Mis pagos" (vacío si la tabla todavía no existe).
  /// En el volcado las tablas no tienen llaves foráneas, así que el plan y la tarjeta de cada pago se
  /// leen aparte: pagos → suscripciones (plan_id, metodo_pago_id) → planes / metodos_pago.
  Future<List<Pago>> obtenerMisPagos() => conRespaldo(
        () async {
          final pagos =
              await _db.from('pagos').select('*').eq('usuario_id', _usuarioId).order('creado_en', ascending: false);
          if (pagos.isEmpty) return <Pago>[];

          final suscripciones = await _porId('suscripciones', 'id, plan_id, metodo_pago_id',
              pagos.map((p) => p['suscripcion_id']));
          final planes = await _porId('planes', 'id, nombre', suscripciones.values.map((s) => s['plan_id']));
          final metodos =
              await _porId('metodos_pago', 'id, marca, ultimos4', suscripciones.values.map((s) => s['metodo_pago_id']));

          return [
            for (final p in pagos)
              () {
                final s = suscripciones[p['suscripcion_id']?.toString()];
                final metodo = metodos[s?['metodo_pago_id']?.toString()];
                return Pago.fromMap({
                  'referencia': p['referencia_externa'] ?? '',
                  'plan': PlanSuscripcion.tipoDe(planes[s?['plan_id']?.toString()]?['nombre'] as String?).codigo,
                  'monto': p['importe'],
                  'marca': metodo?['marca'],
                  'ultimos4': metodo?['ultimos4'],
                  'estado': p['estado'],
                  'creado_en': p['creado_en'],
                });
              }(),
          ];
        },
        () async => <Pago>[],
      );

  /// Filas de [tabla] con esos ids, por id (sin consultar si no hay ids).
  Future<Map<String, Map<String, dynamic>>> _porId(String tabla, String columnas, Iterable<Object?> ids) async {
    final unicos = {for (final id in ids) if (id != null) id.toString()}.toList();
    if (unicos.isEmpty) return {};
    final r = await _db.from(tabla).select(columnas).inFilter('id', unicos);
    return {for (final f in r) f['id'].toString(): f};
  }
}
