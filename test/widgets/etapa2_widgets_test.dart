import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tdsport_app/core/theme/tds_theme.dart';
import 'package:tdsport_app/features/perfil/domain/perfil.dart';
import 'package:tdsport_app/features/perfil/providers/perfil_providers.dart';
import 'package:tdsport_app/features/quinielas/presentation/rivales_screen.dart';
import 'package:tdsport_app/features/suscripcion/domain/pasarela_pago.dart';
import 'package:tdsport_app/features/suscripcion/presentation/pago/pago_screen.dart';
import 'package:tdsport_app/features/suscripcion/providers/suscripcion_providers.dart';

/// Pasarela que nunca termina: deja la pantalla en "procesando".
class _PasarelaColgada implements PasarelaPago {
  final completer = Completer<ResultadoPago>();

  @override
  Future<ResultadoPago> cobrar({required PlanUsuario plan, required DatosTarjeta tarjeta}) => completer.future;
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
}
