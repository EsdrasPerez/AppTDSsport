import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_providers.dart';
import 'widgets/quiniela_resumen_cards.dart';

/// Mis Quinielas: todas, con la misma card, separadas en En curso, Por iniciar y Finalizadas.
class MisQuinielasScreen extends ConsumerStatefulWidget {
  const MisQuinielasScreen({super.key});

  @override
  ConsumerState<MisQuinielasScreen> createState() => _MisQuinielasScreenState();
}

class _MisQuinielasScreenState extends ConsumerState<MisQuinielasScreen> {
  EstadoQuiniela? _filtro; // null = todas
  String _busqueda = '';

  Future<void> _recargar() {
    ref.invalidate(posicionesProvider);
    return ref.refresh(misQuinielasProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final activas = ref.watch(quinielasActivasProvider);
    final finalizadas = ref.watch(historialQuinielasProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: TdsAppBar(titulo: 'MIS QUINIELAS', onRefrescar: _recargar),
      body: AsyncValueView(
        value: activas,
        onReintentar: _recargar,
        data: (lista) => _buildContenido(lista, finalizadas),
      ),
    );
  }

  Widget _buildContenido(List<ResumenQuiniela> activas, List<ResumenQuiniela> finalizadas) {
    final todas = [...activas, ...finalizadas];
    final buscando = _busqueda.trim().isNotEmpty;
    // Filtros y secciones trabajan sobre las que coinciden con la búsqueda
    final coinciden = todas.where((q) => q.coincideConBusqueda(_busqueda)).toList();
    final miId = ref.watch(usuarioIdProvider);

    // Una sección por estado, en este orden; con un filtro elegido solo la suya
    const titulos = {
      EstadoQuiniela.enCurso: 'EN CURSO',
      EstadoQuiniela.porIniciar: 'POR INICIAR',
      EstadoQuiniela.finalizada: 'FINALIZADAS',
    };
    List<ResumenQuiniela> de(EstadoQuiniela e) => coinciden.where((q) => q.estado == e).toList();
    final secciones = [
      for (final e in titulos.keys)
        if ((_filtro == null || _filtro == e) && de(e).isNotEmpty) (e, de(e)),
    ];
    // Encabezado de sección + sus cards, en una sola lista para el SliverList
    final items = <Object>[
      for (final (estado, lista) in secciones) ...[estado, ...lista],
    ];

    return RefreshIndicator(
      onRefresh: _recargar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    const TdsDot(color: TdsColors.primaryContainer, pulse: true),
                    const SizedBox(width: 6),
                    Text(
                      '${activas.length} activas • ${activas.where((q) => q.estado == EstadoQuiniela.enCurso).length} en curso',
                      style: TdsText.label(14, color: TdsColors.primaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Acciones(),
                const SizedBox(height: 16),
                if (todas.isNotEmpty) ...[
                  TdsBuscador(
                    hint: 'Buscar quiniela, torneo o código',
                    onChanged: (v) => setState(() => _busqueda = v),
                  ),
                  const SizedBox(height: 12),
                  TdsFilterChipsRow(
                    chips: [
                      TdsFilterChip(
                          texto: 'Todas',
                          activo: _filtro == null,
                          cantidad: coinciden.length,
                          onTap: () => setState(() => _filtro = null)),
                      TdsFilterChip(
                        texto: 'En Curso',
                        activo: _filtro == EstadoQuiniela.enCurso,
                        cantidad: de(EstadoQuiniela.enCurso).length,
                        punto: TdsColors.secondaryContainer,
                        onTap: () => setState(() => _filtro = EstadoQuiniela.enCurso),
                      ),
                      TdsFilterChip(
                        texto: 'Por Iniciar',
                        activo: _filtro == EstadoQuiniela.porIniciar,
                        cantidad: de(EstadoQuiniela.porIniciar).length,
                        onTap: () => setState(() => _filtro = EstadoQuiniela.porIniciar),
                      ),
                      TdsFilterChip(
                        texto: 'Finalizadas',
                        activo: _filtro == EstadoQuiniela.finalizada,
                        cantidad: de(EstadoQuiniela.finalizada).length,
                        onTap: () => setState(() => _filtro = EstadoQuiniela.finalizada),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (items.isEmpty)
                  TdsCard(
                    child: VacioView(
                      icono: Icons.emoji_events_outlined,
                      texto: todas.isEmpty
                          ? 'No tienes quinielas'
                          : (buscando
                                ? 'Ninguna quiniela coincide con "${_busqueda.trim()}"'
                                : 'No hay quinielas con este estado'),
                      subtitulo: todas.isEmpty ? 'Crea una o únete con el código de un amigo.' : null,
                      compacto: true,
                      acciones: todas.isEmpty ? const [_Acciones(enFila: false)] : const [],
                    ),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => switch (items[i]) {
                final EstadoQuiniela e => _TituloSeccion(
                  titulo: titulos[e]!,
                  cantidad: de(e).length,
                  punto: e == EstadoQuiniela.enCurso,
                ),
                final ResumenQuiniela q => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: QuinielaDestacadaCard(key: ValueKey(q.id), quiniela: q, miId: miId),
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de una sección (EN CURSO, POR INICIAR, FINALIZADAS) con su cantidad.
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.titulo, required this.cantidad, this.punto = false});

  final String titulo;
  final int cantidad;
  final bool punto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        children: [
          if (punto) ...[const TdsDot(color: TdsColors.primaryContainer, pulse: true), const SizedBox(width: 8)],
          Expanded(child: Text(titulo, style: TdsText.headline(20))),
          Text(
            cantidad == 1 ? '1 quiniela' : '$cantidad quinielas',
            style: TdsText.label(12, color: TdsColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Botones "Crear quiniela" y "Unirse con código".
class _Acciones extends StatelessWidget {
  const _Acciones({this.enFila = true});

  final bool enFila;

  @override
  Widget build(BuildContext context) {
    final crear = TdsPillButton(
      icon: Icons.add_circle_outline,
      label: 'Crear quiniela',
      primary: true,
      onTap: () => context.push(Rutas.quinielaNueva),
    );
    final unirse = TdsPillButton(
      icon: Icons.group_add_outlined,
      label: 'Unirse con código',
      onTap: () => context.push(Rutas.quinielaUnirse),
    );

    if (!enFila) {
      return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [crear, unirse]);
    }
    return Row(
      children: [
        Expanded(child: crear),
        const SizedBox(width: 8),
        Expanded(child: unirse),
      ],
    );
  }
}
