import 'package:flutter_test/flutter_test.dart';
import 'package:tdsport_app/features/partidos/domain/partido.dart';

import '../helpers.dart';

void main() {
  group('EstadoPartido.fromId', () {
    test('mapea 1..4 por estado_id', () {
      expect(EstadoPartido.fromId(1), EstadoPartido.futuro);
      expect(EstadoPartido.fromId(2), EstadoPartido.enVivo);
      expect(EstadoPartido.fromId(3), EstadoPartido.finalizado);
      expect(EstadoPartido.fromId(4), EstadoPartido.suspendido);
    });

    test('un id desconocido no cae en silencio en "suspendido"', () {
      expect(() => EstadoPartido.fromId(9), throwsFormatException);
      expect(() => EstadoPartido.fromId(null), throwsFormatException);
    });
  });

  group('Partido.aceptaPronosticoEn', () {
    final ahora = DateTime(2026, 10, 13, 18);

    test('FUTURO y antes de la hora de inicio: acepta', () {
      final p = partido(fecha: ahora.add(const Duration(minutes: 1)));
      expect(p.aceptaPronosticoEn(ahora), isTrue);
    });

    test('FUTURO pero la hora ya llegó: NO acepta (B14)', () {
      expect(partido(fecha: ahora).aceptaPronosticoEn(ahora), isFalse);
      expect(partido(fecha: ahora.subtract(const Duration(minutes: 5))).aceptaPronosticoEn(ahora), isFalse);
    });

    test('EN JUEGO, FINALIZADO o SUSPENDIDO: NO acepta', () {
      final futuro = ahora.add(const Duration(days: 1));
      for (final e in [EstadoPartido.enVivo, EstadoPartido.finalizado, EstadoPartido.suspendido]) {
        expect(partido(estado: e, fecha: futuro).aceptaPronosticoEn(ahora), isFalse, reason: e.name);
      }
    });
  });

  test('goles null mientras no empieza (no se muestran como 0)', () {
    final p = Partido.fromMap({
      'id': 'x',
      'torneo_id': 't',
      'estado_id': 1,
      'goles_local': null,
      'goles_visitante': null,
      'fecha_hora': '2026-10-19T02:00:00+00:00',
      'torneos': {'id': 't', 'nombre': 'Liga', 'estado_activo': true},
      'local': {'id': 'a', 'nombre': 'A'},
      'visitante': {'id': 'b', 'nombre': 'B'},
    });
    expect(p.golesLocal, isNull);
    expect(p.tieneMarcador, isFalse);
  });

  test('búsqueda por equipo: uno o "A vs B" en cualquier orden, sin mayúsculas ni acentos', () {
    final p = partido(); // Municipal vs Comunicaciones
    expect(p.coincideConBusqueda(''), isTrue);
    expect(p.coincideConBusqueda('muni'), isTrue);
    expect(p.coincideConBusqueda('COMUNICACIÓN'), isTrue);
    expect(p.coincideConBusqueda('Municipal vs Comunicaciones'), isTrue);
    expect(p.coincideConBusqueda('comu vs muni'), isTrue);
    expect(p.coincideConBusqueda('muni vs'), isTrue);
    expect(p.coincideConBusqueda('muni vs xelajú'), isFalse);
    expect(p.coincideConBusqueda('antigua'), isFalse);
  });
}
