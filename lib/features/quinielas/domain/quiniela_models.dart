import 'package:equatable/equatable.dart';

import '../../partidos/domain/partido.dart';
import '../../perfil/domain/perfil.dart';
import 'posiciones.dart';

/// Quiniela de todo un torneo o de un solo partido (quinielas.tipo).
enum TipoQuiniela {
  torneo('TORNEO', 'Torneo'),
  partido('PARTIDO', 'Partido');

  const TipoQuiniela(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  /// Sin la columna tipo (antes de la migración 03) todas son por torneo.
  static TipoQuiniela desdeCodigo(String? codigo) => codigo == 'PARTIDO' ? partido : torneo;
}

enum EstadoQuiniela { enCurso, porIniciar, finalizada, anulada }

enum ResultadoQuiniela { enJuego, ganada, perdida, anulada }

/// Regla única del estado de una quiniela (la usan el resumen y el detalle).
/// - Por torneo: finalizada si el torneo está inactivo o ya se jugaron todos sus partidos no suspendidos.
/// - Por partido: finalizada cuando el partido termina; ANULADA si el partido se suspendió.
EstadoQuiniela calcularEstadoQuiniela({
  required TipoQuiniela tipo,
  required bool torneoActivo,
  required List<Partido> partidos,
}) {
  if (tipo == TipoQuiniela.partido) {
    final p = partidos.firstOrNull;
    if (p == null) return EstadoQuiniela.finalizada;
    return switch (p.estado) {
      EstadoPartido.suspendido => EstadoQuiniela.anulada,
      EstadoPartido.finalizado => EstadoQuiniela.finalizada,
      EstadoPartido.enVivo => EstadoQuiniela.enCurso,
      EstadoPartido.futuro => torneoActivo ? EstadoQuiniela.porIniciar : EstadoQuiniela.finalizada,
    };
  }

  final jugables = partidos.where((p) => p.estado != EstadoPartido.suspendido).toList();
  if (!torneoActivo || (jugables.isNotEmpty && jugables.every((p) => p.estado == EstadoPartido.finalizado))) {
    return EstadoQuiniela.finalizada;
  }
  if (jugables.every((p) => p.estado == EstadoPartido.futuro)) return EstadoQuiniela.porIniciar;
  return EstadoQuiniela.enCurso;
}

/// Ganada si quedó en 1.er lugar (empates comparten el 1.er lugar). Solo cuando ya terminó.
ResultadoQuiniela calcularResultado(EstadoQuiniela estado, int? lugar) => switch (estado) {
      EstadoQuiniela.anulada => ResultadoQuiniela.anulada,
      EstadoQuiniela.finalizada => lugar == 1 ? ResultadoQuiniela.ganada : ResultadoQuiniela.perdida,
      _ => ResultadoQuiniela.enJuego,
    };

/// Partidos que pertenecen a una quiniela según su tipo.
List<Partido> partidosDeQuiniela({
  required TipoQuiniela tipo,
  required String torneoId,
  required String? partidoId,
  required Iterable<Partido> partidos,
}) =>
    tipo == TipoQuiniela.partido
        ? partidos.where((p) => p.id == partidoId).toList()
        : partidos.where((p) => p.torneoId == torneoId).toList();

/// Cabecera de una quiniela (tabla quinielas + torneos).
class QuinielaDetalle extends Equatable {
  const QuinielaDetalle({
    required this.id,
    required this.nombre,
    required this.codigoAcceso,
    required this.limiteUsuarios,
    required this.torneoId,
    required this.torneoNombre,
    required this.torneoActivo,
    required this.creadorId,
    this.tipo = TipoQuiniela.torneo,
    this.partidoId,
  });

  final String id;
  final String nombre;
  final String codigoAcceso;
  final int limiteUsuarios;
  final String torneoId;
  final String torneoNombre;
  final bool torneoActivo;
  final String creadorId;
  final TipoQuiniela tipo;
  final String? partidoId;

