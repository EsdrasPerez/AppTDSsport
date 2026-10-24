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
          _tab(TabPartidos.todos, 'TODOS'),
          _tab(
            TabPartidos.enVivo,
            conteo(TabPartidos.enVivo) > 0 ? 'EN VIVO (${conteo(TabPartidos.enVivo)})' : 'EN VIVO',
            puntoVivo: conteo(TabPartidos.enVivo) > 0,
          ),
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

/// Filtro temporal para ver los partidos de la jornada próxima o de hoy/semana.
enum FiltroTemporal {
  jornadaActual,
  hoy,
  semana;
}

/// Selector rápido de partidos de la jornada próxima, hoy o esta semana.
class FiltrosTemporalesChips extends StatelessWidget {
  const FiltrosTemporalesChips({
    super.key,
    required this.seleccionado,
    required this.onChanged,
  });

  final FiltroTemporal seleccionado;
  final ValueChanged<FiltroTemporal> onChanged;

  @override
  Widget build(BuildContext context) {
    return TdsFilterChipsRow(
      chips: [
        TdsFilterChip(
          texto: '⚡ Jornada Próxima',
          activo: seleccionado == FiltroTemporal.jornadaActual,
          onTap: () => onChanged(FiltroTemporal.jornadaActual),
        ),
        TdsFilterChip(
          texto: 'Hoy',
          activo: seleccionado == FiltroTemporal.hoy,
          icono: Icons.today_outlined,
          onTap: () => onChanged(FiltroTemporal.hoy),
        ),
        TdsFilterChip(
          texto: 'Esta semana',
          activo: seleccionado == FiltroTemporal.semana,
          icono: Icons.date_range_outlined,
          onTap: () => onChanged(FiltroTemporal.semana),
        ),
      ],
    );
  }
}

/// Carrusel horizontal para seleccionar jornada / fase cuando se filtra por liga.
class JornadasChips extends StatelessWidget {
  const JornadasChips({
    super.key,
    required this.jornadas,
    required this.seleccionada,
    required this.onChanged,
  });

  final List<String> jornadas;
  final String? seleccionada;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TdsFilterChipsRow(
      chips: [
        TdsFilterChip(
          texto: 'Todas las jornadas',
          activo: seleccionada == null,
          icono: Icons.grid_view_rounded,
          onTap: () => onChanged(null),
        ),
        for (final j in jornadas)
          TdsFilterChip(
            texto: j,
            activo: seleccionada == j,
            onTap: () => onChanged(j),
          ),
      ],
    );
  }
}

/// Título de la sección según el tab y los filtros seleccionados.
class SeccionEncabezado extends StatelessWidget {
  const SeccionEncabezado({
    super.key,
    required this.tab,
    required this.total,
    this.busqueda,
    this.subtitulo,
  });

  final TabPartidos tab;
  final int total;
  final String? busqueda;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    if (busqueda != null && busqueda!.trim().isNotEmpty) {
      return Row(
        children: [
          const Icon(Icons.search, color: TdsColors.primaryContainer, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Resultados para "${busqueda!.trim()}"',
              overflow: TextOverflow.ellipsis,
              style: TdsText.headline(18),
            ),
          ),
          Text('$total ${total == 1 ? 'partido' : 'partidos'}', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
        ],
      );
    }

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

    final (icono, tituloPredeterminado) = tab == TabPartidos.todos
        ? (Icons.sports_soccer, 'Partidos')
        : (Icons.flag_outlined, 'Resultados');

    return Row(
      children: [
        Icon(icono, color: TdsColors.primaryContainer, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(tituloPredeterminado, style: TdsText.headline(20))),
        Text(subtitulo ?? '$total ${total == 1 ? 'partido' : 'partidos'}',
            style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
      ],
    );
  }
}
