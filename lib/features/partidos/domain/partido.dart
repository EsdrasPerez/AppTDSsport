import 'package:equatable/equatable.dart';

/// Estados de la tabla estados_partido. El orden es el que se usa al ordenar listas.
enum EstadoPartido {
  futuro(1),
  enVivo(2),
  finalizado(3),
  suspendido(4);

  const EstadoPartido(this.id);

  /// estados_partido.id
  final int id;

  /// Mapea por estado_id (no por el texto de la descripción).
  static EstadoPartido fromId(int? id) => switch (id) {
        1 => futuro,
        2 => enVivo,
        3 => finalizado,
        4 => suspendido,
        _ => throw FormatException('estado_id desconocido: $id'),
      };
}

class Equipo extends Equatable {
  const Equipo({required this.id, required this.nombre, this.escudoUrl});

  final String id;
  final String nombre;
  final String? escudoUrl;

  factory Equipo.fromMap(Map<String, dynamic>? map, {String fallback = 'Equipo'}) => Equipo(
        id: map?['id']?.toString() ?? '',
        nombre: map?['nombre'] ?? fallback,
        escudoUrl: map?['escudo_url'],
      );

  @override
  List<Object?> get props => [id, nombre, escudoUrl];
}

class Torneo extends Equatable {
  const Torneo({required this.id, required this.nombre, required this.activo, this.formato});

  final String id;
  final String nombre;
  final bool activo;
  final String? formato;

  factory Torneo.fromMap(Map<String, dynamic> map) => Torneo(
        id: map['id'].toString(),
        nombre: map['nombre'] ?? 'Torneo',
        activo: map['estado_activo'] ?? false,
        formato: map['formato'],
      );

  @override
  List<Object?> get props => [id, nombre, activo, formato];
}

class Partido extends Equatable {
  const Partido({
    required this.id,
    required this.torneoId,
    required this.torneo,
    required this.torneoActivo,
    required this.estado,
    required this.local,
    required this.visitante,
    this.golesLocal,
    this.golesVisitante,
    this.fecha,
  });

  final String id;
  final String torneoId;
  final String torneo;
  final bool torneoActivo;
  final EstadoPartido estado;
  final Equipo local;
  final Equipo visitante;

  /// null mientras el partido no ha empezado.
  final int? golesLocal;
  final int? golesVisitante;
  final DateTime? fecha;

  factory Partido.fromMap(Map<String, dynamic> map) {
    final torneo = map['torneos'] as Map<String, dynamic>?;
    return Partido(
      id: map['id'].toString(),
      torneoId: (map['torneo_id'] ?? torneo?['id']).toString(),
      torneo: torneo?['nombre'] ?? 'Torneo',
      torneoActivo: torneo?['estado_activo'] ?? true,
      estado: EstadoPartido.fromId(map['estado_id'] as int?),
      local: Equipo.fromMap(map['local'], fallback: 'Local'),
      visitante: Equipo.fromMap(map['visitante'], fallback: 'Visitante'),
      golesLocal: map['goles_local'] as int?,
      golesVisitante: map['goles_visitante'] as int?,
      fecha: map['fecha_hora'] == null ? null : DateTime.tryParse(map['fecha_hora'])?.toLocal(),
    );
  }

  bool get tieneMarcador => golesLocal != null && golesVisitante != null;

  /// Se puede pronosticar: estado FUTURO y la hora de inicio todavía no llega.
  bool aceptaPronosticoEn(DateTime ahora) =>
      estado == EstadoPartido.futuro && (fecha == null || fecha!.isAfter(ahora));

  bool get aceptaPronostico => aceptaPronosticoEn(DateTime.now());

  /// Partido FUTURO de un torneo activo: se puede crear quiniela para su torneo.
  bool get permiteCrearQuiniela => estado == EstadoPartido.futuro && torneoActivo;

  @override
  List<Object?> get props =>
      [id, torneoId, torneo, torneoActivo, estado, local, visitante, golesLocal, golesVisitante, fecha];
}
