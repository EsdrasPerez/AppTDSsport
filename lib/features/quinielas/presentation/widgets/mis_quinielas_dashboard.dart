import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../domain/quiniela_models.dart';
import '../../providers/quinielas_providers.dart';
import 'quiniela_resumen_cards.dart';

/// Secciones de quinielas del dashboard: primero las de amigos a las que me uní con código
/// (con el botón para unirse) y después las que creé.
///
/// Títulos y botones siempre están a la vista (aunque no haya internet); solo el contenido de
/// cada sección muestra cargando, error o las quinielas.
class MisQuinielasDashboard extends ConsumerWidget {
  const MisQuinielasDashboard({super.key});

  /// Quinielas por sección a la vista; el resto en "Ver todas".
  static const _maxPorSeccion = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activas = ref.watch(quinielasActivasProvider);
    final miId = ref.watch(usuarioIdProvider);

    // En curso primero, luego por iniciar
    List<ResumenQuiniela> ordenadas(List<ResumenQuiniela> l, bool creadas) =>
        l.where((q) => q.esCreador(miId) == creadas).toList()..sort((a, b) => a.estado.index.compareTo(b.estado.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Seccion(
          titulo: 'Quinielas de amigos',
          contenido: activas.whenData((l) => ordenadas(l, false)),
          vacio: const VacioView(
            icono: Icons.group_outlined,
            texto: 'Aún no te unes a la quiniela de un amigo',
            compacto: true,
          ),
          // El reintentar se muestra una sola vez, en la primera sección.
          error: (e) => ErrorView.desde(e, onReintentar: () => ref.invalidate(misQuinielasProvider)),
          pie: Center(
            child: TdsPillButton(
              icon: Icons.group_add_outlined,
              label: 'Unirse con código',
              primary: true,
              onTap: () => context.push(Rutas.quinielaUnirse),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _Seccion(
          titulo: 'Mis Quinielas',
          contenido: activas.whenData((l) => ordenadas(l, true)),
          vacio: VacioView(
            icono: Icons.emoji_events_outlined,
            texto: 'No has creado quinielas activas',
            compacto: true,
            acciones: [
              TdsPillButton(
                icon: Icons.add_circle_outline,
                label: 'Crear quiniela',
                primary: true,
                onTap: () => context.push(Rutas.quinielaNueva),
              ),
            ],
          ),
          error: (_) => Text(
            'No se pudieron cargar tus quinielas.',
            textAlign: TextAlign.center,
            style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.contenido, required this.vacio, required this.error, this.pie});

  final String titulo;
  final AsyncValue<List<ResumenQuiniela>> contenido;
  final Widget vacio;
  final Widget Function(Object error) error;

  /// Siempre visible debajo del contenido.
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(titulo, style: TdsText.headline(20))),
            TextButton(
              onPressed: () => context.push(Rutas.quinielas),
              child: Text('Ver todas ➔', style: TdsText.label(13, color: TdsColors.primaryContainer)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...contenido.when(
          skipLoadingOnRefresh: true,
          loading: () => [
            const TdsCard.modulo(
              child: Padding(padding: EdgeInsets.all(12), child: CargandoView()),
            ),
          ],
          error: (e, _) => [TdsCard.modulo(child: error(e))],
          data: (quinielas) => quinielas.isEmpty
              ? [TdsCard.modulo(child: vacio)]
              : [
                  for (final q in quinielas.take(MisQuinielasDashboard._maxPorSeccion))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: QuinielaPanelCard(key: ValueKey(q.id), quiniela: q),
                    ),
                ],
        ),
        if (pie != null) ...[const SizedBox(height: 16), pie!],
      ],
    );
  }
}
