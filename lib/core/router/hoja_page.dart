import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_theme.dart';

/// Página de go_router que se muestra como hoja inferior (bottom sheet) con el tema TDS.
/// Permite que "Crear quiniela" y "Unirse con código" tengan su propia URL.
class HojaInferiorPage<T> extends Page<T> {
  const HojaInferiorPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
        settings: this,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: TdsColors.surfaceContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        builder: (_) => conTemaTds(child),
      );
}
