import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tdsport_app/core/widgets/estado_carga.dart';
import 'package:tdsport_app/core/widgets/tds_buttons.dart';
import 'package:tdsport_app/features/partidos/domain/partido.dart';
import 'package:tdsport_app/features/quinielas/presentation/widgets/pronostico_card.dart';

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

  testWidgets('ErrorView llama a onReintentar', (tester) async {
    var llamadas = 0;
    await tester.pumpWidget(_app(ErrorView(mensaje: 'Falló', onReintentar: () => llamadas++)));
    await tester.tap(find.text('Reintentar'));
    expect(llamadas, 1);
  });
}
