import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tdsport_app/core/theme/tds_colors.dart';
import 'package:tdsport_app/core/theme/tds_theme.dart';
import 'package:tdsport_app/core/widgets/tds_buscador.dart';
import 'package:tdsport_app/core/widgets/tds_buttons.dart';
import 'package:tdsport_app/features/perfil/domain/perfil.dart';
import 'package:tdsport_app/features/perfil/providers/perfil_providers.dart';
import 'package:tdsport_app/features/quinielas/presentation/rivales_screen.dart';
import 'package:tdsport_app/features/partidos/domain/partido.dart';
import 'package:tdsport_app/features/partidos/presentation/calendario_screen.dart';
import 'package:tdsport_app/features/partidos/presentation/partidos_screen.dart';
import 'package:tdsport_app/features/partidos/presentation/widgets/torneo_secciones.dart';
import 'package:tdsport_app/features/partidos/providers/partidos_providers.dart';
import 'package:tdsport_app/features/quinielas/data/quinielas_repository.dart';
import 'package:tdsport_app/features/quinielas/domain/quiniela_models.dart';
import 'package:tdsport_app/features/quinielas/presentation/mis_pronosticos_screen.dart';
import 'package:tdsport_app/features/quinielas/presentation/quiniela_detalle_screen.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/pronostico_card.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/pronosticos_torneo_card.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/quiniela_resumen_cards.dart';
import 'package:tdsport_app/features/quinielas/providers/quinielas_providers.dart';
import 'package:tdsport_app/features/suscripcion/domain/pasarela_pago.dart';
import 'package:tdsport_app/features/suscripcion/presentation/pago/pago_screen.dart';
import 'package:tdsport_app/features/suscripcion/providers/suscripcion_providers.dart';

import '../helpers.dart';

/// Pasarela que nunca termina: deja la pantalla en "procesando".
class _PasarelaColgada implements PasarelaPago {
  final completer = Completer<ResultadoPago>();

  @override
  Future<ResultadoPago> cobrar({required PlanUsuario plan, required DatosTarjeta tarjeta}) => completer.future;
}

/// Repositorio falso: guarda los pronósticos en memoria (como la tabla pronosticos).
class _RepoFalso implements QuinielasRepository {
  final guardados = <String, Pronostico>{};
  final llamadas = <String>[];

  @override
  Future<void> guardarPronostico({
    required String quinielaId,
    required String partidoId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    llamadas.add('$quinielaId/$partidoId $golesLocal-$golesVisitante');
    guardados[partidoId] =
        Pronostico(partidoId: partidoId, golesLocal: golesLocal, golesVisitante: golesVisitante, puntos: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: TdsTheme.oscuro, home: child),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const gratis = Perfil(id: 'u1', nombre: 'José', esAdmin: false, plan: PlanUsuario.gratis);

  testWidgets('Rivales: un usuario gratis ve la pantalla bloqueada', (tester) async {
    await tester.pumpWidget(_app(const RivalesScreen(), [
      perfilActualProvider.overrideWith((ref) async => gratis),
    ]));
    await tester.pump();

    expect(find.text('Mira lo que pronosticaron tus rivales'), findsOneWidget);
    expect(find.textContaining('Hazte PRO'), findsOneWidget);
  });

  testWidgets('Pago: el botón Pagar queda deshabilitado mientras procesa', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);

    final pasarela = _PasarelaColgada();
    await tester.pumpWidget(_app(const PagoScreen(plan: 'pro'), [
      perfilActualProvider.overrideWith((ref) async => gratis),
      pasarelaPagoProvider.overrideWithValue(pasarela),
    ]));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'ANA LOPEZ');
    await tester.enterText(find.byType(TextFormField).at(1), '4242424242424242');
    await tester.enterText(find.byType(TextFormField).at(2), '1230');
    await tester.enterText(find.byType(TextFormField).at(3), '123');
    await tester.pump();

    ElevatedButton boton() => tester.widget<ElevatedButton>(find.byKey(const Key('boton-pagar')));
    expect(boton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('boton-pagar')));
    await tester.pump();

