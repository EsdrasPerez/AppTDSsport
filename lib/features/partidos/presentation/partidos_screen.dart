import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/tds_ui.dart';
import '../domain/partido.dart';
import '../providers/partidos_providers.dart';
import 'widgets/partido_cards.dart';
import 'widgets/partidos_filtros.dart';

class PartidosScreen extends ConsumerStatefulWidget {
  const PartidosScreen({super.key, this.tabInicial});

  /// Valor de ?tab= (p. ej. "envivo" desde la tarjeta EN VIVO de Inicio).
  final String? tabInicial;

  @override
  ConsumerState<PartidosScreen> createState() => _PartidosScreenState();
}

class _PartidosScreenState extends ConsumerState<PartidosScreen> {
  late TabPartidos _tab = TabPartidos.desdeQuery(widget.tabInicial);
  String? _torneoSeleccionado; // null = todas las ligas

  @override
  void didUpdateWidget(PartidosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabInicial != oldWidget.tabInicial && widget.tabInicial != null) {
      _tab = TabPartidos.desdeQuery(widget.tabInicial);
    }
  }

  Future<void> _recargar() => ref.refresh(partidosProvider(null).future);

  static bool _enTab(Partido p, TabPartidos tab) => switch (tab) {
        TabPartidos.todos => true,
        TabPartidos.enVivo => p.estado == EstadoPartido.enVivo,
        TabPartidos.finalizados => p.estado == EstadoPartido.finalizado,
      };

  /// FUTURO → EN_JUEGO → FINALIZADO → Suspendido. Futuros/en juego por fecha más próxima;
  /// finalizados del más reciente al más antiguo.
  static List<Partido> _ordenar(List<Partido> lista) {
    final sinFecha = DateTime(9999);
    return [...lista]..sort((a, b) {
        final porEstado = a.estado.index.compareTo(b.estado.index);
        if (porEstado != 0) return porEstado;
        final porFecha = (a.fecha ?? sinFecha).compareTo(b.fecha ?? sinFecha);
        return a.estado == EstadoPartido.finalizado ? -porFecha : porFecha;
      });
  }

  @override
  Widget build(BuildContext context) {
    final partidos = ref.watch(partidosProvider(null));

    return Scaffold(
      appBar: TdsAppBar(titulo: 'PARTIDOS', onRefrescar: _recargar),
      body: AsyncValueView(
        value: partidos,
        onReintentar: _recargar,
        data: _buildContenido,
      ),
    );
  }

  Widget _buildContenido(List<Partido> todos) {
    int contar(TabPartidos tab) => todos.where((p) => _enTab(p, tab)).length;
    final torneos = todos.map((p) => p.torneo).toSet().toList()..sort();
    final visibles = _ordenar(todos
        .where((p) => _enTab(p, _tab) && (_torneoSeleccionado == null || p.torneo == _torneoSeleccionado))
        .toList());

    final vacio = switch (_tab) {
      TabPartidos.todos => 'No hay partidos registrados',
      TabPartidos.enVivo => 'No hay partidos en juego ahora mismo',
      TabPartidos.finalizados => 'Aún no hay resultados',
    };

    return RefreshIndicator(
      onRefresh: _recargar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverList.list(
              children: [
                PartidosTabs(seleccionado: _tab, conteo: contar, onChanged: (t) => setState(() => _tab = t)),
                const SizedBox(height: 16),
                LigasChips(
                  torneos: torneos,
                  seleccionado: _torneoSeleccionado,
                  onChanged: (t) => setState(() => _torneoSeleccionado = t),
                ),
                const SizedBox(height: 24),
                SeccionEncabezado(tab: _tab, total: visibles.length),
                if (visibles.isEmpty)
                  VacioView(
                    icono: Icons.sports_soccer_outlined,
                    texto: vacio,
                    subtitulo: 'Desliza hacia abajo para actualizar.',
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.separated(
              itemCount: visibles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => visibles[i].estado == EstadoPartido.futuro
                  ? FuturoCard(partido: visibles[i])
                  : MarcadorCard(partido: visibles[i]),
            ),
          ),
        ],
      ),
    );
  }
}
