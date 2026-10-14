class TorneoModel {
  final String id;
  final String nombre;
  final int estadoId;
  final String? fechaInicio;
  final String? fechaFin;

  TorneoModel({
    required this.id,
    required this.nombre,
    required this.estadoId,
    this.fechaInicio,
    this.fechaFin,
  });

  factory TorneoModel.fromJson(Map<String, dynamic> json) {
    return TorneoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      estadoId: json['estado_id'] as int? ?? 1,
      fechaInicio: json['fecha_inicio']?.toString(),
      fechaFin: json['fecha_fin']?.toString(),
    );
  }

  String get estadoTexto {
    switch (estadoId) {
      case 1:
        return 'Próximo';
      case 2:
        return 'En curso';
      case 3:
        return 'Finalizado';
      default:
        return 'Activo';
    }
  }
}