    expect(find.text('Procesando tu pago…'), findsOneWidget);
    expect(boton().onPressed, isNull);
  });

  testWidgets('Detalle de quiniela abierto desde un partido: lo resalta, baja hasta él y enfoca sus goles',
      (tester) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final partidos = [for (var i = 0; i < 10; i++) partido(id: 'p$i', fecha: manana.add(Duration(hours: i)))];
    final detalle = DetalleQuiniela(
      quiniela: const QuinielaDetalle(
        id: 'q1',
        nombre: 'Oficina',
        codigoAcceso: 'ABCD2345',
        limiteUsuarios: 10,
        torneoId: 't1',
        torneoNombre: 'Liga',
        torneoActivo: true,
        creadorId: 'u1',
      ),
      partidos: partidos,
      posiciones: const [Posicion(lugar: 1, usuarioId: 'u1', nombre: 'Ana', puntos: 0, esPro: false)],
      misPronosticos: const {},
      miId: 'u1',
    );

    await tester.pumpWidget(_app(const QuinielaDetalleScreen(quinielaId: 'q1', partidoId: 'p8'), [
      quinielaDetalleProvider('q1').overrideWith((ref) async => detalle),
      partidosProvider('t1').overrideWith((ref) async => partidos),
    ]));
    await tester.pumpAndSettle();

    // El campo de goles local del partido elegido (p8 = 9.º partido, 17.º campo) tiene el foco y se ve
    final campos = find.byType(TextField);
    expect(campos, findsNWidgets(20));
    EditableText editable(int i) =>
        tester.widget<EditableText>(find.descendant(of: campos.at(i), matching: find.byType(EditableText)));
    expect(editable(16).focusNode.hasFocus, isTrue);
    expect(editable(0).focusNode.hasFocus, isFalse);
    expect(campos.at(16).hitTestable(), findsOneWidget);
    expect(campos.first.hitTestable(), findsNothing);
  });

  testWidgets('Mis pronósticos: un card por quiniela activa con 2 partidos a la vista y "Ver más"', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    final manana = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(_app(const MisPronosticosScreen(), [
      misQuinielasProvider.overrideWith((ref) async => [
            resumen(id: 'q1', nombre: 'Oficina', partidos: [
              for (final id in ['a', 'b', 'c', 'd']) partido(id: id, fecha: manana),
            ]),
            resumen(id: 'q2', nombre: 'Familia', partidos: [partido(id: 'e', fecha: manana)]),
            // Finalizada (torneo inactivo): no sale en Pendientes
            resumen(id: 'q3', nombre: 'Vieja', torneoActivo: false, partidos: [partido(id: 'f', fecha: manana)]),
          ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('PENDIENTES (5)'), findsOneWidget);
    expect(find.text('0/4 pronosticados'), findsOneWidget);
    expect(find.text('0/1 pronosticados'), findsOneWidget);
    // De entrada: 2 partidos de "Oficina" y 1 de "Familia" (2 campos de goles cada uno), sin animación
    Finder goles() => find.descendant(of: find.byType(GolesField), matching: find.byType(TextField));
    expect(goles(), findsNWidgets(6));
    expect(find.text('Ver más (2)'), findsOneWidget);

    // Lo escrito en un partido visible se conserva al ver más y ver menos
    await tester.enterText(goles().first, '3');
    Finder camposOficina() =>
        find.descendant(of: find.byType(PronosticosTorneoCard).first, matching: find.byType(GolesField));
    expect(camposOficina(), findsNWidgets(4));
    await tester.tap(find.text('Ver más (2)'));
    await tester.pump();
    expect(camposOficina(), findsNWidgets(8));
    await tester.drag(find.byType(PronosticosTorneoCard).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver menos'));
    await tester.pumpAndSettle();
    expect(camposOficina(), findsNWidgets(4));
    expect(tester.widget<TextField>(goles().first).controller!.text, '3');
  });

  testWidgets('Mis pronósticos: la barra de búsqueda del card filtra sus partidos por equipo', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    final manana = DateTime.now().add(const Duration(days: 1));
    Partido entre(String id, String a, String b) => Partido(
          id: id,
          torneoId: 't1',
          torneo: 'Liga',
          torneoActivo: true,
          estado: EstadoPartido.futuro,
          local: Equipo(id: a, nombre: a),
          visitante: Equipo(id: b, nombre: b),
          fecha: manana,
        );
    await tester.pumpWidget(_app(const MisPronosticosScreen(), [
      misQuinielasProvider.overrideWith((ref) async => [
            resumen(id: 'q1', nombre: 'Oficina', partidos: [
              entre('a', 'Municipal', 'Comunicaciones'),
              entre('b', 'Antigua', 'Xelajú'),
              entre('c', 'Cobán', 'Mixco'),
            ]),
          ]),
    ]));
    await tester.pumpAndSettle();

    Finder goles() => find.descendant(of: find.byType(PronosticosTorneoCard), matching: find.byType(GolesField));
    final barra = find.descendant(of: find.byType(TdsBuscador), matching: find.byType(TextField));
    expect(barra, findsOneWidget);
    expect(goles(), findsNWidgets(4)); // 2 partidos a la vista

    // Encuentra también el que estaba oculto tras "Ver más"
    await tester.enterText(barra, 'mixco vs coban');
    await tester.pump();
    expect(goles(), findsNWidgets(2));
    expect(find.text('Ver más (1)'), findsNothing);

    await tester.enterText(barra, 'heredia');
    await tester.pump();
    expect(goles(), findsNothing);
    expect(find.textContaining('Ningún partido coincide'), findsOneWidget);

    await tester.enterText(barra, '');
    await tester.pump();
    expect(goles(), findsNWidgets(4));
    expect(find.text('Ver más (1)'), findsOneWidget);
  });

  testWidgets('Mis Quinielas: asignar, guardar y editar el marcador dentro del partido, sin salir', (tester) async {
    final repo = _RepoFalso();
    final p = partido(fecha: DateTime.now().add(const Duration(days: 1)));
    await tester.pumpWidget(_app(
      Scaffold(
        body: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, _) {
              final q = ref.watch(misQuinielasProvider).valueOrNull?.first;
              return q == null ? const SizedBox() : QuinielaCompactaCard(quiniela: q);
            },
          ),
        ),
      ),
      [
        quinielasRepositoryProvider.overrideWithValue(repo),
        misQuinielasProvider.overrideWith((ref) async => [resumen(partidos: [p], pronosticos: {...repo.guardados})]),
      ],
    ));
    await tester.pumpAndSettle();

    Finder goles(int i) => find.descendant(of: find.byType(GolesField).at(i), matching: find.byType(TextField));

    // Asignar: se abren los dos campos en la misma fila; Guardar se habilita con los dos
    await tester.tap(find.text('Asignar marcador'));
    await tester.pump();
    expect(find.byType(GolesField), findsNWidgets(2));
    TdsPillButton guardar() => tester.widget<TdsPillButton>(find.widgetWithText(TdsPillButton, 'Guardar'));
    await tester.enterText(goles(0), '2');
    await tester.pump();
    expect(guardar().onTap, isNull);
    await tester.enterText(goles(1), '1');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.llamadas, ['q1/p1 2-1']);
    expect(find.byType(GolesField), findsNothing);
    expect(find.textContaining('2-1 ·'), findsOneWidget);
    expect(find.text('Editar marcador'), findsOneWidget);

    // Editar: los campos llegan con el marcador guardado
    await tester.tap(find.text('Editar marcador'));
    await tester.pump();
    expect(tester.widget<TextField>(goles(0)).controller!.text, '2');
    expect(tester.widget<TextField>(goles(1)).controller!.text, '1');
    await tester.enterText(goles(0), '3');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.llamadas.last, 'q1/p1 3-1');
    expect(find.textContaining('3-1 ·'), findsOneWidget);
  });
  testWidgets('Mis pronósticos: "Guardar" aparece solo en el partido seleccionado y guarda solo ese', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    final repo = _RepoFalso();
    final manana = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(_app(const MisPronosticosScreen(), [
      quinielasRepositoryProvider.overrideWithValue(repo),
      misQuinielasProvider.overrideWith((ref) async => [
            resumen(
              partidos: [partido(id: 'a', fecha: manana), partido(id: 'b', fecha: manana)],
              pronosticos: {...repo.guardados},
            ),
          ]),
    ]));
    await tester.pumpAndSettle();

    Finder goles(int i) => find.descendant(of: find.byType(GolesField).at(i), matching: find.byType(TextField));
    // Sin partido seleccionado no hay botón de guardar
    expect(find.text('Guardar'), findsNothing);
    expect(find.textContaining('Guardar pronósticos'), findsNothing);

    // Se selecciona el 2.º partido: su botón aparece (deshabilitado hasta tener los dos goles)
    await tester.tap(goles(2));
    await tester.pump();
    expect(find.text('Guardar'), findsOneWidget);
    await tester.enterText(goles(2), '1');
    await tester.enterText(goles(3), '0');
    await tester.pump();

    // Escribir en el 1.º lo vuelve el seleccionado: el botón se mueve ahí
    await tester.enterText(goles(0), '2');
    await tester.pump();
    expect(find.text('Guardar'), findsOneWidget);
    await tester.enterText(goles(1), '2');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.llamadas, ['q1/a 2-2']);
    expect(find.text('Guardar'), findsNothing);
    // Lo escrito en el otro partido sigue ahí, sin guardar
    expect(tester.widget<TextField>(goles(2)).controller!.text, '1');
  });
  testWidgets('Calendario: los días con partidos se marcan en lima; los demás no', (tester) async {
    // Pantalla ancha: la fuente de pruebas es más ancha que la real
    tester.view.physicalSize = const Size(2700, 2400);
    addTearDown(tester.view.reset);
    final hoy = DateTime.now();
    // Partido mañana (o pasado mañana si mañana ya es otro mes, para seguir en el mes visible)
    final dia = DateTime(hoy.year, hoy.month, hoy.day + 1).month == hoy.month ? hoy.day + 1 : hoy.day - 1;
    final p = partido(fecha: DateTime(hoy.year, hoy.month, dia, 20));
    await tester.pumpWidget(_app(const CalendarioScreen(), [
      partidosProvider(null).overrideWith((ref) async => [p]),
    ]));
    // El punto de "Temporada" pulsa sin parar: se espera un tiempo fijo
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    BoxDecoration decoracionDe(String texto) {
      final caja = find.ancestor(of: find.text(texto), matching: find.byType(AnimatedContainer)).first;
      return tester.widget<AnimatedContainer>(caja).decoration! as BoxDecoration;
    }

    // Día con partido: "1 part" y borde lima
    expect(find.text('1 part'), findsOneWidget);
    expect(decoracionDe('1 part').border, isNotNull);
    expect((decoracionDe('1 part').border! as Border).top.color.toARGB32() & 0xFFFFFF,
        TdsColors.acento.toARGB32() & 0xFFFFFF);
    // Día sin partidos: "—" y sin borde
    expect(decoracionDe('—').border, isNull);
  });
  Partido deTorneo(String id, String torneoId, String torneo, DateTime fecha) => Partido(
        id: id,
        torneoId: torneoId,
        torneo: torneo,
        torneoActivo: true,
        estado: EstadoPartido.futuro,
        local: const Equipo(id: 'l', nombre: 'Municipal'),
        visitante: const Equipo(id: 'v', nombre: 'Comunicaciones'),
        fecha: fecha,
      );

  testWidgets('Partidos: agrupados por torneo; "Crear quiniela" solo si aún no estoy en una de ese torneo',
      (tester) async {
    tester.view.physicalSize = const Size(2700, 4000);
    addTearDown(tester.view.reset);
    final manana = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(_app(const PartidosScreen(), [
      partidosProvider(null).overrideWith((ref) async => [
            deTorneo('a', 't1', 'Liga Nacional', manana),
            deTorneo('b', 't2', 'Copa', manana),
            deTorneo('c', 't1', 'Liga Nacional', manana.add(const Duration(hours: 2))),
          ]),
      // Ya estoy en una quiniela de la Liga Nacional (t1)
      misQuinielasProvider.overrideWith((ref) async => [resumen(partidos: const [])]),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Un encabezado por torneo (cada tarjeta repite además el nombre del torneo)
    Finder encabezado(String t) => find.descendant(of: find.byType(EncabezadoTorneo), matching: find.text(t));
    expect(find.byType(EncabezadoTorneo), findsNWidgets(2));
    expect(encabezado('LIGA NACIONAL'), findsOneWidget);
    expect(encabezado('COPA'), findsOneWidget);
    expect(find.text('2 partidos'), findsOneWidget);
    expect(find.text('1 partido'), findsOneWidget);
    // Solo la Copa ofrece crear quiniela
    expect(find.text('Crear quiniela'), findsOneWidget);
    expect(
      find.descendant(
          of: find.ancestor(of: encabezado('COPA'), matching: find.byType(EncabezadoTorneo)),
          matching: find.text('Crear quiniela')),
      findsOneWidget,
    );
  });

  testWidgets('Calendario: "Otros torneos" muestra los que no juegan ese día, con "Crear quiniela"', (tester) async {
    tester.view.physicalSize = const Size(2700, 4000);
    addTearDown(tester.view.reset);
    final hoy = DateTime.now();
    final hoyNoche = DateTime(hoy.year, hoy.month, hoy.day, 23, 59);
    final semana = hoy.add(const Duration(days: 7));
    await tester.pumpWidget(_app(const CalendarioScreen(), [
      partidosProvider(null).overrideWith((ref) async => [
            if (hoyNoche.isAfter(hoy)) deTorneo('a', 't1', 'Liga Nacional', hoyNoche),
            deTorneo('b', 't2', 'Copa', semana),
          ]),
      misQuinielasProvider.overrideWith((ref) async => []),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('OTROS TORNEOS'), findsOneWidget);
    expect(find.descendant(of: find.byType(EncabezadoTorneo), matching: find.text('COPA')), findsOneWidget);
    expect(find.text('1 partido próximo'), findsOneWidget);
    expect(find.text('Crear quiniela'), findsWidgets);
  });

  test('Crear quiniela: solo se ofrecen torneos activos que tienen partidos', () async {
    const conPartidos = Torneo(id: 't1', nombre: 'Liga Nacional', activo: true);
    const sinPartidos = Torneo(id: 't2', nombre: 'Copa vacía', activo: true);
    final contenedor = ProviderContainer(overrides: [
      torneosActivosProvider.overrideWith((ref) async => [conPartidos, sinPartidos]),
      partidosProvider(null).overrideWith((ref) async => [partido()]),
    ]);
    addTearDown(contenedor.dispose);

    expect(await contenedor.read(torneosConPartidosProvider.future), [conPartidos]);
  });
  testWidgets('Calendario: con una liga elegida la tira solo muestra los días en que juega', (tester) async {
    tester.view.physicalSize = const Size(2700, 4000);
    addTearDown(tester.view.reset);
    final hoy = DateTime.now();
    final fin = DateTime(hoy.year, hoy.month + 1, 0).day;
    // Dos días de este mes para la Liga y uno distinto para la Copa
    final dLiga = [1, fin];
    final dCopa = fin > 2 ? 2 : 1;
    await tester.pumpWidget(_app(const CalendarioScreen(), [
      partidosProvider(null).overrideWith((ref) async => [
            for (final d in dLiga) deTorneo('l$d', 't1', 'Liga Nacional', DateTime(hoy.year, hoy.month, d, 20)),
            deTorneo('c', 't2', 'Copa', DateTime(hoy.year, hoy.month, dCopa, 18)),
          ]),
      misQuinielasProvider.overrideWith((ref) async => []),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final tira = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal);
    Finder enTira(Finder f) => find.descendant(of: tira, matching: f);

    // Sin liga: también salen días sin partidos ("—")
    expect(enTira(find.text('—')), findsWidgets);

    // Con la Liga elegida: solo sus 2 días, sin días vacíos ni el de la Copa
    await tester.tap(find.text('Liga Nacional'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(enTira(find.text('—')), findsNothing);
    // Solo los 2 días de la Liga (el de la Copa no aparece)
    expect(enTira(find.text('1 part')), findsNWidgets(2));
  });
  testWidgets('Partidos: solo ligas activas (en curso o por iniciar); las finalizadas no aparecen', (tester) async {
    tester.view.physicalSize = const Size(2700, 4000);
    addTearDown(tester.view.reset);
    final manana = DateTime.now().add(const Duration(days: 1));
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    Partido finalizada(String id) => Partido(
          id: id,
          torneoId: 't9',
          torneo: 'Liga Vieja',
          torneoActivo: false,
          estado: EstadoPartido.finalizado,
          local: const Equipo(id: 'l', nombre: 'Municipal'),
          visitante: const Equipo(id: 'v', nombre: 'Comunicaciones'),
          golesLocal: 1,
          golesVisitante: 0,
          fecha: ayer,
        );
    await tester.pumpWidget(_app(const PartidosScreen(), [
      partidosProvider(null).overrideWith((ref) async => [
            deTorneo('a', 't1', 'Liga Nacional', manana),
            finalizada('b'),
          ]),
      misQuinielasProvider.overrideWith((ref) async => []),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Liga Nacional'), findsOneWidget); // chip
    expect(find.text('Liga Vieja'), findsNothing);
    expect(find.textContaining('LIGA VIEJA'), findsNothing);
    expect(find.byType(EncabezadoTorneo), findsOneWidget);
  });
}
