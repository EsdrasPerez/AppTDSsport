import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tds_colors.dart';
import '../../../core/widgets/tds_ui.dart';
import '../domain/partido.dart';
import '../providers/partidos_providers.dart';
import 'widgets/partidos_filtros.dart';
import 'widgets/torneo_secciones.dart';

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
  String _busqueda = '';
  FiltroTemporal _filtroTemporal = FiltroTemporal.jornadaActual;
  String? _jornadaSeleccionada;
  int _limite = 6;
  late final TextEditingController _busquedaController;

  @override
  void initState() {
    super.initState();
    _busquedaController = TextEditingController();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

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
        TabPartidos.enVivo => p.estaEnJuego,
        TabPartidos.finalizados => p.estado == EstadoPartido.finalizado,
      };

  static bool _esHoy(DateTime? fecha) {
    if (fecha == null) return false;
    final hoy = DateTime.now();
    return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
  }

  static bool _esEstaSemana(DateTime? fecha) {
    if (fecha == null) return false;
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final finSemana = inicioSemana.add(const Duration(days: 7));
    final f = DateTime(fecha.year, fecha.month, fecha.day);
    final i = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    final e = DateTime(finSemana.year, finSemana.month, finSemana.day);
    return (f.isAtSameMomentAs(i) || f.isAfter(i)) && f.isBefore(e);
  }

  List<String> _obtenerJornadas(List<Partido> partidos) {
    final lista = <String>[];
    for (final p in partidos) {
      final j = p.nombreJornada;
      if (!lista.contains(j)) {
        lista.add(j);
      }
    }
    return lista;
  }

  String? _determinarJornadaActiva(List<Partido> partidos, List<String> jornadas) {
    if (jornadas.isEmpty) return null;
    final ahora = DateTime.now();
    for (final j in jornadas) {
      final enJornada = partidos.where((p) => p.nombreJornada == j);
      if (enJornada.any((p) =>
          p.estaEnJuego ||
          (p.estado == EstadoPartido.futuro && (p.fecha == null || p.fecha!.isAfter(ahora))))) {
        return j;
      }
    }
    return jornadas.first;
  }

  /// EN_JUEGO → FUTURO → FINALIZADO → Suspendido.
  static List<Partido> _ordenar(List<Partido> lista) {
    final sinFecha = DateTime(9999);
    return [...lista]..sort((a, b) {
        final rankA = a.estaEnJuego ? 0 : (a.estado == EstadoPartido.futuro ? 1 : a.estado.index + 1);
        final rankB = b.estaEnJuego ? 0 : (b.estado == EstadoPartido.futuro ? 1 : b.estado.index + 1);
        final porEstado = rankA.compareTo(rankB);
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

  Widget _buildContenido(List<Partido> lista) {
    final todos = lista.where((p) => p.torneoActivo || p.estaEnJuego).toList();
    int contar(TabPartidos tab) => todos.where((p) => _enTab(p, tab)).length;
    final torneos = todos.map((p) => p.torneo).toSet().toList()..sort();
    final enTabActual = todos.where((p) => _enTab(p, _tab)).toList();

    List<Partido> pool;
    String? subtituloEncabezado;
    final tieneBusqueda = _busqueda.trim().isNotEmpty;

    if (tieneBusqueda) {
      // 1. Si el usuario escribe, busca en todos los partidos (equipos, torneo, estadio)
      pool = _ordenar(enTabActual
          .where((p) =>
              (_torneoSeleccionado == null || p.torneo == _torneoSeleccionado) &&
              p.coincideConBusqueda(_busqueda))
          .toList());
      subtituloEncabezado = '${pool.length} ${pool.length == 1 ? 'partido' : 'partidos'}';
    } else if (_torneoSeleccionado != null) {
      // 2. Si hay liga seleccionada, enfocar en la jornada actual / seleccionada
      final partidosDelTorneo = enTabActual.where((p) => p.torneo == _torneoSeleccionado).toList();
      final jornadas = _obtenerJornadas(partidosDelTorneo);

      if (_jornadaSeleccionada != null && !jornadas.contains(_jornadaSeleccionada)) {
        _jornadaSeleccionada = _determinarJornadaActiva(partidosDelTorneo, jornadas);
      }

      if (_jornadaSeleccionada != null) {
        pool = _ordenar(partidosDelTorneo.where((p) => p.nombreJornada == _jornadaSeleccionada).toList());
        subtituloEncabezado = '$_jornadaSeleccionada • ${pool.length} ${pool.length == 1 ? 'partido' : 'partidos'}';
      } else {
        pool = _ordenar(partidosDelTorneo);
        subtituloEncabezado = '${pool.length} partidos';
      }
    } else {
      // 3. Vista general (Todas las ligas)
      if (_tab == TabPartidos.enVivo) {
        pool = _ordenar(enTabActual);
        subtituloEncabezado = '${pool.length} en juego';
      } else {
        switch (_filtroTemporal) {
          case FiltroTemporal.jornadaActual:
            final ordenados = _ordenar(enTabActual);
            pool = ordenados;
            final nombreJornada = ordenados.isNotEmpty ? ordenados.first.nombreJornada : null;
            subtituloEncabezado = nombreJornada != null ? '$nombreJornada (Próxima)' : 'Partidos próximos';
            break;
          case FiltroTemporal.hoy:
            pool = _ordenar(enTabActual.where((p) => _esHoy(p.fecha)).toList());
            subtituloEncabezado = 'Partidos de hoy (${pool.length})';
            break;
          case FiltroTemporal.semana:
            pool = _ordenar(enTabActual.where((p) => _esEstaSemana(p.fecha)).toList());
            subtituloEncabezado = 'Esta semana (${pool.length})';
            break;
        }
      }
    }

    final totalEnPool = pool.length;
    final mostrarBotonVerMas = totalEnPool > _limite;
    final visibles = pool.take(_limite).toList();
    final grupos = agruparPorTorneo(visibles).values.toList()
      ..sort((a, b) => a.first.torneo.compareTo(b.first.torneo));

    final jornadasTorneo = _torneoSeleccionado != null
        ? _obtenerJornadas(enTabActual.where((p) => p.torneo == _torneoSeleccionado).toList())
        : <String>[];

    final vacio = switch (_tab) {
      TabPartidos.todos => 'No hay partidos disponibles',
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
                PartidosTabs(
                  seleccionado: _tab,
                  conteo: contar,
                  onChanged: (t) => setState(() {
                    _tab = t;
                    _limite = 6;
                  }),
                ),
                const SizedBox(height: 12),
                TdsBuscador(
                  controller: _busquedaController,
                  hint: 'Buscar equipo, liga o estadio...',
                  onChanged: (v) => setState(() {
                    _busqueda = v;
                    _limite = 6;
                  }),
                  onLimpiar: () => setState(() {
                    _busqueda = '';
                    _limite = 6;
                  }),
                ),
                const SizedBox(height: 12),
                LigasChips(
                  torneos: torneos,
                  seleccionado: _torneoSeleccionado,
                  onChanged: (t) {
                    setState(() {
                      _torneoSeleccionado = t;
                      _limite = 6;
                      if (t != null) {
                        final partidosDelTorneo = enTabActual.where((p) => p.torneo == t).toList();
                        final jList = _obtenerJornadas(partidosDelTorneo);
                        _jornadaSeleccionada = _determinarJornadaActiva(partidosDelTorneo, jList);
                      } else {
                        _jornadaSeleccionada = null;
                      }
                    });
                  },
                ),
                if (_torneoSeleccionado != null && jornadasTorneo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  JornadasChips(
                    jornadas: jornadasTorneo,
                    seleccionada: _jornadaSeleccionada,
                    onChanged: (j) => setState(() {
                      _jornadaSeleccionada = j;
                      _limite = 6;
                    }),
                  ),
                ] else if (_torneoSeleccionado == null && !tieneBusqueda && _tab != TabPartidos.enVivo) ...[
                  const SizedBox(height: 12),
                  FiltrosTemporalesChips(
                    seleccionado: _filtroTemporal,
                    onChanged: (f) => setState(() {
                      _filtroTemporal = f;
                      _limite = 6;
                    }),
                  ),
                ],
                const SizedBox(height: 20),
                SeccionEncabezado(
                  tab: _tab,
                  total: visibles.length,
                  busqueda: _busqueda,
                  subtitulo: subtituloEncabezado,
                ),
                if (visibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: VacioView(
                      icono: tieneBusqueda ? Icons.search_off_outlined : Icons.sports_soccer_outlined,
                      texto: tieneBusqueda ? 'No se encontraron partidos para "$_busqueda"' : vacio,
                      subtitulo: tieneBusqueda
                          ? 'Intenta buscar por otro nombre de equipo, torneo o estadio.'
                          : 'Desliza hacia abajo para actualizar.',
                    ),
                  ),
              ],
            ),
          ),
          if (visibles.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList.separated(
                itemCount: grupos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 32),
                itemBuilder: (_, i) => SeccionTorneo(partidos: grupos[i], conPronostico: true),
              ),
            ),
          if (mostrarBotonVerMas)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TdsColors.onSurface,
                      side: BorderSide(color: TdsColors.borde.withValues(alpha: 0.5)),
                      backgroundColor: TdsColors.superficie,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: TdsColors.primaryContainer),
                    label: const Text('Ver más partidos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () => setState(() => _limite += 5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
