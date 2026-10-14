import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';

/// Barra "Ver más (N)" / "Ver menos" debajo de una lista recortada.
class TdsVerMas extends StatelessWidget {
  const TdsVerMas({super.key, required this.ocultos, required this.abierto, required this.onTap});

  /// Cuántos elementos quedan ocultos.
  final int ocultos;
  final bool abierto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TdsColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(abierto ? 'Ver menos' : 'Ver más ($ocultos)',
                  style: TdsText.label(12, color: TdsColors.primaryContainer)),
              const SizedBox(width: 4),
              Icon(abierto ? Icons.expand_less : Icons.expand_more, size: 20, color: TdsColors.primaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  /// Al ocultar desde abajo, regresa la pantalla al inicio de [contexto] (la tarjeta o lista).
  static void regresarA(GlobalKey contexto) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = contexto.currentContext;
      if (c == null || !c.mounted) return;
      Scrollable.ensureVisible(
        c,
        duration: const Duration(milliseconds: 250),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }
}
