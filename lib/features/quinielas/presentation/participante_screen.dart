import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../../core/utils/formatos.dart';
import '../../partidos/domain/partido.dart';
import '../../partidos/presentation/widgets/detalles_partido.dart';
import '../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_providers.dart';
import 'widgets/posiciones_list.dart';
import 'widgets/resultado_card.dart';
import 'widgets/resultado_quiniela_badge.dart';

/// Posición, puntos, resultado y pronósticos de un participante.
/// RLS "Lectura pronosticos": se ven los propios, o los de otros miembros si eres PRO (próximos, en juego y finalizados).
class ParticipanteScreen extends ConsumerWidget {
  const ParticipanteScreen({super.key, required this.quinielaId, required this.usuarioId});

  final String quinielaId;
  final String usuarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(quinielaDetalleProvider(quinielaId));

    Future<void> recargar() async {
      ref
        ..invalidate(pronosticosDeProvider((quinielaId: quinielaId, usuarioId: usuarioId)))
        ..invalidate(quinielaDetalleProvider(quinielaId));
      await ref.read(quinielaDetalleProvider(quinielaId).future);
    }

    return Scaffold(
      appBar: TdsAppBar(titulo: 'PARTICIPANTE', onRefrescar: recargar),
      body: AsyncValueView(
        value: detalle,
        onReintentar: recargar,
        data: (d) => _Contenido(detalle: d, usuarioId: usuarioId, onRecargar: recargar),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.detalle, required this.usuarioId, required this.onRecargar});

  final DetalleQuiniela detalle;
  final String usuarioId;
  final Future<void> Function() onRecargar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = detalle;
    final esYo = usuarioId == d.miId;
    final participante = d.posiciones.where((p) => p.usuarioId == usuarioId).firstOrNull;
    final puedeVer = esYo || (ref.watch(perfilActualProvider).valueOrNull?.esPro ?? false);

    // Mis pronósticos ya vienen en el detalle; los de otro participante se piden aparte.
    final pronosticos = esYo
        ? AsyncValue.data(d.misPronosticos)
        : puedeVer
            ? ref.watch(pronosticosDeProvider((quinielaId: d.quiniela.id, usuarioId: usuarioId)))
            : const AsyncValue.data(<String, Pronostico>{});

    final resultado = d.resultadoDe(participante);
    final nombre = participante?.nombre ?? 'Usuario';

    return RefreshIndicator(
      onRefresh: onRecargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          TdsCard(
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: TdsColors.surfaceContainerHighest,
                      child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?', style: TdsText.headline(20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(esYo ? '$nombre (Tú)' : nombre, style: TdsText.headline(22))),
                    if (participante?.esPro ?? false)
                      TdsPill(
                        color: TdsColors.primaryContainer,
                        child: Text('PRO', style: TdsText.label(11, color: TdsColors.onPrimaryContainer)),
                      ),
                  ],
                ),
                if (d.finalizada) ...[
                  const SizedBox(height: 12),
                  ResultadoQuinielaBadge(
                    resultado: resultado,
                    lugar: participante?.lugar,
                    total: d.posiciones.length,
                    terceraPersona: !esYo,
                  ),
                ],
                const SizedBox(height: 16),
                ResumenPosicion(
                  lugar: participante?.lugar,
                  total: d.posiciones.length,
                  puntos: participante?.puntos ?? 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Pronósticos', style: TdsText.headline(18)),
          const SizedBox(height: 12),
          if (!puedeVer)
            TdsCard(
              child: VacioView(
                icono: Icons.workspace_premium,
                texto: 'Solo los usuarios PRO pueden ver los pronósticos de otros participantes.',
                compacto: true,
                acciones: [
                  TdsPillButton(
                    icon: Icons.bolt,
                    label: 'Ver planes',
                    primary: true,
                    onTap: () => context.push(Rutas.suscripcion),
                  ),
                ],
              ),
            )
          else
            pronosticos.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: CargandoView()),
              error: (e, _) => ErrorView.desde(e, onReintentar: onRecargar),
              data: (mapa) {
                // Un PRO ve partidos próximos, en juego y finalizados (nunca suspendidos)
                final visibles = d.partidos.where((p) => p.estado != EstadoPartido.suspendido).toList()
                  ..sort((a, b) => a.estado.index.compareTo(b.estado.index));
                if (visibles.isEmpty) {
                  return const VacioView(icono: Icons.sports_soccer_outlined, texto: 'Esta quiniela aún no tiene partidos.');
                }
                return Column(
                  children: [
                    for (final p in visibles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: p.estado == EstadoPartido.finalizado
                            ? ResultadoCard(partido: p, pronostico: mapa[p.id])
                            : _PronosticoAbierto(partido: p, pronostico: mapa[p.id]),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Pronóstico de un partido próximo o en juego (sin puntos todavía).
class _PronosticoAbierto extends StatelessWidget {
  const _PronosticoAbierto({required this.partido, this.pronostico});

  final Partido partido;
  final Pronostico? pronostico;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final pr = pronostico;
    return TdsCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(Formatos.diaHora(p.fecha), style: TdsText.label(12, color: TdsColors.textoSecundario)),
              ),
              EstadoPartidoPill(partido: p, estado: p.estado),
            ],
          ),
          const SizedBox(height: 8),
          DetallesPartido(partido: p),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: EquipoEscudo(nombre: p.local.nombre, escudoUrl: p.local.escudoUrl, size: 36)),
              Column(
                children: [
                  Text('PRONÓSTICO', style: TdsText.label(10, color: TdsColors.textoSecundario, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(pr == null ? '—' : '${pr.golesLocal} : ${pr.golesVisitante}', style: TdsText.stats(26)),
                ],
              ),
              Expanded(child: EquipoEscudo(nombre: p.visitante.nombre, escudoUrl: p.visitante.escudoUrl, size: 36)),
            ],
          ),
          if (p.estaEnJuego) ...[
            const SizedBox(height: 8),
            Text('Marcador actual: ${golesTexto(p.golesLocal)} - ${golesTexto(p.golesVisitante)}',
                style: TdsText.body(12, color: TdsColors.textoSecundario)),
          ],
          if (pr == null) ...[
            const SizedBox(height: 8),
            Text('No pronosticó', style: TdsText.label(12, color: TdsColors.textoTenue)),
          ],
        ],
      ),
    );
  }
}
