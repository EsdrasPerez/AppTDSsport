import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/services/notificaciones_servicio.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../partidos/domain/partido.dart';
import '../../../quinielas/domain/quiniela_models.dart';

/// Elemento con información de un partido de hoy pendiente de pronóstico.
class PartidoPendienteHoy {
  const PartidoPendienteHoy({
    required this.quiniela,
    required this.partido,
    required this.fecha,
  });

  final ResumenQuiniela quiniela;
  final Partido partido;
  final DateTime fecha;
}

/// Banner inteligente Anti-Olvido para el Dashboard (/inicio).
///
/// Detecta automáticamente si el usuario tiene partidos programados para HOY
/// en sus quinielas activas a los que aún no les ha asignado pronóstico.
///
/// - Si hay partidos pendientes: Muestra una tarjeta de alerta ámbar con cuenta
///   regresiva al partido más próximo y botón directo [Pronosticar ahora].
/// - Si ya completó todos sus partidos de hoy: Muestra un badge de confirmación
///   verde (todo al día).
/// - Si hoy no hay partidos programados: Se oculta suavemente para no saturar.
class BannerAntiOlvido extends StatelessWidget {
  const BannerAntiOlvido({
    super.key,
    required this.quinielas,
  });

  final List<ResumenQuiniela> quinielas;

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    if (quinielas.isEmpty) return const SizedBox.shrink();

    final ahora = DateTime.now();
    final List<PartidoPendienteHoy> pendientesHoy = [];
    int totalPartidosHoy = 0;

    for (final q in quinielas) {
      for (final p in q.partidos) {
        final f = p.fecha;
        if (f == null) continue;
        if (!_esMismoDia(f, ahora)) continue;

        totalPartidosHoy++;

        // Si aún no tiene pronóstico en esta quiniela y el partido acepta pronósticos
        final yaPronosticado = q.pronosticos.containsKey(p.id);
        if (!yaPronosticado && p.aceptaPronosticoEn(ahora)) {
          pendientesHoy.add(PartidoPendienteHoy(
            quiniela: q,
            partido: p,
            fecha: f,
          ));
        }
      }
    }

    // 1. Caso: Hay partidos de hoy sin pronóstico -> ALERTA ACTIVA
    if (pendientesHoy.isNotEmpty) {
      // Ordenar por el más cercano en tiempo
      pendientesHoy.sort((a, b) => a.fecha.compareTo(b.fecha));
      final proximo = pendientesHoy.first;
      final diffMinutos = proximo.fecha.difference(ahora).inMinutes;

      final String tiempoTexto;
      if (diffMinutos <= 0) {
        tiempoTexto = 'en breve';
      } else if (diffMinutos < 60) {
        tiempoTexto = 'en $diffMinutos min';
      } else {
        final horas = diffMinutos ~/ 60;
        final mins = diffMinutos % 60;
        tiempoTexto = mins > 0 ? 'en ${horas}h ${mins}m' : 'en ${horas}h';
      }

      return _buildAlertaActiva(
        context: context,
        pendientesCount: pendientesHoy.length,
        proximo: proximo,
        tiempoTexto: tiempoTexto,
      );
    }

    // 2. Caso: Había partidos hoy y ya todos fueron pronosticados -> CONFIRMACIÓN ÉXITO
    if (totalPartidosHoy > 0) {
      return _buildTodoAlDia(context: context, totalHoy: totalPartidosHoy);
    }

    // 3. Caso: No hay partidos programados para hoy
    return const SizedBox.shrink();
  }

  Widget _buildAlertaActiva({
    required BuildContext context,
    required int pendientesCount,
    required PartidoPendienteHoy proximo,
    required String tiempoTexto,
  }) {
    final bool esUnico = pendientesCount == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C1E0A),
            TdsColors.superficie,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TdsColors.advertencia.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: TdsColors.advertencia.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del banner con tag de aviso
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: TdsColors.advertencia.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: TdsColors.advertencia,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: TdsColors.advertencia.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ALERTA ANTI-OLVIDO',
                                style: TdsText.label(
                                  10,
                                  color: TdsColors.advertencia,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final concedido = await NotificacionesServicio().solicitarPermisos();
                                await NotificacionesServicio().mostrarNotificacionInmediata(
                                  id: 777,
                                  titulo: '⏰ ¡Alerta de Partido TDS Sport!',
                                  cuerpo: '${proximo.partido.local.nombre} vs ${proximo.partido.visitante.nombre} inicia $tiempoTexto. ¡Asigna tu pronóstico!',
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: TdsColors.superficieAlta,
                                      content: Text(
                                        concedido
                                            ? '🔔 Notificación de prueba enviada al teléfono.'
                                            : '🔔 Recordatorio sincronizado en Android.',
                                        style: TdsText.body(13, color: TdsColors.texto),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: TdsColors.superficieAlta,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: TdsColors.borde.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.notifications_active_outlined, size: 12, color: TdsColors.acento),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Alerta móvil',
                                      style: TdsText.label(10, color: TdsColors.textoSecundario),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: TdsColors.advertencia.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: TdsColors.advertencia.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                '$pendientesCount ${esUnico ? 'pendiente' : 'pendientes'}',
                                style: TdsText.label(
                                  11,
                                  color: TdsColors.advertencia,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          esUnico
                              ? 'Tienes 1 partido de hoy sin pronóstico'
                              : 'Tienes $pendientesCount partidos de hoy sin pronóstico',
                          style: TdsText.headline(16, color: TdsColors.texto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Detalle del partido más próximo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: TdsColors.superficieAlta.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TdsColors.borde.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: TdsColors.advertencia,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'El más próximo: ',
                              style: TdsText.body(12, color: TdsColors.textoSecundario),
                            ),
                            TextSpan(
                              text: '${proximo.partido.local.nombre} vs ${proximo.partido.visitante.nombre} ',
                              style: TdsText.label(12, color: TdsColors.texto),
                            ),
                            TextSpan(
                              text: '($tiempoTexto)',
                              style: TdsText.label(12, color: TdsColors.advertencia),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Botón de acción rápida: Pronosticar Ahora
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TdsColors.acento,
                        foregroundColor: TdsColors.sobreAcento,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(Rutas.misPronosticosPendientes());
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: Text(
                        'Pronosticar ahora ($pendientesCount)',
                        style: TdsText.label(14, color: TdsColors.sobreAcento),
                      ),
                    ),
                  ),
                  if (esUnico) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TdsColors.texto,
                        side: BorderSide(color: TdsColors.borde.withValues(alpha: 0.8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push(Rutas.quiniela(proximo.quiniela.id, partidoId: proximo.partido.id));
                      },
                      child: const Text('Ver quiniela'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoAlDia({
    required BuildContext context,
    required int totalHoy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TdsColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TdsColors.exito.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TdsColors.exito.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: TdsColors.exito,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¡Estás al día con tus pronósticos!',
                  style: TdsText.label(13, color: TdsColors.texto),
                ),
                Text(
                  'Completaste los $totalHoy partidos programados para hoy. ¡A ganar!',
                  style: TdsText.body(11, color: TdsColors.textoSecundario),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: TdsColors.acento,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => context.push(Rutas.misPronosticos),
            child: const Text('Ver todos'),
          ),
        ],
      ),
    );
  }
}
