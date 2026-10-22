import 'package:equatable/equatable.dart';

import '../../../core/utils/errores.dart';
import '../../perfil/domain/perfil.dart';
import 'plan_suscripcion.dart';
import 'tarjeta.dart';

/// Datos que escribe el usuario. Viven solo en memoria del dispositivo:
/// a la base únicamente llegan [marca] y [ultimos4].
class DatosTarjeta {
  const DatosTarjeta({
    required this.titular,
    required this.numero,
    required this.vencimiento,
    required this.cvv,
  });

  final String titular;
  final String numero;
  final String vencimiento;
  final String cvv;

  MarcaTarjeta get marca => marcaDe(numero);

  String get ultimos4 {
    final n = soloDigitos(numero);
    return n.length < 4 ? '' : n.substring(n.length - 4);
  }

  /// Mes y año (4 dígitos) de "MM/AA", para metodos_pago.mes_vence / anio_vence. null si no es válido.
  ({int mes, int anio})? get mesYAnio {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(vencimiento.trim());
    return m == null ? null : (mes: int.parse(m.group(1)!), anio: 2000 + int.parse(m.group(2)!));
  }

  /// null si todo es válido; si no, el primer problema encontrado.
  String? validar() =>
      (titular.trim().length < 3 ? 'Nombre del titular' : null) ??
      validarNumeroTarjeta(numero) ??
      validarVencimiento(vencimiento) ??
      validarCvv(cvv, marca);
}

class ResultadoPago extends Equatable {
  const ResultadoPago({
    required this.referencia,
    required this.plan,
    required this.monto,
    required this.fecha,
    required this.venceEn,
    required this.marca,
    required this.ultimos4,
  });

  final String referencia;
  final PlanUsuario plan;
  final num monto;
  final DateTime fecha;

  /// Hasta cuándo queda pagado el plan (próximo cobro).
  final DateTime venceEn;
  final MarcaTarjeta marca;
  final String ultimos4;

  @override
  List<Object?> get props => [referencia, plan, monto, fecha, venceEn, marca, ultimos4];
}

/// El pago no se pudo procesar (datos de tarjeta inválidos).
class PagoRechazado extends MensajeUsuario {
  const PagoRechazado([super.mensaje = 'No se pudo procesar el pago. Revisa los datos de tu tarjeta.']);
}

/// Punto único de cobro. Hoy: PasarelaPagoInterna. Mañana: el procesador de pagos real,
/// sin cambiar las pantallas.
abstract class PasarelaPago {
  Future<ResultadoPago> cobrar({required PlanSuscripcion plan, required DatosTarjeta tarjeta});
}

/// Un pago del historial "Mis pagos" (tabla pagos).
class Pago extends Equatable {
  const Pago({
    required this.referencia,
    required this.plan,
    required this.monto,
    required this.marca,
    required this.ultimos4,
    required this.estado,
    required this.fecha,
  });

  final String referencia;
  final PlanUsuario plan;
  final num monto;
  final String marca;
  final String ultimos4;
  final String estado;
  final DateTime? fecha;

  factory Pago.fromMap(Map<String, dynamic> m) => Pago(
        referencia: m['referencia'],
        plan: PlanUsuario.desdeCodigo(m['plan'] as String?),
        monto: m['monto'] is num ? m['monto'] as num : num.tryParse('${m['monto']}') ?? 0,
        marca: m['marca'] ?? '',
        ultimos4: m['ultimos4'] ?? '',
        estado: m['estado'] ?? '',
        fecha: DateTime.tryParse(m['creado_en'] ?? '')?.toLocal(),
      );

  @override
  List<Object?> get props => [referencia, plan, monto, marca, ultimos4, estado, fecha];
}
