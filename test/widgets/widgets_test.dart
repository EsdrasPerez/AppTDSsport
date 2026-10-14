import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tdsport_app/core/widgets/estado_carga.dart';
import 'package:tdsport_app/core/widgets/tds_buttons.dart';
import 'package:tdsport_app/features/partidos/domain/partido.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/pronostico_card.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/pronosticos_torneo_card.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/quiniela_resumen_cards.dart';

import '../helpers.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  // En pruebas no se descargan fuentes
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> noOp(Partido p, int l, int v) async {}

  testWidgets('PronosticoCard bloqueada si el partido no acepta pronóstico', (tester) async {
    await tester.pumpWidget(_app(PronosticoCard(
      partido: partido(estado: EstadoPartido.enVivo, fecha: DateTime.now().subtract(const Duration(minutes: 10))),
      onGuardar: noOp,
    )));

    expect(find.text('Pronósticos cerrados'), findsOneWidget);
    final campos = tester.widgetList<TextField>(find.byType(TextField));
    expect(campos.every((c) => c.enabled == false), isTrue);
  });

  testWidgets('PronosticoCard bloqueada cuando la hora ya pasó aunque siga en FUTURO', (tester) async {
    await tester.pumpWidget(_app(PronosticoCard(
      partido: partido(fecha: DateTime.now().subtract(const Duration(minutes: 1))),
      onGuardar: noOp,
    )));
    expect(find.text('Pronósticos cerrados'), findsOneWidget);
  });

  testWidgets('Guardar deshabilitado si faltan goles', (tester) async {
    await tester.pumpWidget(_app(PronosticoCard(
      partido: partido(fecha: DateTime.now().add(const Duration(days: 1))),
      onGuardar: noOp,
    )));

    TdsPillButton boton() => tester.widget<TdsPillButton>(find.byType(TdsPillButton));
    expect(boton().onTap, isNull);

    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pump();
    expect(boton().onTap, isNull);

    await tester.enterText(find.byType(TextField).last, '1');
    await tester.pump();
    expect(boton().onTap, isNotNull);
  });

  testWidgets('Tarjeta del torneo: un solo botón guarda solo los partidos abiertos con marcador', (tester) async {
    final guardados = <String, (int, int)>{};
    await tester.pumpWidget(_app(PronosticosTorneoCard(
      titulo: 'Liga',
      partidos: [
        partido(id: 'abierto', fecha: DateTime.now().add(const Duration(days: 1))),
        partido(id: 'cerrado', estado: EstadoPartido.enVivo, fecha: DateTime.now()),
      ],
      pronosticos: const {},
      onGuardar: (p, l, v) async => guardados[p.id] = (l, v),
    )));

    // 2 partidos en una sola tarjeta; los campos del partido en juego están bloqueados
    final campos = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(campos.length, 4);
    expect(campos.where((c) => c.enabled == false).length, 2);

    TdsPillButton boton() => tester.widget<TdsPillButton>(find.byType(TdsPillButton));
    expect(boton().onTap, isNull);

    await tester.enterText(find.byType(TextField).at(0), '2');
    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.pump();
    expect(find.text('Guardar pronósticos (1)'), findsOneWidget);

    await tester.tap(find.byType(TdsPillButton));
    await tester.pump();
    expect(guardados, {'abierto': (2, 1)});
  });

  testWidgets('ErrorView llama a onReintentar', (tester) async {
    var llamadas = 0;
    await tester.pumpWidget(_app(ErrorView(mensaje: 'Falló', onReintentar: () => llamadas++)));
    await tester.tap(find.text('Reintentar'));
    expect(llamadas, 1);
  });


  testWidgets('Fila del partido: "Asignar" o "Editar marcador" solo si se puede pronosticar', (tester) async {
    final futuro = partido(fecha: DateTime.now().add(const Duration(days: 1)));
    await tester.pumpWidget(_app(Column(children: [
      PronosticoFila(partido: futuro, onGuardar: noOp),
      PronosticoFila(partido: futuro, pronostico: pronostico('p1', 1, 0), onGuardar: noOp),
      // Ya empezó / ya pasó la hora / historial (sin onGuardar): sin botón
      PronosticoFila(partido: partido(estado: EstadoPartido.enVivo, gl: 0, gv: 0), onGuardar: noOp),
      PronosticoFila(partido: partido(fecha: DateTime.now().subtract(const Duration(minutes: 1))), onGuardar: noOp),
      PronosticoFila(partido: futuro),
    ])));

    expect(find.text('Asignar marcador'), findsOneWidget);
    expect(find.text('Editar marcador'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Card de quiniela: 2 partidos a la vista y "Ver más" / "Ver menos" para el resto', (tester) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final q = resumen(partidos: [for (var i = 0; i < 5; i++) partido(id: 'p$i', fecha: manana)]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ListView(children: [QuinielaDestacadaCard(quiniela: q)])),
    ));

    // Sin tocar nada ya se ven 2 partidos
    expect(find.byType(PronosticoFila), findsNWidgets(2));
    expect(find.text('Ver más (3)'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver más (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver más (3)'));
    await tester.pumpAndSettle();
    expect(find.byType(PronosticoFila), findsNWidgets(5));

    await tester.ensureVisible(find.text('Ver menos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver menos'));
    await tester.pumpAndSettle();
    expect(find.byType(PronosticoFila), findsNWidgets(2));
  });

  testWidgets('Card de quiniela: el buscador filtra los partidos por equipo', (tester) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final otro = Partido(
      id: 'p2',
      torneoId: 't1',
      torneo: 'Liga',
      torneoActivo: true,
      estado: EstadoPartido.futuro,
      local: const Equipo(id: 'a', nombre: 'Antigua'),
      visitante: const Equipo(id: 'x', nombre: 'Xelajú'),
      fecha: manana,
    );
    final q = resumen(partidos: [partido(fecha: manana), otro]);
    await tester.pumpWidget(_app(QuinielaCompactaCard(quiniela: q)));
    expect(find.byType(PronosticoFila), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'xelaju vs antigua');
    await tester.pump();
    expect(find.byType(PronosticoFila), findsOneWidget);
    expect(find.text('Antigua vs Xelajú'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'cobán');
    await tester.pump();
    expect(find.byType(PronosticoFila), findsNothing);
    expect(find.textContaining('Ningún partido coincide'), findsOneWidget);
  });
  testWidgets('Editor de marcador en celular (360 px) con nombres largos: sin desbordes', (tester) async {
    final largo = Partido(
      id: 'p1',
      torneoId: 't1',
      torneo: 'Liga',
      torneoActivo: true,
      estado: EstadoPartido.futuro,
      local: const Equipo(id: 'a', nombre: 'Club Social y Deportivo Municipal'),
      visitante: const Equipo(id: 'b', nombre: 'Deportivo Comunicaciones Fútbol Club'),
      fecha: DateTime.now().add(const Duration(days: 1)),
    );
    // Ancho de la fila dentro de un card en un celular de 360 px (márgenes de pantalla y del card)
    await tester.pumpWidget(_app(Center(
      child: SizedBox(width: 288, child: PronosticoFila(partido: largo, onGuardar: noOp)),
    )));

    await tester.tap(find.text('Asignar marcador'));
    await tester.pumpAndSettle();

    expect(find.byType(GolesField), findsNWidgets(2));
    expect(find.text('Guardar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
