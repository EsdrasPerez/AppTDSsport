import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';
import '../utils/errores.dart';
import 'tds_buttons.dart';

/// Estado "cargando" estándar.
class CargandoView extends StatelessWidget {
  const CargandoView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

/// Estado "error" estándar, con botón Reintentar.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.mensaje, required this.onReintentar});

  /// Crea la vista a partir de una excepción (sin mostrar el texto crudo).
  ErrorView.desde(Object error, {super.key, required this.onReintentar})
      : mensaje = mensajeDeExcepcion(error);

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: TdsColors.error, size: 48),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center, style: TdsText.body(14, color: TdsColors.onSurfaceVariant)),
            const SizedBox(height: 20),
            TdsPillButton(icon: Icons.refresh, label: 'Reintentar', primary: true, onTap: onReintentar),
          ],
        ),
      ),
    );
  }
}

/// Estado "vacío" estándar, con una acción útil opcional.
class VacioView extends StatelessWidget {
  const VacioView({
    super.key,
    required this.icono,
    required this.texto,
    this.subtitulo,
    this.acciones = const [],
    this.compacto = false,
  });

  final IconData icono;
  final String texto;
  final String? subtitulo;
  final List<Widget> acciones;

  /// Sin espacio vertical extra (para usar dentro de listas o cards).
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compacto ? 16 : 48, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: TdsColors.outlineVariant, size: 56),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center, style: TdsText.label(15)),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(subtitulo!, textAlign: TextAlign.center, style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
          ],
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: acciones),
          ],
        ],
      ),
    );
  }
}

/// Pinta un [AsyncValue] de Riverpod con los estados estándar.
/// Mientras recarga, si ya hay datos, los sigue mostrando.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    required this.onReintentar,
    this.cargando,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onReintentar;
  final Widget? cargando;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => cargando ?? const CargandoView(),
      error: (e, _) => ErrorView.desde(e, onReintentar: onReintentar),
    );
  }
}
