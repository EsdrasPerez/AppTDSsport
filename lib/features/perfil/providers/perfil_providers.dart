import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/perfil_repository.dart';
import '../domain/perfil.dart';

final perfilRepositoryProvider = Provider((ref) => PerfilRepository(ref.watch(supabaseProvider)));

/// Perfil del usuario con sesión (nombre, es_pro, es_admin). null si no hay sesión.
final perfilActualProvider = FutureProvider<Perfil?>((ref) async {
  final id = ref.watch(usuarioIdProvider);
  if (id == null) return null;
  return ref.watch(perfilRepositoryProvider).obtenerPerfil(id);
});
