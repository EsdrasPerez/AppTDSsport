import 'package:flutter_test/flutter_test.dart';
import 'package:tdsport_app/features/partidos/domain/partido.dart';
import 'package:tdsport_app/features/quinielas/domain/etiquetas_puntos.dart';
import 'package:tdsport_app/features/quinielas/domain/posiciones.dart';
import 'package:tdsport_app/features/quinielas/domain/quiniela_models.dart';

import '../helpers.dart';

void main() {
  final manana = DateTime.now().add(const Duration(days: 1));

  group('ResumenQuiniela.estado', () {
    test('por iniciar: ningún partido ha empezado', () {
      final q = resumen(partidos: [partido(fecha: manana), partido(id: 'p2', fecha: manana)]);
      expect(q.estado, EstadoQuiniela.porIniciar);
    });

    test('en curso: hay partidos jugados y pendientes', () {
      final q = resumen(partidos: [
        partido(estado: EstadoPartido.finalizado, gl: 1, gv: 0),
        partido(id: 'p2', fecha: manana),
      ]);
      expect(q.estado, EstadoQuiniela.enCurso);
    });

    test('finalizada: todos los no suspendidos terminaron', () {
      final q = resumen(partidos: [
        partido(estado: EstadoPartido.finalizado, gl: 1, gv: 0),
        partido(id: 'p2', estado: EstadoPartido.suspendido),
      ]);
      expect(q.estado, EstadoQuiniela.finalizada);
    });

    test('finalizada: el torneo está inactivo aunque queden partidos', () {
      final q = resumen(partidos: [partido(fecha: manana)], torneoActivo: false);
      expect(q.estado, EstadoQuiniela.finalizada);
    });
  });

  group('ResumenQuiniela.resultado', () {
    final terminada = [partido(estado: EstadoPartido.finalizado, gl: 2, gv: 1)];

    test('en juego mientras no termina', () {
      final q = resumen(partidos: [partido(fecha: manana)], puntos: 10, puntosDeTodos: [10, 3]);
      expect(q.resultado, ResultadoQuiniela.enJuego);
    });

    test('ganada si queda en 1.er lugar', () {
      final q = resumen(partidos: terminada, puntos: 8, puntosDeTodos: [8, 5, 4]);
      expect(q.resultado, ResultadoQuiniela.ganada);
      expect(q.empateEnPrimero, isFalse);
    });

    test('empate en 1.er lugar: todos ganan', () {
      final q = resumen(partidos: terminada, puntos: 8, puntosDeTodos: [8, 8, 4]);
      expect(q.resultado, ResultadoQuiniela.ganada);
      expect(q.empateEnPrimero, isTrue);
    });

    test('perdida en cualquier otro lugar', () {
      final q = resumen(partidos: terminada, puntos: 4, puntosDeTodos: [8, 5, 4]);
      expect(q.resultado, ResultadoQuiniela.perdida);
      expect(q.lugar, 3);
      expect(q.participantes, 3);
    });
  });

  test('pendientesDePronosticar cuenta partidos abiertos sin mi pronóstico', () {
    final q = resumen(
      partidos: [partido(fecha: manana), partido(id: 'p2', fecha: manana), partido(id: 'p3', estado: EstadoPartido.enVivo)],
      pronosticos: {'p1': pronostico('p1', 1, 0)},
    );
    expect(q.pendientesDePronosticar(DateTime.now()), 1);
  });

  test('lugares con empates compartidos: 1, 2, 2, 4', () {
    expect(calcularLugares([10, 7, 7, 3]), [1, 2, 2, 4]);
    expect(lugarDe(7, [10, 7, 7, 3]), 2);
    expect(lugarDe(3, [10, 7, 7, 3]), 4);
  });

  test('etiquetas de puntos (solo texto, sin cálculo)', () {
    expect(detallePuntos(5), 'Resultado exacto');
    expect(detallePuntos(4), 'Ganador + diferencia');
    expect(detallePuntos(3), 'Ganador / empate');
    expect(detallePuntos(0), 'Sin acierto');
    expect(signo(2, 1), '1');
    expect(signo(1, 1), 'X');
    expect(signo(0, 3), '2');
  });

  test('porJugar: solo en juego y por jugar, en juego primero; sin finalizados ni suspendidos', () {
    final q = resumen(partidos: [
      partido(id: 'fin', estado: EstadoPartido.finalizado, gl: 1, gv: 0),
      partido(id: 'fut', fecha: DateTime.now().add(const Duration(days: 1))),
      partido(id: 'sus', estado: EstadoPartido.suspendido),
      partido(id: 'vivo', estado: EstadoPartido.enVivo, gl: 0, gv: 0),
    ]);
    expect(q.porJugar.map((p) => p.id), ['vivo', 'fut']);
  });
}
