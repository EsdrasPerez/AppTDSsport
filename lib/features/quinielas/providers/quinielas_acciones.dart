import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../suscripcion/providers/suscripcion_providers.dart';
import 'quinielas_providers.dart';

/// Acciones sobre quinielas. Cada una invalida los providers afectados al terminar,
/// así las pantallas se actualizan sin callbacks ni recargas manuales.
class QuinielasAcciones {
  QuinielasAcciones(this._ref);

  final Ref _ref;

  /// Quinielas ACTIVAS del usuario (en curso o por iniciar): las que creó y las de amigos.
  /// Las finalizadas no cuentan para el límite del plan.
  Future<({int creadas, int unidas})> _activas() async {
    final miId = _ref.read(usuarioIdProvider);
    final activas = (await _ref.read(misQuinielasProvider.future)).where((q) => q.activa);
    final creadas = activas.where((q) => q.esCreador(miId)).length;
    return (creadas: creadas, unidas: activas.length - creadas);
  }

  Future<({String id, String codigo})> crear({
    required String torneoId,
    required String nombre,
    required int limiteUsuarios,
  }) async {
    final (creadas: creadas, unidas: unidas) = await _activas();
    (await _ref.read(limiteQuinielasProvider.future)).validarCrear(creadas: creadas, unidas: unidas);

    final creada = await _ref.read(quinielasRepositoryProvider).crearQuiniela(
          torneoId: torneoId,
          nombre: nombre,
          limiteUsuarios: limiteUsuarios,
        );
    _ref.invalidate(misQuinielasProvider);
    return creada;
  }

  /// Devuelve el id de la quiniela.
  Future<String> unirse(String codigo) async {
    final (creadas: creadas, unidas: unidas) = await _activas();
    (await _ref.read(limiteQuinielasProvider.future)).validarUnirse(creadas: creadas, unidas: unidas);

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
