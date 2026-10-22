import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';

/// Card oscura redondeada, con brillo lima opcional en la esquina.
class TdsCard extends StatelessWidget {
  const TdsCard({
    super.key,
    required this.child,
    this.glow = false,
    this.color = TdsColors.surfaceContainer,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  }) : modulo = false;

  /// Estilo del card "¡Módulo de Quinielas Deportivo!": degradado, borde lima suave y esquinas de 24.
  /// Lo usan todos los cards del panel principal para que se vean iguales.
  const TdsCard.modulo({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
  })  : glow = false,
        color = TdsColors.superficie,
        modulo = true;

  final bool modulo;
  final Widget child;
  final bool glow;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final contenido = Stack(
      children: [
        if (glow)
          Positioned(
            top: -48,
            right: -48,
            child: IgnorePointer(
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TdsColors.primaryContainer.withValues(alpha: 0.12),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: modulo
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [TdsColors.superficieAlta, TdsColors.superficie],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: TdsColors.acento.withValues(alpha: 0.3)),
            )
          : BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
      child: onTap == null
          ? contenido
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, child: contenido),
            ),
    );
  }
}
