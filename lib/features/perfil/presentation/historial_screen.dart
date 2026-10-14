import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../quinielas/domain/quiniela_models.dart';
import '../../quinielas/presentation/widgets/quiniela_resumen_cards.dart';
import '../../quinielas/providers/quinielas_providers.dart';

enum _FiltroHistorial { todas, ganadas, perdidas, creadas }

/// Todas las quinielas FINALIZADAS del usuario (creadas y jugadas), más reciente primero.
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  _FiltroHistorial _filtro = _FiltroHistorial.todas;

  Future<void> _recargar() async {
    ref.invalidate(misQuinielasProvider);
    await ref.read(misQuinielasProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final historial = ref.watch(historialQuinielasProvider);
    final miId = ref.watch(usuarioIdProvider);

    return Scaffold(
      appBar: TdsAppBar(titulo: 'HISTORIAL', onRefrescar: _recargar),
      body: AsyncValueView(
        value: historial,
        onReintentar: _recargar,
        data: (todas) {
          bool pasa(ResumenQuiniela q, _FiltroHistorial f) => switch (f) {
                _FiltroHistorial.todas => true,
                _FiltroHistorial.ganadas => q.resultado == ResultadoQuiniela.ganada,
                _FiltroHistorial.perdidas => q.resultado == ResultadoQuiniela.perdida,
                _FiltroHistorial.creadas => q.esCreador(miId),
              };
          int contar(_FiltroHistorial f) => todas.where((q) => pasa(q, f)).length;

          final visibles = todas.where((q) => pasa(q, _filtro)).toList();

          return RefreshIndicator(
            onRefresh: _recargar,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: TdsFilterChipsRow(
                      chips: [
                        for (final (f, texto) in const [
                          (_FiltroHistorial.todas, 'Todas'),
                          (_FiltroHistorial.ganadas, 'Ganadas'),
                          (_FiltroHistorial.perdidas, 'Perdidas'),
                          (_FiltroHistorial.creadas, 'Creadas por mí'),
                        ])
                          TdsFilterChip(
                            texto: texto,
                            activo: _filtro == f,
                            cantidad: contar(f),
                            onTap: () => setState(() => _filtro = f),
                          ),
                      ],
                    ),
                  ),
                ),
                if (visibles.isEmpty)
                  SliverToBoxAdapter(
                    child: VacioView(
                      icono: Icons.emoji_events_outlined,
                      texto: todas.isEmpty
                          ? 'Aún no tienes quinielas finalizadas'
                          : 'No hay quinielas con este filtro',
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: visibles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) =>
                        QuinielaCompactaCard(key: ValueKey(visibles[i].id), quiniela: visibles[i], miId: miId),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