  factory QuinielaDetalle.fromMap(Map<String, dynamic> map) => QuinielaDetalle(
        id: map['id'].toString(),
        nombre: map['nombre'],
        codigoAcceso: map['codigo_acceso'],
        limiteUsuarios: map['limite_usuarios'],
        torneoId: map['torneo_id'].toString(),
        torneoNombre: map['torneos']?['nombre'] ?? 'Torneo',
        torneoActivo: torneoEstaActivo(map['torneos']),
        creadorId: map['creador_id'].toString(),
        tipo: TipoQuiniela.desdeCodigo(map['tipo'] as String?),
        partidoId: map['partido_id']?.toString(),
      );

  @override
  List<Object?> get props =>
      [id, nombre, codigoAcceso, limiteUsuarios, torneoId, torneoNombre, torneoActivo, creadorId, tipo, partidoId];
}

/// Fila de la tabla de posiciones (quiniela_usuarios + perfiles).
class Posicion extends Equatable {
  const Posicion({
    required this.lugar,
    required this.usuarioId,
    required this.nombre,
    required this.puntos,
    required this.esPro,
    this.plan = PlanUsuario.gratis,
  });

  final int lugar;
  final String usuarioId;
  final String nombre;
  final int puntos;
  final bool esPro;
  final PlanUsuario plan;

  @override
  List<Object?> get props => [lugar, usuarioId, nombre, puntos, esPro, plan];
}

/// Pronóstico de un usuario para un partido (tabla pronosticos).
class Pronostico extends Equatable {
  const Pronostico({
    required this.partidoId,
    required this.golesLocal,
    required this.golesVisitante,
    required this.puntos,
    this.actualizadoEn,
  });

  final String partidoId;
  final int golesLocal;
  final int golesVisitante;

  /// pronosticos.puntos_obtenidos tal como viene de la base.
  final int puntos;
  final DateTime? actualizadoEn;

  factory Pronostico.fromMap(Map<String, dynamic> map) => Pronostico(
        partidoId: map['partido_id'].toString(),
        golesLocal: map['pred_goles_local'],
        golesVisitante: map['pred_goles_visitante'],
        puntos: map['puntos_obtenidos'] ?? 0,
        actualizadoEn: DateTime.tryParse(map['actualizado_en'] ?? '')?.toLocal(),
      );

  @override
  List<Object?> get props => [partidoId, golesLocal, golesVisitante, puntos, actualizadoEn];
}

/// Resumen de una quiniela del usuario actual (Inicio, Mis Quinielas, Historial, Mis pronósticos).
class ResumenQuiniela extends Equatable {
  const ResumenQuiniela({
    required this.id,
    required this.nombre,
    required this.codigoAcceso,
    required this.limiteUsuarios,
    required this.creadoEn,
    required this.unidoEn,
    required this.creadorId,
    required this.torneoId,
    required this.torneoNombre,
    required this.torneoActivo,
    required this.puntos,
    required this.puntosDeTodos,
    required this.partidos,
    required this.pronosticos,
    this.tipo = TipoQuiniela.torneo,
    this.partidoId,
  });

  final String id;
  final String nombre;
  final String codigoAcceso;
  final int limiteUsuarios;
  final DateTime? creadoEn;
  final DateTime? unidoEn;
  final String creadorId;
  final String torneoId;
  final String torneoNombre;
  final bool torneoActivo;
  final TipoQuiniela tipo;
  final String? partidoId;

  /// Mis puntos_totales en esta quiniela (leídos de la base).
  final int puntos;

  /// puntos_totales de todos los miembros (incluido yo).
  final List<int> puntosDeTodos;

  /// Partidos de la quiniela: todo el torneo (TORNEO) o solo uno (PARTIDO), por fecha.
  final List<Partido> partidos;

  /// Mis pronósticos, por partido.
  final Map<String, Pronostico> pronosticos;

  int get lugar => lugarDe(puntos, puntosDeTodos);
  int get participantes => puntosDeTodos.length;

  bool esCreador(String? usuarioId) => usuarioId != null && creadorId == usuarioId;

  List<Partido> get _jugables => partidos.where((p) => p.estado != EstadoPartido.suspendido).toList();
  List<Partido> get finalizados => partidos.where((p) => p.estado == EstadoPartido.finalizado).toList();
  List<Partido> get futuros => partidos.where((p) => p.estado == EstadoPartido.futuro).toList();
  int get enVivo => partidos.where((p) => p.estado == EstadoPartido.enVivo).length;

