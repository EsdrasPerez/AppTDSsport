class QuinielaModel {
  final String id;
  final String nombre;
  final String torneoId;
  final String? torneoNombre;
  final String codigoAcceso;
  final int limiteUsuarios;
  final String creadorId;
  final DateTime? creadoEn;
  final int totalParticipantes;
  final int puntosUsuario;

  QuinielaModel({
    required this.id,
    required this.nombre,
    required this.torneoId,
    this.torneoNombre,
    required this.codigoAcceso,
    required this.limiteUsuarios,
    required this.creadorId,
    this.creadoEn,
    this.totalParticipantes = 1,
    this.puntosUsuario = 0,
  });

  factory QuinielaModel.fromJson(Map<String, dynamic> json) {
    // Si la consulta incluye join con torneos
    String? nombreTorneo;
    if (json['torneos'] != null && json['torneos'] is Map) {
      nombreTorneo = json['torneos']['nombre'] as String?;
    }

    return QuinielaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Quiniela sin nombre',
      torneoId: json['torneo_id'] as String? ?? '',
      torneoNombre: nombreTorneo ?? json['torneo_nombre'] as String?,
      codigoAcceso: json['codigo_acceso'] as String? ?? '',
      limiteUsuarios: json['limite_usuarios'] as int? ?? 10,
      creadorId: json['creador_id'] as String? ?? '',
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
      totalParticipantes: json['total_participantes'] as int? ?? 1,
      puntosUsuario: json['puntos_totales'] as int? ?? 0,
    );
  }
}
