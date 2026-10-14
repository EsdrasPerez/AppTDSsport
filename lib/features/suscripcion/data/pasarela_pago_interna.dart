import '../../perfil/domain/perfil.dart';
import '../domain/pasarela_pago.dart';
import 'pagos_repository.dart';

/// Implementación actual de [PasarelaPago].
/// Nota para el equipo: no hay procesador de pagos conectado. Valida la tarjeta en el dispositivo y
/// registra el pago con la RPC procesar_pago (solo marca y últimos 4 dígitos). Para conectar un
/// procesador real, crear otra implementación de PasarelaPago y cambiarla en suscripcion_providers.dart.
class PasarelaPagoInterna implements PasarelaPago {
  PasarelaPagoInterna(this._pagos);

  final PagosRepository _pagos;

  @override
  Future<ResultadoPago> cobrar({required PlanUsuario plan, required DatosTarjeta tarjeta}) async {
    if (plan == PlanUsuario.gratis || tarjeta.validar() != null) throw const PagoRechazado();

    // Tiempo de autorización
    await Future<void>.delayed(const Duration(milliseconds: 2500));

    return _pagos.procesarPago(plan: plan, marca: tarjeta.marca, ultimos4: tarjeta.ultimos4);
  }
}
