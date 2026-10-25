import 'package:equatable/equatable.dart';

import '../../../core/utils/texto.dart';

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

/// ¿El torneo está activo? Sirve para los dos esquemas:
/// - base local: columna `estado_activo` (sí/no);
/// - proyecto en la nube: `estado_id` de estados_torneo (1 PRÓXIMO y 2 EN CURSO cuentan como activos).
bool torneoEstaActivo(Map<String, dynamic>? torneo, {bool porDefecto = true}) {
  if (torneo == null) return porDefecto;
  final activo = torneo['estado_activo'];
  if (activo is bool) return activo;
  final estado = torneo['estado_id'];
  if (estado is int) return estado == 1 || estado == 2;
  return porDefecto;
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
        activo: torneoEstaActivo(map, porDefecto: false),
        formato: map['formato'] ?? map['formatos_torneo']?['nombre'],
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
    this.jornada,
    this.estadio,
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

  /// Texto de la base ("6" o "Cuartos de final"); null si está vacío.
  final String? jornada;
  final String? estadio;

  static String? _texto(Object? valor) => switch (valor?.toString().trim()) { '' || null => null, final t => t };

  factory Partido.fromMap(Map<String, dynamic> map) {
    final torneo = map['torneos'] as Map<String, dynamic>?;
    return Partido(
      id: map['id'].toString(),
      torneoId: (map['torneo_id'] ?? torneo?['id']).toString(),
      torneo: torneo?['nombre'] ?? 'Torneo',
      torneoActivo: torneoEstaActivo(torneo),
      estado: EstadoPartido.fromId(map['estado_id'] as int?),
      local: Equipo.fromMap(map['local'], fallback: 'Local'),
      visitante: Equipo.fromMap(map['visitante'], fallback: 'Visitante'),
      golesLocal: map['goles_local'] as int?,
      golesVisitante: map['goles_visitante'] as int?,
      fecha: map['fecha_hora'] == null ? null : DateTime.tryParse(map['fecha_hora'])?.toLocal(),
      jornada: _texto(map['jornada']),
      estadio: _texto(map['estadio']),
    );
  }

  bool get tieneMarcador => golesLocal != null && golesVisitante != null;

  /// ¿El partido se está jugando en este momento?
  /// Se considera en juego si:
  /// 1. Su estado en base de datos es `enVivo` (id 2).
  /// 2. O si es un partido no finalizado/suspendido cuya hora de inicio ya llegó y
  ///    se encuentra en la ventana habitual de juego (~135 minutos desde el inicio).
  bool estaEnJuegoEn(DateTime ahora) {
    if (estado == EstadoPartido.enVivo) return true;
    if (estado == EstadoPartido.finalizado || estado == EstadoPartido.suspendido) return false;
    if (fecha == null) return false;
    return ahora.isAfter(fecha!) && ahora.isBefore(fecha!.add(const Duration(minutes: 135)));
  }

  bool get estaEnJuego => estaEnJuegoEn(DateTime.now());

  /// Se puede pronosticar: estado FUTURO, no está en juego y la hora de inicio todavía no llega.
  bool aceptaPronosticoEn(DateTime ahora) =>
      estado == EstadoPartido.futuro && !estaEnJuegoEn(ahora) && (fecha == null || fecha!.isAfter(ahora));

  bool get aceptaPronostico => aceptaPronosticoEn(DateTime.now());

  /// Partido FUTURO de un torneo activo: se puede crear quiniela para su torneo.
  bool get permiteCrearQuiniela => estado == EstadoPartido.futuro && torneoActivo;

  /// Búsqueda por equipo: "muni" busca en los dos equipos; "muni vs comu" busca ese
  /// enfrentamiento en cualquier orden. Sin distinguir mayúsculas ni acentos.
  bool coincideConBusqueda(String texto) {
    final q = sinAcentos(texto.trim());
    if (q.isEmpty) return true;
    final l = sinAcentos(local.nombre);
    final v = sinAcentos(visitante.nombre);
    final t = sinAcentos(torneo);
    final e = sinAcentos(estadio ?? '');
    final partes = q.split(RegExp(r'\s+vs\.?\s*|\s*vs\.?\s+')).map((s) => s.trim()).toList();
    if (partes.length == 2) {
      final (a, b) = (partes[0], partes[1]);
      return (l.contains(a) && v.contains(b)) || (l.contains(b) && v.contains(a));
    }
    return l.contains(q) || v.contains(q) || t.contains(q) || e.contains(q);
  }

  /// Formato legible de la jornada o fase (ej. "16" -> "Jornada 16", "Cuartos" -> "Cuartos").
  String get nombreJornada {
    if (jornada == null || jornada!.trim().isEmpty) return 'General';
    final num = int.tryParse(jornada!.trim());
    if (num != null) return 'Jornada $num';
    return jornada!.trim();
  }

  @override
  List<Object?> get props =>
      [id, torneoId, torneo, torneoActivo, estado, local, visitante, golesLocal, golesVisitante, fecha, jornada, estadio];
}
