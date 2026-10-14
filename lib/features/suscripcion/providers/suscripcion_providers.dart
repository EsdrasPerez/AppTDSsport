import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../perfil/domain/perfil.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../data/pagos_repository.dart';
import '../data/pasarela_pago_interna.dart';
import '../domain/pasarela_pago.dart';

final pagosRepositoryProvider = Provider((ref) => PagosRepository(ref.watch(supabaseProvider)));

/// Pasarela en uso. Para conectar un procesador real, cambiar solo esta línea.
final pasarelaPagoProvider = Provider<PasarelaPago>((ref) => PasarelaPagoInterna(ref.watch(pagosRepositoryProvider)));

/// Historial "Mis pagos".
final misPagosProvider = FutureProvider<List<Pago>>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(pagosRepositoryProvider).obtenerMisPagos();
});

/// Acciones de suscripción. Al terminar invalidan el perfil y los pagos para que toda la app vea el cambio.
class SuscripcionController {
  SuscripcionController(this._ref);

  final Ref _ref;

  Future<ResultadoPago> pagar({required PlanUsuario plan, required DatosTarjeta tarjeta}) async {
    final resultado = await _ref.read(pasarelaPagoProvider).cobrar(plan: plan, tarjeta: tarjeta);
    _ref
      ..invalidate(perfilActualProvider)
      ..invalidate(misPagosProvider);
    return resultado;
  }

  Future<void> cancelar() async {
    await _ref.read(pagosRepositoryProvider).cancelarSuscripcion();
    _ref.invalidate(perfilActualProvider);
  }
}

final suscripcionControllerProvider = Provider(SuscripcionController.new);
