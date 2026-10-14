import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'rutas.dart';

/// Avisa a GoRouter que vuelva a evaluar [redirectSesion] cuando se inicia o cierra sesión.
class RefrescoSesion extends ChangeNotifier {
  RefrescoSesion() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Sin sesión: solo login, registro y recuperar. Con sesión: login/registro llevan al dashboard
/// (o a la ruta que se quería abrir antes de iniciar sesión).
String? redirectSesion(BuildContext context, GoRouterState state) {
  final sesion = Supabase.instance.client.auth.currentSession;
  final ruta = state.matchedLocation;

  if (sesion == null) {
    if (Rutas.publicas.contains(ruta)) return null;
    return '${Rutas.login}?desde=${Uri.encodeComponent(state.uri.toString())}';
  }

  if (ruta == Rutas.login || ruta == Rutas.registro) {
    final desde = state.uri.queryParameters['desde'];
    return (desde != null && desde.startsWith('/') && !desde.startsWith(Rutas.login)) ? desde : Rutas.inicio;
  }
  return null;
}
