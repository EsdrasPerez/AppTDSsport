import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/rpc_respaldo.dart';
import '../../../core/utils/errores.dart';
import '../../perfil/domain/perfil.dart';
import '../domain/pasarela_pago.dart';
import '../domain/precios.dart';
import '../domain/tarjeta.dart';

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

  /// RPC procesar_pago (migración 03): registra el pago, activa el plan y devuelve referencia y vencimiento.
  /// El monto lo pone el servidor.
  Future<ResultadoPago> procesarPago({
    required PlanUsuario plan,
    required MarcaTarjeta marca,
    required String ultimos4,
  }) {
    final id = _usuarioId;
    return conRespaldo(
      () async {
        final r = await _db.rpc('procesar_pago', params: {
          'p_plan': plan.codigo,
          'p_marca': nombreMarca(marca),
          'p_ultimos4': ultimos4,
        });
        return ResultadoPago(
          referencia: r['referencia'] as String,
          plan: PlanUsuario.desdeCodigo(r['plan'] as String?),
          monto: r['monto'] as num,
          fecha: DateTime.now(),
          venceEn: DateTime.parse(r['vence_en'] as String).toLocal(),
          marca: marca,
          ultimos4: ultimos4,
        );
      },
      // Sin la migración 03 no existe la tabla pagos: se activa PRO con el camino anterior.
      () async {
        await conRespaldo(
          () => _db.rpc('activar_pro_demo'),
          () => _db.from('perfiles').update({'es_pro': true}).eq('id', id),
        );
        final ahora = DateTime.now();
        return ResultadoPago(
          referencia: 'TDS-${ahora.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
          plan: plan,
          monto: precioDe(plan),
          fecha: ahora,
          venceEn: DateTime(ahora.year, ahora.month + 1, ahora.day),
          marca: marca,
          ultimos4: ultimos4,
        );
      },
    );
  }

  /// RPC cancelar_suscripcion: no se renueva; el plan sigue hasta plan_vence_en.
  Future<void> cancelarSuscripcion() {
    final id = _usuarioId;
    return conRespaldo(
      () => _db.rpc('cancelar_suscripcion'),
      () => conRespaldo(
        () => _db.rpc('cancelar_pro_demo'),
        () => _db.from('perfiles').update({'es_pro': false}).eq('id', id),
      ),
    );
  }

  /// Historial "Mis pagos" (vacío si la tabla todavía no existe).
  Future<List<Pago>> obtenerMisPagos() => conRespaldo(
        () async {
          final r = await _db.from('pagos').select('*').eq('usuario_id', _usuarioId).order('creado_en', ascending: false);
          return r.map(Pago.fromMap).toList();
        },
        () async => <Pago>[],
      );
}
