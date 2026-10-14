import 'package:equatable/equatable.dart';

enum PlanUsuario {
  gratis('GRATIS', 'Gratis'),
  pro('PRO', 'PRO'),
  vip('VIP', 'VIP');

  const PlanUsuario(this.codigo, this.etiqueta);

  /// perfiles.plan / pagos.plan
  final String codigo;
  final String etiqueta;

  static PlanUsuario desdeCodigo(String? codigo) =>
      PlanUsuario.values.firstWhere((p) => p.codigo == codigo, orElse: () => gratis);
}

class Perfil extends Equatable {
  const Perfil({
    required this.id,
    required this.nombre,
    required this.esAdmin,
    required this.plan,
    this.planVenceEn,
    this.planRenovar = true,
  });

  final String id;
  final String nombre;
  final bool esAdmin;

  /// Plan contratado (columna plan de la migración 03; antes se deduce de es_pro).
  final PlanUsuario plan;

  /// Hasta cuándo está pagado el plan (null = sin vencimiento).
  final DateTime? planVenceEn;

  /// false si el usuario canceló: el plan sigue activo hasta [planVenceEn] y no se renueva.
  final bool planRenovar;

  factory Perfil.fromMap(Map<String, dynamic> map) {
    final esPro = map['es_pro'] ?? false;
    final columna = PlanUsuario.desdeCodigo(map['plan'] as String?);
    // Sin la columna plan (o con datos viejos), es_pro = true se interpreta como PRO.
    final plan = (columna == PlanUsuario.gratis && esPro) ? PlanUsuario.pro : columna;
    return Perfil(
      id: map['id'].toString(),
      nombre: map['nombre'] ?? 'Usuario',
      // es_admin y plan llegan con las migraciones; mientras no existan se usan los valores por defecto.
      esAdmin: map['es_admin'] ?? false,
      plan: plan,
      planVenceEn: DateTime.tryParse(map['plan_vence_en'] ?? '')?.toLocal(),
      planRenovar: map['plan_renovar'] ?? true,
    );
  }

  /// PRO o VIP vigente (si el plan venció, ya no cuenta).
  bool get esPro =>
      plan != PlanUsuario.gratis && (planVenceEn == null || planVenceEn!.isAfter(DateTime.now()));

  PlanUsuario get planVigente => esPro ? plan : PlanUsuario.gratis;

  /// Primer nombre para saludar ("Hola, Ana").
  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  @override
  List<Object?> get props => [id, nombre, esAdmin, plan, planVenceEn, planRenovar];
}
