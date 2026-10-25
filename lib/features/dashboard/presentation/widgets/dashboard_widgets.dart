import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../quinielas/domain/quiniela_models.dart';

// -----------------------------------------------------------------------------
// KPIs de Resumen Rápido del Usuario
// -----------------------------------------------------------------------------

class DashboardKpiCards extends StatelessWidget {
  const DashboardKpiCards({
    super.key,
    required this.quinielasActivas,
    required this.puntosTotales,
    required this.pronosticosAsignados,
    required this.totalPartidos,
    required this.mejorPosicion,
  });

  final int quinielasActivas;
  final int puntosTotales;
  final int pronosticosAsignados;
  final int totalPartidos;
  final int? mejorPosicion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dosColumnas = constraints.maxWidth < 600;

        final item1 = _KpiItem(
          icono: Icons.emoji_events_outlined,
          color: const Color(0xFFFFB800),
          valor: '$quinielasActivas',
          etiqueta: 'Quinielas Activas',
        );

        final item2 = _KpiItem(
          icono: Icons.stars_rounded,
          color: TdsColors.primaryContainer,
          valor: '$puntosTotales pts',
          etiqueta: 'Puntos Sumados',
        );

        final item3 = _KpiItem(
          icono: Icons.sports_soccer_outlined,
          color: const Color(0xFF29B6F6),
          valor: '$pronosticosAsignados / $totalPartidos',
          etiqueta: 'Pronósticos Listos',
        );

        final item4 = _KpiItem(
          icono: Icons.military_tech_outlined,
          color: TdsColors.exito,
          valor: mejorPosicion == null ? '—' : '#$mejorPosicion',
          etiqueta: 'Mejor Puesto',
        );

