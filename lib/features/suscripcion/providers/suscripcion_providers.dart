import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../data/pagos_repository.dart';
import '../data/pasarela_pago_interna.dart';
import '../domain/limite_quinielas.dart';
import '../domain/pasarela_pago.dart';
import '../domain/plan_suscripcion.dart';

final pagosRepositoryProvider = Provider((ref) => PagosRepository(ref.watch(supabaseProvider)));

/// Pasarela en uso. Para conectar un procesador real, cambiar solo esta línea.
final pasarelaPagoProvider = Provider<PasarelaPago>((ref) => PasarelaPagoInterna(ref.watch(pagosRepositoryProvider)));

/// Planes disponibles (tabla planes, solo los activos).
final planesProvider = FutureProvider<List<PlanSuscripcion>>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(pagosRepositoryProvider).obtenerPlanes();
});

/// Límite de quinielas del plan del usuario (se revisa al crear o unirse a una quiniela).
final limiteQuinielasProvider = FutureProvider<LimiteQuinielas>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(pagosRepositoryProvider).obtenerLimiteQuinielas();
});

/// Historial "Mis pagos".
final misPagosProvider = FutureProvider<List<Pago>>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(pagosRepositoryProvider).obtenerMisPagos();
});

/// Acciones de suscripción. Al terminar invalidan el perfil y los pagos para que toda la app vea el cambio.
class SuscripcionController {
  SuscripcionController(this._ref);

  final Ref _ref;

  Future<ResultadoPago> pagar({required PlanSuscripcion plan, required DatosTarjeta tarjeta}) async {
    final resultado = await _ref.read(pasarelaPagoProvider).cobrar(plan: plan, tarjeta: tarjeta);
    _ref
      ..invalidate(perfilActualProvider)
      ..invalidate(misPagosProvider)
      ..invalidate(limiteQuinielasProvider);
    return resultado;
  }

  Future<void> cancelar() async {
    await _ref.read(pagosRepositoryProvider).cancelarSuscripcion();
    _ref
      ..invalidate(perfilActualProvider)
      ..invalidate(limiteQuinielasProvider);
  }
}

final suscripcionControllerProvider = Provider(SuscripcionController.new);
