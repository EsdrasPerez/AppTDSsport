import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../partidos/providers/partidos_providers.dart';
import '../data/quinielas_repository.dart';
import '../domain/quiniela_models.dart';

final quinielasRepositoryProvider = Provider(
  (ref) => QuinielasRepository(ref.watch(supabaseProvider), ref.watch(partidosRepositoryProvider)),
);

/// TODAS las quinielas del usuario (una sola carga, compartida por Inicio, Mis quinielas y Perfil).
final misQuinielasProvider = FutureProvider<List<ResumenQuiniela>>((ref) async {
  final id = ref.watch(usuarioIdProvider);
  if (id == null) return [];
  return ref.watch(quinielasRepositoryProvider).obtenerMisQuinielas(id);
});

/// Derivado: solo las activas (en curso o por iniciar). Sin consultas nuevas.
final quinielasActivasProvider = Provider<AsyncValue<List<ResumenQuiniela>>>((ref) {
  return ref.watch(misQuinielasProvider).whenData((l) => l.where((q) => q.activa).toList());
});

/// Derivado: solo las finalizadas, por fecha del último partido (más reciente primero).
final historialQuinielasProvider = Provider<AsyncValue<List<ResumenQuiniela>>>((ref) {
  return ref.watch(misQuinielasProvider).whenData((l) {
    final finalizadas = l.where((q) => !q.activa).toList();
    finalizadas.sort((a, b) => (b.fechaUltimoPartido ?? DateTime(0)).compareTo(a.fechaUltimoPartido ?? DateTime(0)));
    return finalizadas;
  });
});

/// Detalle de una quiniela (compartido por Detalle y Participante).
final quinielaDetalleProvider = FutureProvider.family<DetalleQuiniela, String>((ref, quinielaId) {
  final miId = ref.watch(usuarioIdProvider);
  return ref.watch(quinielasRepositoryProvider).obtenerDetalle(quinielaId, miId);
});

/// Pronósticos de un participante en una quiniela (Pantalla Participante).
final pronosticosDeProvider =
    FutureProvider.family<Map<String, Pronostico>, ({String quinielaId, String usuarioId})>((ref, args) {
  ref.watch(usuarioIdProvider);
  return ref.watch(quinielasRepositoryProvider).obtenerPronosticos(args.quinielaId, args.usuarioId);
});

/// Tabla de posiciones de una quiniela (participantes con su plan).
final posicionesProvider = FutureProvider.family<List<Posicion>, String>((ref, quinielaId) {
  ref.watch(usuarioIdProvider);
  return ref.watch(quinielasRepositoryProvider).obtenerPosiciones(quinielaId);
});

/// Pronósticos de todos los participantes para un partido (pantalla de rivales), por usuario.
final pronosticosDePartidoProvider =
    FutureProvider.family<Map<String, Pronostico>, ({String quinielaId, String partidoId})>((ref, args) {
  ref.watch(usuarioIdProvider);
  return ref.watch(quinielasRepositoryProvider).obtenerPronosticosDePartido(args.quinielaId, args.partidoId);
});
