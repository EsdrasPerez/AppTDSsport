import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_shell.dart';
import '../router/rutas.dart';
import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';

/// Regresa a la pantalla anterior; si no hay (se entró por URL), va al Panel principal.
void volverSeguro(BuildContext context, [Object? resultado]) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    Navigator.maybePop(context, resultado);
  } else if (router.canPop()) {
    context.pop(resultado);
  } else {
    context.go(Rutas.inicio);
  }
}

/// ¿Hay una pantalla anterior? (funciona también sin GoRouter, p. ej. en pruebas)
bool puedeVolver(BuildContext context) => GoRouter.maybeOf(context)?.canPop() ?? Navigator.canPop(context);

/// AppBar estándar. A la izquierda muestra automáticamente:
/// - flecha atrás si hay a dónde volver (pantallas de detalle);
/// - el botón de menú en móvil si es una pantalla principal del menú.
class TdsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TdsAppBar({
    super.key,
    required this.titulo,
    this.onRefrescar,
    this.acciones = const [],
  });

  final String titulo;
  final VoidCallback? onRefrescar;
  final List<Widget> acciones;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final hayAnterior = puedeVolver(context);
    final conMenu = !hayAnterior && !esEscritorio(context) && shellScaffoldKey.currentState?.hasDrawer == true;

    final Widget? leading = hayAnterior
        ? IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Regresar', onPressed: () => volverSeguro(context))
        : conMenu
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menú',
                onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
              )
            : null;

    return AppBar(
      backgroundColor: TdsColors.superficie,
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 20 : 0,
      title: Text(titulo, style: TdsText.headline(22)),
      actions: [
        ...acciones,
        if (onRefrescar != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: TdsColors.acento),
            tooltip: 'Actualizar',
            onPressed: onRefrescar,
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
