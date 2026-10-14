/// Moneda y precios de los planes, en un solo lugar (decisión del dueño: quetzales, solo mensual).
/// El monto que se cobra lo decide el SERVIDOR (procesar_pago); estos valores son para mostrar.
library;

import '../../../core/utils/formatos.dart';
import '../../perfil/domain/perfil.dart';

const simboloMoneda = 'Q';
const precioGratis = 0;
const precioProMensual = 50;
const precioVipMensual = 100;

// TODO(decision): plan anual. Si se define, agregar aquí los precios anuales y volver a mostrar el selector.

int precioDe(PlanUsuario plan) => switch (plan) {
      PlanUsuario.gratis => precioGratis,
      PlanUsuario.pro => precioProMensual,
      PlanUsuario.vip => precioVipMensual,
    };

/// "Q50 / mes"
String precioPorMes(int monto) => '${Formatos.moneda(monto)} / mes';
