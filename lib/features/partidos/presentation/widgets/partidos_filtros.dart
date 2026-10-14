import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_ui.dart';

enum TabPartidos {
  todos,
  enVivo,
  finalizados;

  /// Valor de ?tab= en la URL.
  static TabPartidos desdeQuery(String? valor) => switch (valor) {
        'envivo' => enVivo,
        'finalizados' => finalizados,
        _ => todos,
      };
}

/// Sub-tabs TODOS / EN VIVO / FINALIZADOS.
class PartidosTabs extends StatelessWidget {
  const PartidosTabs({
    super.key,
    required this.seleccionado,
    required this.conteo,
    required this.onChanged,
  });

  final TabPartidos seleccionado;
  final int Function(TabPartidos) conteo;
  final ValueChanged<TabPartidos> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _tab(TabPartidos.todos, 'TODOS (${conteo(TabPartidos.todos)})'),
          _tab(TabPartidos.enVivo, 'EN VIVO (${conteo(TabPartidos.enVivo)})', puntoVivo: true),
          _tab(TabPartidos.finalizados, 'FINALIZADOS'),
        ],
      ),
    );
  }

  Widget _tab(TabPartidos valor, String texto, {bool puntoVivo = false}) {
    final activo = seleccionado == valor;
    return Expanded(
      child: Semantics(
        button: true,
        selected: activo,
        child: GestureDetector(
          onTap: () => onChanged(valor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: activo ? TdsColors.surfaceContainerHighest : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: activo
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (puntoVivo) ...[
                  const TdsDot(color: TdsColors.error, pulse: true),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    texto,
                    overflow: TextOverflow.ellipsis,
                    style: TdsText.label(13, color: activo ? TdsColors.onSurface : TdsColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carrusel horizontal de chips para filtrar por liga (null = todas).
class LigasChips extends StatelessWidget {
  const LigasChips({
    super.key,
    required this.torneos,
    required this.seleccionado,
    required this.onChanged,
  });

  final List<String> torneos;
  final String? seleccionado;
  final ValueChanged<String?> onChanged;

  static const _coloresLiga = [
    TdsColors.secondaryContainer,
    TdsColors.primaryFixedDim,
    TdsColors.tertiaryFixed,
    TdsColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    return TdsFilterChipsRow(
      chips: [
        TdsFilterChip(
          texto: 'Todas las Ligas',
          activo: seleccionado == null,
          icono: Icons.sports_soccer,
          onTap: () => onChanged(null),
        ),
        for (var i = 0; i < torneos.length; i++)
          TdsFilterChip(
            texto: torneos[i],
            activo: seleccionado == torneos[i],
            punto: _coloresLiga[i % _coloresLiga.length],
            onTap: () => onChanged(torneos[i]),
          ),
      ],
    );
  }
}

/// Título de la sección según el tab seleccionado.
class SeccionEncabezado extends StatelessWidget {
  const SeccionEncabezado({super.key, required this.tab, required this.total});

  final TabPartidos tab;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (tab == TabPartidos.enVivo) {
      return Row(
        children: [
          TdsPill(
            color: TdsColors.errorContainer,
            child: Row(
              children: [
                const TdsDot(color: TdsColors.error, size: 6, pulse: true),
                const SizedBox(width: 4),
                Text('EN DIRECTO AHORA',
                    style: TdsText.label(11, color: TdsColors.onErrorContainer, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('($total en juego)', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
        ],
      );
    }

    final (icono, titulo, subtitulo) = tab == TabPartidos.todos
        ? (Icons.sports_soccer, 'Todos los Partidos', '$total partidos')
        : (Icons.flag_outlined, 'Resultados', '$total jugados');

    return Row(
      children: [
        Icon(icono, color: TdsColors.primaryContainer, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(titulo, style: TdsText.headline(20))),
        Text(subtitulo, style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
      ],
    );
  }
}
