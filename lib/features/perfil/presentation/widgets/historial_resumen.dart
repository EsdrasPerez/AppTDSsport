import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/theme/tds_theme.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../quinielas/domain/quiniela_models.dart';
import '../../../quinielas/presentation/widgets/resultado_quiniela_badge.dart';
import '../../../quinielas/providers/quinielas_providers.dart';

/// Totales del historial (puntos leídos de la base, solo se suman para mostrar el acumulado).
class EstadisticasHistorial {
  EstadisticasHistorial(List<ResumenQuiniela> finalizadas)
      : jugadas = finalizadas.length,
        ganadas = finalizadas.where((q) => q.resultado == ResultadoQuiniela.ganada).length,
        perdidas = finalizadas.where((q) => q.resultado == ResultadoQuiniela.perdida).length,
        mejorPosicion = finalizadas.isEmpty ? null : finalizadas.map((q) => q.lugar).reduce((a, b) => a < b ? a : b),
        puntosAcumulados = finalizadas.fold(0, (s, q) => s + q.puntos);

  final int jugadas;
  final int ganadas;
  final int perdidas;
  final int? mejorPosicion;
  final int puntosAcumulados;

  /// Porcentaje de quinielas ganadas sobre las terminadas.
  int get porcentajeVictorias => ganadas + perdidas == 0 ? 0 : (ganadas * 100 / (ganadas + perdidas)).round();
}

/// Sección que se agrega DEBAJO de la tarjeta de edición del perfil (no la modifica).
/// Trae su propio tema porque la pantalla de perfil conserva su paleta original.
class HistorialResumen extends ConsumerWidget {
  const HistorialResumen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(historialQuinielasProvider);

    return Theme(
      data: TdsTheme.oscuro,
      child: TdsCard(
        padding: const EdgeInsets.all(24),
        child: historial.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(padding: EdgeInsets.all(16), child: CargandoView()),
          error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(misQuinielasProvider)),
          data: (lista) {
            final stats = EstadisticasHistorial(lista);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: TdsColors.primaryContainer),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Mi historial', style: TdsText.headline(20))),
                  ],
                ),
                const SizedBox(height: 16),
                if (lista.isEmpty)
                  const VacioView(
                    icono: Icons.emoji_events_outlined,
                    texto: 'Aún no tienes quinielas finalizadas',
                    compacto: true,
                  )
                else ...[
                  Row(
                    children: [
                      _Dato(valor: '${stats.ganadas}', texto: 'Ganadas', color: TdsColors.primaryContainer),
                      _Dato(valor: '${stats.perdidas}', texto: 'Perdidas'),
                      _Dato(valor: '${stats.porcentajeVictorias}%', texto: 'Victorias', color: TdsColors.secondaryContainer),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Dato(valor: '${stats.jugadas}', texto: 'Jugadas'),
                      _Dato(valor: '#${stats.mejorPosicion}', texto: 'Mejor posición'),
                      _Dato(valor: '${stats.puntosAcumulados}', texto: 'Puntos'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final q in lista.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push(Rutas.quiniela(q.id, soloLectura: true)),
                      title: Text(q.nombre, overflow: TextOverflow.ellipsis, style: TdsText.label(14)),
                      subtitle: Text('${q.torneoNombre} · ${q.puntos} pts',
                          style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                      trailing: ResultadoQuinielaBadge(
                        resultado: q.resultado,
                        lugar: q.lugar,
                        total: q.participantes,
                        empate: q.empateEnPrimero,
                      ),
                    ),
                  const SizedBox(height: 8),
                  TdsPillButton(
                    icon: Icons.list_alt,
                    label: 'Ver historial completo',
                    onTap: () => context.push(Rutas.historial),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.texto, this.color = TdsColors.onSurface});

  final String valor;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(valor, style: TdsText.stats(22, color: color)),
          const SizedBox(height: 4),
          Text(texto, textAlign: TextAlign.center, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
