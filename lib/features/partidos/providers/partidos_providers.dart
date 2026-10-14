import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/partidos_repository.dart';
import '../domain/partido.dart';

final partidosRepositoryProvider = Provider((ref) => PartidosRepository(ref.watch(supabaseProvider)));

/// Partidos de un torneo, o todos si el argumento es null.
final partidosProvider = FutureProvider.family<List<Partido>, String?>((ref, torneoId) {
  ref.watch(usuarioIdProvider); // RLS: solo usuarios autenticados
  return ref.watch(partidosRepositoryProvider).obtenerPartidos(torneoId: torneoId);
});

final torneosActivosProvider = FutureProvider<List<Torneo>>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(partidosRepositoryProvider).obtenerTorneosActivos();
});

/// Torneos activos que tienen al menos un partido: los únicos que se ofrecen para crear quiniela.
final torneosConPartidosProvider = FutureProvider<List<Torneo>>((ref) async {
  final (torneos, partidos) = await (
    ref.watch(torneosActivosProvider.future),
    ref.watch(partidosProvider(null).future),
  ).wait;
  final conPartidos = partidos.map((p) => p.torneoId).toSet();
  return torneos.where((t) => conPartidos.contains(t.id)).toList();
});