        if (dosColumnas) {
          return Column(
            children: [
              Row(children: [Expanded(child: item1), const SizedBox(width: 12), Expanded(child: item2)]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: item3), const SizedBox(width: 12), Expanded(child: item4)]),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: item1),
            const SizedBox(width: 12),
            Expanded(child: item2),
            const SizedBox(width: 12),
            Expanded(child: item3),
            const SizedBox(width: 12),
            Expanded(child: item4),
          ],
        );
      },
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: TdsText.stats(18, color: TdsColors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  etiqueta,
                  style: TdsText.label(10, color: TdsColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Partido Estelar / En Vivo de Tu Quiniela
// -----------------------------------------------------------------------------

class DashboardPartidoEstelar extends StatelessWidget {
  const DashboardPartidoEstelar({
    super.key,
    required this.partido,
    required this.quiniela,
    required this.pronostico,
    required this.esPro,
  });

  final Partido partido;
  final ResumenQuiniela quiniela;
  final Pronostico? pronostico;
  final bool esPro;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final enVivo = partido.estaEnJuegoEn(ahora);
    final pr = pronostico;
    final gl = partido.golesLocal;
    final gv = partido.golesVisitante;

    // Comparar pronóstico con marcador real
    final bool? acertandoExacto;
    final bool? acertandoSigno;

    if (gl != null && gv != null && pr != null) {
      acertandoExacto = gl == pr.golesLocal && gv == pr.golesVisitante;
      final signoReal = gl > gv ? 1 : (gl < gv ? -1 : 0);
      final signoPred = pr.golesLocal > pr.golesVisitante ? 1 : (pr.golesLocal < pr.golesVisitante ? -1 : 0);
      acertandoSigno = signoReal == signoPred;
    } else {
      acertandoExacto = null;
      acertandoSigno = null;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enVivo ? TdsColors.error.withValues(alpha: 0.8) : TdsColors.borde.withValues(alpha: 0.6),
          width: enVivo ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: enVivo ? TdsColors.error.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra superior del partido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: TdsColors.surfaceContainerLow,
            child: Row(
              children: [
                if (enVivo) ...[
                  const TdsDot(color: TdsColors.error, pulse: true),
                  const SizedBox(width: 8),
                  Text('EN JUEGO AHORA', style: TdsText.label(11, color: TdsColors.error, letterSpacing: 1.2)),
                ] else ...[
                  const Icon(Icons.schedule_rounded, size: 14, color: TdsColors.primaryContainer),
                  const SizedBox(width: 6),
                  Text('PARTIDO DESTACADO DE HOY', style: TdsText.label(11, color: TdsColors.primaryContainer, letterSpacing: 1)),
                ],
                const Spacer(),
                Text(
                  quiniela.torneoNombre,
                  style: TdsText.label(11, color: TdsColors.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Marcador y Equipos
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Equipo Local
                Expanded(
                  child: Column(
                    children: [
                      TdsEscudo(url: partido.local.escudoUrl, size: 54),
                      const SizedBox(height: 8),
                      Text(
                        partido.local.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TdsText.label(14),
                      ),
                    ],
                  ),
                ),

                // Marcador central
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: TdsColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: enVivo ? TdsColors.error.withValues(alpha: 0.5) : TdsColors.borde,
                          ),
                        ),
                        child: Text(
                          gl != null && gv != null ? '$gl  -  $gv' : 'VS',
                          style: TdsText.stats(26, color: enVivo ? TdsColors.onSurface : TdsColors.primaryContainer),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatos.hora(partido.fecha),
                        style: TdsText.label(11, color: TdsColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // Equipo Visitante
                Expanded(
                  child: Column(
                    children: [
                      TdsEscudo(url: partido.visitante.escudoUrl, size: 54),
                      const SizedBox(height: 8),
                      Text(
                        partido.visitante.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TdsText.label(14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Franja del Pronóstico del Usuario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: TdsColors.surfaceContainer,
              border: Border(top: BorderSide(color: TdsColors.borde.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                if (pr != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TdsColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TdsColors.borde),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 12, color: TdsColors.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                          'Tu pronóstico: ${pr.golesLocal} - ${pr.golesVisitante}',
                          style: TdsText.label(12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: acertandoExacto == true
                        ? Text(
                            '🔥 ¡Acertando exacto! (+3 pts)',
                            style: TdsText.label(12, color: TdsColors.primaryContainer),
                            overflow: TextOverflow.ellipsis,
                          )
                        : acertandoSigno == true
                            ? Text(
                                '👍 ¡Acertando ganador! (+1 pt)',
                                style: TdsText.label(12, color: const Color(0xFF29B6F6)),
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                enVivo ? 'Marcador en juego' : 'Pronóstico registrado',
                                style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                  ),
                ] else ...[
                  const Icon(Icons.warning_amber_rounded, size: 16, color: TdsColors.advertencia),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No has asignado pronóstico para este partido',
                      style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TdsPillButton(
                    icon: Icons.add,
                    label: 'Pronosticar',
                    primary: true,
                    onTap: () => context.push(Rutas.quiniela(quiniela.id, partidoId: partido.id)),
                  ),
                ],
                if (pr != null && esPro) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => context.push(Rutas.rivalesDe(quinielaId: quiniela.id, partidoId: partido.id)),
                    icon: const Icon(Icons.visibility_outlined, size: 15, color: TdsColors.primaryContainer),
                    label: Text('Ver rivales', style: TdsText.label(11, color: TdsColors.primaryContainer)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pulso / Tendencia de Pronósticos de Rivales
// -----------------------------------------------------------------------------

class DashboardTendenciaCard extends StatelessWidget {
  const DashboardTendenciaCard({
    super.key,
    required this.partido,
    required this.quinielaId,
    this.porcLocal = 65,
    this.porcEmpate = 20,
    this.porcVisita = 15,
  });

  final Partido partido;
  final String quinielaId;
  final int porcLocal;
  final int porcEmpate;
  final int porcVisita;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TdsColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded, size: 18, color: TdsColors.primaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TENDENCIA DE PRONÓSTICOS', style: TdsText.headline(15)),
                    Text(
                      '${partido.local.nombre} vs ${partido.visitante.nombre}',
                      style: TdsText.body(11, color: TdsColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TdsPill(
                color: TdsColors.surfaceContainerHigh,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 13, color: TdsColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('RIVALES', style: TdsText.label(10, color: TdsColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra segmentada tricolor
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: porcLocal,
                    child: Container(color: TdsColors.primaryContainer),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: porcEmpate,
                    child: Container(color: const Color(0xFFFFB800)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: porcVisita,
                    child: Container(color: const Color(0xFF29B6F6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Leyenda de porcentajes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LeyendaItem(
                color: TdsColors.primaryContainer,
                etiqueta: 'Local (${partido.local.nombre.split(' ').first})',
                porcentaje: '$porcLocal%',
              ),
              _LeyendaItem(
                color: const Color(0xFFFFB800),
                etiqueta: 'Empate',
                porcentaje: '$porcEmpate%',
              ),
              _LeyendaItem(
                color: const Color(0xFF29B6F6),
                etiqueta: 'Visita (${partido.visitante.nombre.split(' ').first})',
                porcentaje: '$porcVisita%',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pie con llamado a la acción
          Row(
            children: [
              Expanded(
                child: Text(
                  'El $porcLocal% de tus rivales anticipa victoria de ${partido.local.nombre}.',
                  style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => context.push(Rutas.rivalesDe(quinielaId: quinielaId, partidoId: partido.id)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver detalle', style: TdsText.label(12, color: TdsColors.primaryContainer)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: TdsColors.primaryContainer),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  const _LeyendaItem({required this.color, required this.etiqueta, required this.porcentaje});

  final Color color;
  final String etiqueta;
  final String porcentaje;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$etiqueta: ', style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
        Text(porcentaje, style: TdsText.label(12, color: color)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Quinielas Activas en Formato Compacto
// -----------------------------------------------------------------------------

class DashboardQuinielasCompactas extends StatelessWidget {
  const DashboardQuinielasCompactas({
    super.key,
    required this.quinielas,
    required this.onVerTodas,
  });

  final List<ResumenQuiniela> quinielas;
  final VoidCallback onVerTodas;

  @override
  Widget build(BuildContext context) {
    if (quinielas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TdsColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 40, color: TdsColors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text('Aún no tienes quinielas activas', style: TdsText.label(14)),
            const SizedBox(height: 4),
            Text(
              'Crea tu propia quiniela o únete a la de un amigo con un código de acceso.',
              textAlign: TextAlign.center,
              style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard_outlined, color: TdsColors.primaryContainer, size: 20),
                const SizedBox(width: 8),
                Text('TUS QUINIELAS ACTIVAS', style: TdsText.headline(16)),
              ],
            ),
            TextButton.icon(
              onPressed: onVerTodas,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: TdsColors.primaryContainer),
              label: Text('Ver todas', style: TdsText.label(13, color: TdsColors.primaryContainer)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final q in quinielas.take(3)) ...[
          _QuinielaCompactaItem(quiniela: q),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _QuinielaCompactaItem extends StatelessWidget {
  const _QuinielaCompactaItem({required this.quiniela});

  final ResumenQuiniela quiniela;

  @override
  Widget build(BuildContext context) {
    final prCount = quiniela.pronosticos.length;
    final totalPartidos = quiniela.partidos.length;
    final progreso = totalPartidos > 0 ? (prCount / totalPartidos).clamp(0.0, 1.0) : 0.0;
    final esLider = quiniela.lugar == 1;

    return Material(
      color: TdsColors.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Rutas.quiniela(quiniela.id)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: esLider ? const Color(0xFFFFB800).withValues(alpha: 0.5) : TdsColors.borde.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: esLider
                          ? const Color(0xFFFFB800).withValues(alpha: 0.16)
                          : TdsColors.primaryContainer.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esLider ? Icons.workspace_premium : Icons.emoji_events_outlined,
                      size: 20,
                      color: esLider ? const Color(0xFFFFB800) : TdsColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quiniela.nombre, style: TdsText.headline(16)),
                        Text(quiniela.torneoNombre, style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  // Posición
                  TdsPill(
                    color: esLider
                        ? const Color(0xFFFFB800).withValues(alpha: 0.18)
                        : TdsColors.surfaceContainerHigh,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (esLider) ...[
                          const Icon(Icons.star, size: 12, color: Color(0xFFFFB800)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '#${quiniela.lugar} de ${quiniela.participantes}',
                          style: TdsText.label(11, color: esLider ? const Color(0xFFFFB800) : TdsColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Puntos y barra de progreso
              Row(
                children: [
                  Text('${quiniela.puntos} pts', style: TdsText.stats(16, color: TdsColors.primaryContainer)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progreso,
                            minHeight: 6,
                            backgroundColor: TdsColors.surfaceContainerLow,
                            valueColor: AlwaysStoppedAnimation(
                              progreso >= 1.0 ? TdsColors.exito : TdsColors.primaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$prCount de $totalPartidos pronosticados',
                          style: TdsText.label(10, color: TdsColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right, size: 20, color: TdsColors.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
