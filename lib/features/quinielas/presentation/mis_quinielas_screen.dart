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

/// Mis Quinielas: solo las ACTIVAS. Las finalizadas pasan al historial del perfil.
class MisQuinielasScreen extends ConsumerStatefulWidget {
  const MisQuinielasScreen({super.key});

  @override
  ConsumerState<MisQuinielasScreen> createState() => _MisQuinielasScreenState();
}

class _MisQuinielasScreenState extends ConsumerState<MisQuinielasScreen> {
  EstadoQuiniela? _filtro; // null = todas

  Future<void> _recargar() => ref.refresh(misQuinielasProvider.future);

  @override
  Widget build(BuildContext context) {
    final activas = ref.watch(quinielasActivasProvider);
    final historial = ref.watch(historialQuinielasProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: TdsAppBar(titulo: 'MIS QUINIELAS', onRefrescar: _recargar),
      body: AsyncValueView(
        value: activas,
        onReintentar: _recargar,
        data: (lista) => _buildContenido(lista, historial.length),
      ),
    );
  }

  Widget _buildContenido(List<ResumenQuiniela> activas, int totalHistorial) {
    int contar(EstadoQuiniela e) => activas.where((q) => q.estado == e).length;
    final filtradas = _filtro == null ? activas : activas.where((q) => q.estado == _filtro).toList();

    // Destacada: la primera en curso; si no hay, la primera de la lista
    final destacada =
        filtradas.where((q) => q.estado == EstadoQuiniela.enCurso).firstOrNull ?? filtradas.firstOrNull;
    final otras = filtradas.where((q) => q != destacada).toList();
    final miId = ref.watch(usuarioIdProvider);

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
                      '${activas.length} activas • ${contar(EstadoQuiniela.enCurso)} en curso',
                      style: TdsText.label(14, color: TdsColors.primaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Acciones(),
                const SizedBox(height: 16),
                if (activas.isNotEmpty) ...[
                  TdsFilterChipsRow(
                    chips: [
                      TdsFilterChip(
                          texto: 'Todas',
                          activo: _filtro == null,
                          cantidad: activas.length,
                          onTap: () => setState(() => _filtro = null)),
                      TdsFilterChip(
                        texto: 'En Curso',
                        activo: _filtro == EstadoQuiniela.enCurso,
                        cantidad: contar(EstadoQuiniela.enCurso),
                        punto: TdsColors.secondaryContainer,
                        onTap: () => setState(() => _filtro = EstadoQuiniela.enCurso),
                      ),
                      TdsFilterChip(
                        texto: 'Por Iniciar',
                        activo: _filtro == EstadoQuiniela.porIniciar,
                        cantidad: contar(EstadoQuiniela.porIniciar),
                        onTap: () => setState(() => _filtro = EstadoQuiniela.porIniciar),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (filtradas.isEmpty)
                  TdsCard(
                    child: VacioView(
                      icono: Icons.emoji_events_outlined,
                      texto: activas.isEmpty ? 'No tienes quinielas activas' : 'No hay quinielas con este estado',
                      subtitulo: activas.isEmpty ? 'Crea una o únete con el código de un amigo.' : null,
                      compacto: true,
                      acciones: activas.isEmpty ? const [_Acciones(enFila: false)] : const [],
                    ),
                  )
                else ...[
                  QuinielaDestacadaCard(quiniela: destacada!),
                  if (otras.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: Text('OTRAS QUINIELAS', style: TdsText.headline(20))),
                        Text('${otras.length} activas', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: otras.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => QuinielaCompactaCard(key: ValueKey(otras[i].id), quiniela: otras[i], miId: miId),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverToBoxAdapter(
              child: totalHistorial == 0
                  ? const SizedBox.shrink()
                  : Center(
                      child: TextButton.icon(
                        onPressed: () => context.push(Rutas.historial),
                        icon: const Icon(Icons.history),
                        label: Text('Ver historial ($totalHistorial)'),
                      ),
                    ),
            ),
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
