import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quiniela_models.dart';
import 'quinielas_providers.dart';

/// Acciones sobre quinielas. Cada una invalida los providers afectados al terminar,
/// así las pantallas se actualizan sin callbacks ni recargas manuales.
class QuinielasAcciones {
  QuinielasAcciones(this._ref);

  final Ref _ref;

  Future<({String id, String codigo})> crear({
    required TipoQuiniela tipo,
    required String torneoId,
    String? partidoId,
    required String nombre,
    required int limiteUsuarios,
  }) async {
    final creada = await _ref.read(quinielasRepositoryProvider).crearQuiniela(
          tipo: tipo,
          torneoId: torneoId,
          partidoId: partidoId,
          nombre: nombre,
          limiteUsuarios: limiteUsuarios,
        );
    _ref.invalidate(misQuinielasProvider);
    return creada;
  }

  /// Devuelve el id de la quiniela.
  Future<String> unirse(String codigo) async {
    final id = await _ref.read(quinielasRepositoryProvider).unirse(codigo);
    _ref.invalidate(misQuinielasProvider);
    _ref.invalidate(quinielaDetalleProvider(id));
    return id;
  }

  Future<void> guardarPronostico({
    required String quinielaId,
    required String partidoId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    try {
      await _ref.read(quinielasRepositoryProvider).guardarPronostico(
            quinielaId: quinielaId,
            partidoId: partidoId,
            golesLocal: golesLocal,
            golesVisitante: golesVisitante,
          );
    } finally {
      // También si falla (p. ej. 42501): así se ve el estado real del partido
      _ref.invalidate(quinielaDetalleProvider(quinielaId));
      _ref.invalidate(misQuinielasProvider);
      _ref.invalidate(pronosticosDePartidoProvider((quinielaId: quinielaId, partidoId: partidoId)));
    }
  }
}

final quinielasAccionesProvider = Provider(QuinielasAcciones.new);
