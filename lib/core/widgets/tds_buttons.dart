import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';

/// Botón en forma de píldora (lima si es primario). Con [onTap] null queda deshabilitado.
class TdsPillButton extends StatelessWidget {
  const TdsPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.cargando = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null && !cargando;
    final fg = primary ? TdsColors.onPrimaryContainer : TdsColors.onSurface;

    return Opacity(
      opacity: habilitado || cargando ? 1 : 0.4,
      child: Material(
        color: primary ? TdsColors.primaryContainer : TdsColors.surfaceContainerHighest,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cargando)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                else
                  Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TdsText.label(13, color: fg))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón circular con ícono. Siempre con tooltip (accesibilidad).
class TdsCircleButton extends StatelessWidget {
  const TdsCircleButton({super.key, required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: TdsColors.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: TdsColors.onSurface)),
        ),
      ),
    );
  }
}
