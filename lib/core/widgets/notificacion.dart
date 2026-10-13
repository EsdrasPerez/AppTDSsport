import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TipoNotificacion { exito, error, advertencia, info }

/// Notificaciones en "cajitas" con la paleta del dashboard.
///
/// Uso:
///   Notificacion.exito(context, 'Perfil guardado');
///   Notificacion.excepcion(context, e); // dentro de un catch
class Notificacion {
  static const _superficie = Color(0xFF1E293B);

  static void exito(BuildContext context, String mensaje, {String titulo = '¡Listo!'}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.exito);

  static void error(BuildContext context, String mensaje, {String titulo = 'Ocurrió un error'}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.error);

  static void advertencia(BuildContext context, String mensaje, {String titulo = 'Atención'}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.advertencia);

  static void info(BuildContext context, String mensaje, {String titulo = 'Información'}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.info);

  /// Muestra una excepción con un mensaje legible en lugar del toString() crudo.
  static void excepcion(BuildContext context, Object e, {String titulo = 'Ocurrió un error'}) =>
      error(context, mensajeDeExcepcion(e), titulo: titulo);

  static String mensajeDeExcepcion(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return e.message;
    final texto = e.toString();
    if (texto.contains('SocketException') ||
        texto.contains('Failed host lookup') ||
        texto.contains('ClientException')) {
      return 'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
    }
    return texto.replaceFirst('Exception: ', '');
  }

  static void mostrar(
    BuildContext context,
    String mensaje, {
    required String titulo,
    required TipoNotificacion tipo,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final anchoPantalla = MediaQuery.of(context).size.width;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          width: min(anchoPantalla - 32, 420),
          duration: Duration(seconds: tipo == TipoNotificacion.error ? 5 : 3),
          content: _Caja(
            titulo: titulo,
            mensaje: mensaje,
            tipo: tipo,
            onCerrar: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }
}

class _Caja extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final VoidCallback onCerrar;

  const _Caja({
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.onCerrar,
  });

  (Color, IconData) get _estilo => switch (tipo) {
        TipoNotificacion.exito => (const Color(0xFF10B981), Icons.check_circle_outline),
        TipoNotificacion.error => (const Color(0xFFEF4444), Icons.error_outline),
        TipoNotificacion.advertencia => (const Color(0xFFF59E0B), Icons.warning_amber_rounded),
        TipoNotificacion.info => (const Color(0xFF3B82F6), Icons.info_outline),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icono) = _estilo;

    return Container(
      decoration: BoxDecoration(
        color: Notificacion._superficie,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja de color a la izquierda
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icono, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              mensaje,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onCerrar,
                        icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
