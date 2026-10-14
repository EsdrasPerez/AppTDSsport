import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente de Supabase. Los repositorios lo reciben por constructor.
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Cambios de sesión (inicio, cierre, refresco de token).
final sesionProvider = StreamProvider<AuthState>((ref) => ref.watch(supabaseProvider).auth.onAuthStateChange);

/// Id del usuario con sesión, o null. Los providers de datos del usuario lo observan,
/// así que al cerrar sesión o cambiar de cuenta se recalculan solos.
final usuarioIdProvider = Provider<String?>((ref) {
  ref.watch(sesionProvider);
  return ref.watch(supabaseProvider).auth.currentUser?.id;
});
