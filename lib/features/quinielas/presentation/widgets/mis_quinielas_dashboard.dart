import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../providers/quinielas_providers.dart';
import 'quiniela_resumen_cards.dart';

/// Sección "Mis Quinielas" del dashboard: las 2 primeras quinielas activas y acceso a la lista.
class MisQuinielasDashboard extends ConsumerWidget {
  const MisQuinielasDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activas = ref.watch(quinielasActivasProvider);
    final miId = ref.watch(usuarioIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Mis Quinielas', style: TdsText.headline(20))),
            TextButton(
              onPressed: () => context.push(Rutas.quinielas),
              child: Text('Ver todas ➔', style: TdsText.label(13, color: TdsColors.primaryContainer)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activas.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(padding: EdgeInsets.all(24), child: CargandoView()),
          error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(misQuinielasProvider)),
          data: (lista) {
            if (lista.isEmpty) {
              return TdsCard(
                child: VacioView(
                  icono: Icons.emoji_events_outlined,
                  texto: 'No tienes quinielas activas',
                  compacto: true,
                  acciones: [
                    TdsPillButton(
                      icon: Icons.add_circle_outline,
                      label: 'Crear quiniela',
                      primary: true,
                      onTap: () => context.push(Rutas.quinielaNueva),
                    ),
                    TdsPillButton(
                      icon: Icons.group_add_outlined,
                      label: 'Unirse con código',
                      onTap: () => context.push(Rutas.quinielaUnirse),
                    ),
                  ],
                ),
              );
            }
            // En curso primero, luego por iniciar
            final orden = [...lista]..sort((a, b) => a.estado.index.compareTo(b.estado.index));
            return Column(
              children: [
                for (final q in orden.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: QuinielaCompactaCard(key: ValueKey(q.id), quiniela: q, miId: miId),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
