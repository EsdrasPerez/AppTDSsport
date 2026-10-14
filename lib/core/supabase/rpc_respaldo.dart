import 'package:supabase_flutter/supabase_flutter.dart';

/// Códigos de PostgREST cuando la función o la vista todavía no existen en la base.
const _noExiste = {'PGRST202', 'PGRST205', '42P01', '42883'};

/// Ejecuta [principal] (RPC o vista de la migración 02). Si la base aún no tiene esa migración,
/// usa [respaldo] (el camino anterior) para que la app siga funcionando.
// TODO(decision): cuando la migración 20261013120000 esté aplicada en todos los ambientes, quitar los respaldos.
Future<T> conRespaldo<T>(Future<T> Function() principal, Future<T> Function() respaldo) async {
  try {
    return await principal();
  } on PostgrestException catch (e) {
    if (_noExiste.contains(e.code)) return respaldo();
    rethrow;
  }
}
