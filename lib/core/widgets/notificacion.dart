import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';
import '../utils/errores.dart' as errores;

enum TipoNotificacion { exito, error, advertencia, info }

/// Notificaciones en "cajitas" con la paleta TDS. Es la única forma de mostrar avisos en la app.
///
/// Uso:
///   Notificacion.exito(context, 'Perfil guardado');
///   Notificacion.excepcion(context, e); // dentro de un catch
class Notificacion {
  Notificacion._();

  static void exito(BuildContext context, String mensaje, {String titulo = '¡Listo!', SnackBarAction? accion}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.exito, accion: accion);

  static void error(BuildContext context, String mensaje, {String titulo = 'Ocurrió un error'}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.error);

  static void advertencia(BuildContext context, String mensaje, {String titulo = 'Atención'}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.advertencia);

  static void info(BuildContext context, String mensaje, {String titulo = 'Información', SnackBarAction? accion}) =>
      mostrar(context, mensaje, titulo: titulo, tipo: TipoNotificacion.info, accion: accion);

  /// Muestra una excepción con un mensaje legible en lugar del toString() crudo.
  static void excepcion(BuildContext context, Object e, {String titulo = 'Ocurrió un error'}) =>
      error(context, mensajeDeExcepcion(e), titulo: titulo);

  static String mensajeDeExcepcion(Object e) => errores.mensajeDeExcepcion(e);

  /// Banner arriba de la pantalla (no abajo como las cajitas), para avisos importantes.
  /// Se cierra solo después de [duracion] o con la X; sigue visible aunque se cambie de pantalla.
  static void banner(
    BuildContext context,
    String mensaje, {
    required String titulo,
    TipoNotificacion tipo = TipoNotificacion.exito,
    Duration duracion = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    var cerrado = false;

    messenger.hideCurrentMaterialBanner();
    messenger
        .showMaterialBanner(
          MaterialBanner(
            backgroundColor: Colors.transparent,
            dividerColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            content: _Caja(titulo: titulo, mensaje: mensaje, tipo: tipo, onCerrar: messenger.hideCurrentMaterialBanner),
            actions: const [SizedBox.shrink()],
          ),
        )
        .closed
        .whenComplete(() => cerrado = true);

    // Solo cierra este banner si sigue en pantalla (no uno que se haya mostrado después)
    Timer(duracion, () {
      if (!cerrado && messenger.mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  static void mostrar(
    BuildContext context,
    String mensaje, {
    required String titulo,
    required TipoNotificacion tipo,
    SnackBarAction? accion,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final anchoPantalla = MediaQuery.sizeOf(context).width;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          width: min(anchoPantalla - 32, 420),
          duration: Duration(seconds: accion != null ? 8 : (tipo == TipoNotificacion.error ? 5 : 3)),
          content: _Caja(
            titulo: titulo,
            mensaje: mensaje,
            tipo: tipo,
            accion: accion,
            onCerrar: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }
}

class _Caja extends StatelessWidget {
  const _Caja({
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.onCerrar,
    this.accion,
  });

  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final VoidCallback onCerrar;
  final SnackBarAction? accion;

  (Color, IconData) get _estilo => switch (tipo) {
        TipoNotificacion.exito => (TdsColors.exito, Icons.check_circle_outline),
        TipoNotificacion.error => (TdsColors.error, Icons.error_outline),
        TipoNotificacion.advertencia => (TdsColors.advertencia, Icons.warning_amber_rounded),
        TipoNotificacion.info => (TdsColors.acento, Icons.info_outline),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icono) = _estilo;

    return Container(
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                            Text(titulo, style: TdsText.label(14, color: color)),
                            const SizedBox(height: 3),
                            Text(mensaje, style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
                            if (accion != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                                  onPressed: () {
                                    onCerrar();
                                    accion!.onPressed();
                                  },
                                  child: Text(accion!.label, style: TdsText.label(13, color: color)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onCerrar,
                        icon: const Icon(Icons.close, color: TdsColors.onSurfaceVariant, size: 18),
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
