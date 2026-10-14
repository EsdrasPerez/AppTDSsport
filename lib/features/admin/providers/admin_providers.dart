import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../partidos/domain/partido.dart';
import '../../partidos/providers/partidos_providers.dart';
import '../../quinielas/providers/quinielas_providers.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.watch(supabaseProvider)));

final adminTorneosProvider = FutureProvider<List<Torneo>>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(adminRepositoryProvider).obtenerTorneos();
});

final adminEquiposProvider = FutureProvider<List<Equipo>>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(adminRepositoryProvider).obtenerEquipos();
});

/// Acciones de administración. Después de cada cambio se invalidan los datos que dependen de él.
class AdminAcciones {
  AdminAcciones(this._ref);

  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<void> guardarTorneo({String? id, required String nombre, required String formato, required bool activo}) async {
    await _repo.guardarTorneo(id: id, nombre: nombre, formato: formato, activo: activo);
    _ref
      ..invalidate(adminTorneosProvider)
      ..invalidate(torneosActivosProvider)
      ..invalidate(partidosProvider)
      ..invalidate(misQuinielasProvider);
  }

  Future<void> guardarEquipo({String? id, required String nombre, String? escudoUrl}) async {
    await _repo.guardarEquipo(id: id, nombre: nombre, escudoUrl: escudoUrl);
    _ref
      ..invalidate(adminEquiposProvider)
      ..invalidate(partidosProvider);
  }

  Future<String> subirEscudo(Uint8List bytes, String nombre) => _repo.subirEscudo(bytes, nombre);

  Future<void> crearPartido({
    required String torneoId,
    required String localId,
    required String visitanteId,
    required DateTime fecha,
  }) async {
    await _repo.crearPartido(torneoId: torneoId, localId: localId, visitanteId: visitanteId, fecha: fecha);
    _despuesDeCambiarPartidos();
  }

  Future<void> actualizarPartido({
    required String partidoId,
    required EstadoPartido estado,
    int? golesLocal,
    int? golesVisitante,
  }) async {
    await _repo.actualizarPartido(
        partidoId: partidoId, estado: estado, golesLocal: golesLocal, golesVisitante: golesVisitante);
    _despuesDeCambiarPartidos();
  }

  /// Los puntos y posiciones los recalcula la base; aquí solo se vuelven a leer.
  void _despuesDeCambiarPartidos() {
    _ref
      ..invalidate(partidosProvider)
      ..invalidate(misQuinielasProvider)
      ..invalidate(quinielaDetalleProvider);
  }
}

final adminAccionesProvider = Provider(AdminAcciones.new);
