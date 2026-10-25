import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/services/notificaciones_servicio.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../partidos/domain/partido.dart';
import '../../perfil/domain/perfil.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../../quinielas/domain/quiniela_models.dart';
import '../../quinielas/providers/quinielas_providers.dart';
import '../../suscripcion/presentation/widgets/pro_banner.dart';
import 'widgets/banner_anti_olvido.dart';
import 'widgets/dashboard_widgets.dart';

/// Panel principal (/inicio): Centro de control deportivo en tiempo real con
/// KPIs de jornada, partido estelar en vivo con seguimiento de pronóstico,
/// tendencias de la comunidad y quinielas activas compactas.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _recargar(WidgetRef ref) async {
    ref
      ..invalidate(perfilActualProvider)
      ..invalidate(misQuinielasProvider);
    await ref.read(misQuinielasProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sincronizar automáticamente alertas de partidos por iniciar en Android
    ref.listen<AsyncValue<List<ResumenQuiniela>>>(quinielasActivasProvider, (_, next) {
      final lista = next.valueOrNull;
      if (lista != null && lista.isNotEmpty) {
        ref.read(notificacionesServicioProvider).sincronizarAlertasAntiOlvido(lista);
      }
    });

    return Scaffold(
      appBar: TdsAppBar(titulo: 'TDS SPORT', onRefrescar: () => _recargar(ref)),
      body: RefreshIndicator(
        onRefresh: () => _recargar(ref),
        child: _buildMainContent(context, ref),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider).valueOrNull;
    final activasAsync = ref.watch(quinielasActivasProvider);
    final activas = activasAsync.valueOrNull ?? const <ResumenQuiniela>[];

    // Cálculos de métricas globales del usuario
    final quinielasCount = activas.length;
    final puntosTotales = activas.fold<int>(0, (acc, q) => acc + q.puntos);
    final pronosticosAsignados = activas.fold<int>(0, (acc, q) => acc + q.pronosticos.length);
    final totalPartidos = activas.fold<int>(0, (acc, q) => acc + q.partidos.length);
    final mejorPosicion = activas.isEmpty ? null : activas.map((q) => q.lugar).reduce(min);

    final ahora = DateTime.now();

    // 1. Buscar Partido Estelar: primero en juego, luego próximo de hoy, luego el siguiente
    Partido? partidoEstelar;
    ResumenQuiniela? quinielaEstelar;

    for (final q in activas) {
      final enJuego = q.partidos.where((p) => p.estaEnJuegoEn(ahora)).firstOrNull;
      if (enJuego != null) {
        partidoEstelar = enJuego;
        quinielaEstelar = q;
        break;
      }
    }

    if (partidoEstelar == null) {
      for (final q in activas) {
        final deHoy = q.partidos.where((p) {
          final f = p.fecha;
          return f != null && f.year == ahora.year && f.month == ahora.month && f.day == ahora.day && f.isAfter(ahora);
        }).firstOrNull;
        if (deHoy != null) {
          partidoEstelar = deHoy;
          quinielaEstelar = q;
          break;
        }
      }
    }

    if (partidoEstelar == null) {
      for (final q in activas) {
        final siguiente = q.porJugar.firstOrNull;
        if (siguiente != null) {
          partidoEstelar = siguiente;
          quinielaEstelar = q;
          break;
        }
      }
    }

    // 2. Buscar Partido para Tendencia Comunitaria (partido de hoy o próximo)
    Partido? partidoTendencia;
    String? quinielaTendenciaId;

    for (final q in activas) {
      for (final p in q.porJugar) {
        if (p.id != partidoEstelar?.id) {
          partidoTendencia = p;
          quinielaTendenciaId = q.id;
          break;
        }
      }
      if (partidoTendencia != null) break;
    }
    // Si no hay otro, usamos el mismo partido estelar para tendencia
    partidoTendencia ??= partidoEstelar;
    quinielaTendenciaId ??= quinielaEstelar?.id;

    final esPro = perfil?.esPro ?? false;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Saludo y estatus
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          perfil == null ? 'Hola' : 'Hola, ${perfil.primerNombre}',
                          style: TdsText.headline(26),
                        ),
                        if (esPro) ...[
                          const SizedBox(width: 8),
                          TdsPill(
                            color: perfil!.plan == PlanUsuario.vip
                                ? const Color(0xFFFFB800).withValues(alpha: 0.18)
                                : TdsColors.primaryContainer.withValues(alpha: 0.18),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  perfil.plan == PlanUsuario.vip ? Icons.workspace_premium : Icons.bolt,
                                  size: 13,
                                  color: perfil.plan == PlanUsuario.vip ? const Color(0xFFFFB800) : TdsColors.primaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  perfil.plan.etiqueta,
                                  style: TdsText.label(
                                    10,
                                    color: perfil.plan == PlanUsuario.vip ? const Color(0xFFFFB800) : TdsColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tu centro de control y seguimiento en tiempo real.',
                      style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Banner Anti-Olvido: Avisos de partidos de hoy sin pronóstico
          BannerAntiOlvido(quinielas: activas),

          // 1. KPIs Rápidos del Usuario
          DashboardKpiCards(
            quinielasActivas: quinielasCount,
            puntosTotales: puntosTotales,
            pronosticosAsignados: pronosticosAsignados,
            totalPartidos: totalPartidos,
            mejorPosicion: mejorPosicion,
          ),
          const SizedBox(height: 24),

          // 2. Partido Estelar / En Vivo con Pronóstico
          if (partidoEstelar != null && quinielaEstelar != null) ...[
            DashboardPartidoEstelar(
              partido: partidoEstelar,
              quiniela: quinielaEstelar,
              pronostico: quinielaEstelar.pronosticos[partidoEstelar.id],
              esPro: esPro,
            ),
            const SizedBox(height: 20),
          ],

          // 3. Pulso / Tendencia de Pronósticos de Rivales
          if (partidoTendencia != null && quinielaTendenciaId != null) ...[
            DashboardTendenciaCard(
              partido: partidoTendencia,
              quinielaId: quinielaTendenciaId,
            ),
            const SizedBox(height: 24),
          ],

          // 4. Tus Quinielas Activas (Formato compacto)
          DashboardQuinielasCompactas(
            quinielas: activas,
            onVerTodas: () => context.go(Rutas.quinielas),
          ),
          const SizedBox(height: 16),

          // Botones de acción rápida para quinielas
          Row(
            children: [
              Expanded(
                child: TdsPillButton(
                  icon: Icons.add_circle_outline,
                  label: 'Crear quiniela',
                  primary: true,
                  onTap: () => context.push(Rutas.quinielaNueva),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TdsPillButton(
                  icon: Icons.group_add_outlined,
                  label: 'Unirse con código',
                  onTap: () => context.push(Rutas.quinielaUnirse),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 5. Banner de Suscripción / Privilegios
          const ProBanner(),
        ],
      ),
    );
  }
}
