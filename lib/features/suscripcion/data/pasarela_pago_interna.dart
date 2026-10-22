import '../domain/pasarela_pago.dart';
import '../domain/plan_suscripcion.dart';
import 'pagos_repository.dart';

/// Implementación actual de [PasarelaPago].
/// Nota para el equipo: no hay procesador de pagos conectado. Valida la tarjeta en el dispositivo y
/// registra el cobro en metodos_pago, suscripciones y pagos (volcado inicial), sin número completo ni CVV.
/// Para conectar un procesador real, crear otra implementación de PasarelaPago y cambiarla en
/// suscripcion_providers.dart.
class PasarelaPagoInterna implements PasarelaPago {
  PasarelaPagoInterna(this._pagos);

  final PagosRepository _pagos;

  @override
  Future<ResultadoPago> cobrar({required PlanSuscripcion plan, required DatosTarjeta tarjeta}) async {
    if (plan.precio <= 0 || tarjeta.validar() != null) throw const PagoRechazado();

    // Tiempo de autorización
    await Future<void>.delayed(const Duration(milliseconds: 2500));

    return _pagos.procesarPago(plan: plan, tarjeta: tarjeta);
  }
}