  EstadoQuiniela get estado =>
      calcularEstadoQuiniela(tipo: tipo, torneoActivo: torneoActivo, partidos: partidos);

  bool get activa => estado == EstadoQuiniela.enCurso || estado == EstadoQuiniela.porIniciar;

  ResultadoQuiniela get resultado => calcularResultado(estado, lugar);

  bool get empateEnPrimero =>
      resultado == ResultadoQuiniela.ganada && puntosDeTodos.where((p) => p == puntos).length > 1;

  /// Pronósticos con puntos en partidos finalizados.
  int get aciertos => finalizados.where((p) => (pronosticos[p.id]?.puntos ?? 0) > 0).length;

  /// Partidos que aún aceptan pronóstico y todavía no tienen el mío.
  int pendientesDePronosticar(DateTime ahora) =>
      partidos.where((p) => p.aceptaPronosticoEn(ahora) && !pronosticos.containsKey(p.id)).length;

  /// Pronósticos ya capturados para partidos FUTURO.
  int get futurosListos => futuros.where((p) => pronosticos.containsKey(p.id)).length;

  int get totalPartidos => _jugables.length;

  double get avance => totalPartidos == 0 ? 0 : finalizados.length / totalPartidos;

  Partido? get proximoPartido => futuros.isEmpty ? null : futuros.first;

  /// Fecha del último partido jugado (para ordenar el historial).
  DateTime? get fechaUltimoPartido {
    final fechas = finalizados.map((p) => p.fecha).whereType<DateTime>().toList()..sort();
    return fechas.isEmpty ? (partidos.firstOrNull?.fecha ?? creadoEn) : fechas.last;
  }

  @override
  List<Object?> get props => [
        id, nombre, codigoAcceso, limiteUsuarios, creadoEn, unidoEn, creadorId, torneoId, torneoNombre,
        torneoActivo, tipo, partidoId, puntos, puntosDeTodos, partidos, pronosticos,
      ];
}

/// Todo lo que necesita el detalle de una quiniela (y la pantalla de participante).
class DetalleQuiniela extends Equatable {
  const DetalleQuiniela({
    required this.quiniela,
    required this.partidos,
    required this.posiciones,
    required this.misPronosticos,
    required this.miId,
  });

  final QuinielaDetalle quiniela;

  /// Ya filtrados por tipo (todo el torneo o el partido único).
  final List<Partido> partidos;
  final List<Posicion> posiciones;
  final Map<String, Pronostico> misPronosticos;
  final String? miId;

  Posicion? get miPosicion => posiciones.where((p) => p.usuarioId == miId).firstOrNull;
  bool get soyMiembro => miPosicion != null;
  bool get soyCreador => miId != null && quiniela.creadorId == miId;
  bool get esPorPartido => quiniela.tipo == TipoQuiniela.partido;

  EstadoQuiniela get estado =>
      calcularEstadoQuiniela(tipo: quiniela.tipo, torneoActivo: quiniela.torneoActivo, partidos: partidos);

  /// Terminada (finalizada o anulada): ya no se invita ni se pronostica.
  bool get finalizada => estado == EstadoQuiniela.finalizada || estado == EstadoQuiniela.anulada;

  ResultadoQuiniela get miResultado => resultadoDe(miPosicion);

  ResultadoQuiniela resultadoDe(Posicion? p) =>
      p == null && estado != EstadoQuiniela.anulada ? ResultadoQuiniela.enJuego : calcularResultado(estado, p?.lugar);

  /// Todo lo que no ha finalizado (los que no aceptan pronóstico se muestran bloqueados).
  List<Partido> get pendientes => partidos.where((p) => p.estado != EstadoPartido.finalizado).toList();

  /// Finalizados, del más reciente al más antiguo.
  List<Partido> get finalizados =>
      partidos.where((p) => p.estado == EstadoPartido.finalizado).toList().reversed.toList();

  @override
  List<Object?> get props => [quiniela, partidos, posiciones, misPronosticos, miId];
}
