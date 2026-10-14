import 'package:tdsport_app/features/partidos/domain/partido.dart';
import 'package:tdsport_app/features/quinielas/domain/quiniela_models.dart';

const local = Equipo(id: 'l', nombre: 'Municipal');
const visitante = Equipo(id: 'v', nombre: 'Comunicaciones');

Partido partido({
  String id = 'p1',
  EstadoPartido estado = EstadoPartido.futuro,
  DateTime? fecha,
  int? gl,
  int? gv,
  bool torneoActivo = true,
}) =>
    Partido(
      id: id,
      torneoId: 't1',
      torneo: 'Liga',
      torneoActivo: torneoActivo,
      estado: estado,
      local: local,
      visitante: visitante,
      golesLocal: gl,
      golesVisitante: gv,
      fecha: fecha,
    );

Pronostico pronostico(String partidoId, int l, int v, {int puntos = 0}) =>
    Pronostico(partidoId: partidoId, golesLocal: l, golesVisitante: v, puntos: puntos);

ResumenQuiniela resumen({
  required List<Partido> partidos,
  int puntos = 0,
  List<int>? puntosDeTodos,
  bool torneoActivo = true,
  Map<String, Pronostico> pronosticos = const {},
}) =>
    ResumenQuiniela(
      id: 'q1',
      nombre: 'Quiniela',
      codigoAcceso: 'ABCD2345',
      limiteUsuarios: 10,
      creadoEn: null,
      unidoEn: null,
      creadorId: 'u1',
      torneoId: 't1',
      torneoNombre: 'Liga',
      torneoActivo: torneoActivo,
      puntos: puntos,
      puntosDeTodos: puntosDeTodos ?? [puntos],
      partidos: partidos,
      pronosticos: pronosticos,
    );
