import 'package:equatable/equatable.dart';

import '../../perfil/domain/perfil.dart';

/// Un plan de la tabla planes (volcado inicial). Es lo que se muestra en Suscripción y lo que se cobra.
class PlanSuscripcion extends Equatable {
  const PlanSuscripcion({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.moneda,
    this.descripcion,
    this.periodo,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final num precio;
  final String moneda;
  final String? periodo;

  /// PRO o VIP según el nombre del plan ("VIP ..." = VIP; cualquier otro plan de pago = PRO).
  /// Sirve para los colores y beneficios de la tarjeta y para perfiles.es_pro.
  PlanUsuario get tipo => tipoDe(nombre);

  static PlanUsuario tipoDe(String? nombre) =>
      (nombre ?? '').toUpperCase().contains('VIP') ? PlanUsuario.vip : PlanUsuario.pro;

  factory PlanSuscripcion.fromMap(Map<String, dynamic> m) => PlanSuscripcion(
        id: m['id'].toString(),
        nombre: (m['nombre'] as String?)?.trim() ?? 'Plan',
        descripcion: (m['descripcion'] as String?)?.trim(),
        precio: m['precio'] is num ? m['precio'] as num : num.tryParse('${m['precio']}') ?? 0,
        moneda: (m['moneda'] as String?)?.trim().isNotEmpty == true ? (m['moneda'] as String).trim() : 'GTQ',
        periodo: (m['periodo'] as String?)?.trim(),
      );

  @override
  List<Object?> get props => [id, nombre, descripcion, precio, moneda, periodo];
}
