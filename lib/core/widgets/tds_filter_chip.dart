import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';
import 'tds_pill.dart';

/// Chip de filtro (lima cuando está activo), con punto de color, ícono y contador opcionales.
class TdsFilterChip extends StatelessWidget {
  const TdsFilterChip({
    super.key,
    required this.texto,
    required this.activo,
    required this.onTap,
    this.cantidad,
    this.punto,
    this.icono,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final int? cantidad;
  final Color? punto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final color = activo ? TdsColors.onPrimaryContainer : TdsColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: activo,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: activo ? TdsColors.primaryContainer : TdsColors.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
              boxShadow: activo
                  ? [BoxShadow(color: TdsColors.primaryContainer.withValues(alpha: 0.25), blurRadius: 16)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[Icon(icono, size: 16, color: color), const SizedBox(width: 6)],
                if (punto != null && icono == null) ...[TdsDot(color: punto!), const SizedBox(width: 6)],
                Text(texto, style: TdsText.label(13, color: color)),
                if (cantidad != null) ...[
                  const SizedBox(width: 6),
                  Text('$cantidad', style: TdsText.label(12, color: color)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila horizontal desplazable de chips.
class TdsFilterChipsRow extends StatelessWidget {
  const TdsFilterChipsRow({super.key, required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: chips),
    );
  }
}
