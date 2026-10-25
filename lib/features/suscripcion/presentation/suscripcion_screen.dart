import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../perfil/domain/perfil.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../domain/pasarela_pago.dart';
import '../providers/suscripcion_providers.dart';
import 'widgets/plan_widgets.dart';

/// Centro de Membresías y Planes: selección, pase activo, comparativa y "Mis pagos".
class SuscripcionScreen extends ConsumerStatefulWidget {
  const SuscripcionScreen({super.key});

  @override
  ConsumerState<SuscripcionScreen> createState() => _SuscripcionScreenState();
}

class _SuscripcionScreenState extends ConsumerState<SuscripcionScreen> {
  bool _procesando = false;

  void _suscribirme(PlanInfo plan) {
    if (plan.base == null) {
      Notificacion.info(
        context,
        'El ${plan.nombre} estará disponible para contratación directa en las próximas horas.',
        titulo: plan.nombre,
      );
      return;
    }
    context.push(Rutas.pago(plan.base!.id));
  }

  Future<void> _cancelar(Perfil perfil) async {
    final hasta = perfil.planVenceEn;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar tu suscripción?'),
        content: Text(
          hasta == null
              ? 'Tu cuenta pasará al Plan Gratuito y dejarás de ver los pronósticos de tus rivales.'
              : 'Tu plan ${perfil.plan.etiqueta} seguirá activo hasta el ${Formatos.fecha(hasta)}. '
                  'Después tu cuenta pasará al Plan Gratuito.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mantener mi plan')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: TdsColors.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _procesando = true);
    try {
      await ref.read(suscripcionControllerProvider).cancelar();
      if (!mounted) return;
      Notificacion.info(
        context,
        hasta == null ? 'Tu cuenta regresó al Plan Gratuito.' : 'Tu plan sigue activo hasta el ${Formatos.fecha(hasta)}.',
        titulo: 'Suscripción cancelada',
      );
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo cancelar');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: const TdsAppBar(titulo: 'MEMBRESÍAS & PLANES'),
      body: AsyncValueView(
        value: perfil,
        onReintentar: () => ref.invalidate(perfilActualProvider),
        data: (p) {
          final plan = p?.planVigente ?? PlanUsuario.gratis;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                children: [
                  if (p != null && plan != PlanUsuario.gratis) ...[
                    _MiPlan(perfil: p, onCancelar: () => _cancelar(p)),
                    const SizedBox(height: 28),
                  ] else ...[
                    const HeroPro(esPro: false),
                    const SizedBox(height: 28),
                  ],

                  // Encabezado de la sección de planes
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined, color: TdsColors.primaryContainer, size: 22),
                      const SizedBox(width: 8),
                      Text('PLANES DISPONIBLES', style: TdsText.headline(18)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona el nivel que mejor se adapta a tu estrategia. Sin plazos forzosos.',
                    style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Tarjetas de planes con disposición adaptable
                  ...ref.watch(planesProvider).when(
                        skipLoadingOnRefresh: true,
                        loading: () => [const Padding(padding: EdgeInsets.all(24), child: CargandoView())],
                        error: (e, _) => [ErrorView.desde(e, onReintentar: () => ref.invalidate(planesProvider))],
                        data: (planes) {
                          final proBase = planes.where((b) => b.tipo == PlanUsuario.pro).firstOrNull;
                          final vipBase = planes.where((b) => b.tipo == PlanUsuario.vip).firstOrNull;

                          final infoPro = proBase != null ? PlanInfo.desde(proBase) : planPro;
                          final infoVip = vipBase != null ? PlanInfo.desde(vipBase) : planVip;

                          final cardGratis = PlanGratuitoCard(
                            activo: plan == PlanUsuario.gratis,
                            onVolver: () {
                              if (p != null) _cancelar(p);
                            },
                            puedeVolver: p?.planRenovar ?? true,
                          );

                          final cardPro = PlanCard(
                            plan: infoPro,
                            destacado: true,
                            activo: plan == PlanUsuario.pro,
                            onComprar: () => _suscribirme(infoPro),
                          );

                          final cardVip = PlanCard(
                            plan: infoVip,
                            destacado: false,
                            activo: plan == PlanUsuario.vip,
                            onComprar: () => _suscribirme(infoVip),
                          );

                          return [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final esEscritorio = constraints.maxWidth >= 960;
                                if (esEscritorio) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: cardGratis),
                                      const SizedBox(width: 16),
                                      Expanded(child: cardPro),
                                      const SizedBox(width: 16),
                                      Expanded(child: cardVip),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    cardPro,
                                    const SizedBox(height: 16),
                                    cardVip,
                                    const SizedBox(height: 16),
                                    cardGratis,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            const TablaComparativaPlanes(),
                          ];
                        },
                      ),

                  const SizedBox(height: 32),
                  const _MisPagos(),
                  const SizedBox(height: 24),
                  const GarantiasCard(),
                  const SizedBox(height: 24),
                  const PreguntasFrecuentes(),
                ],
              ),
              if (_procesando) Container(color: TdsColors.velo, child: const CargandoView()),
            ],
          );
        },
      ),
    );
  }
}

/// Credencial de membresía digital activa para suscriptores PRO o VIP.
class _MiPlan extends StatelessWidget {
  const _MiPlan({required this.perfil, required this.onCancelar});

  final Perfil perfil;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final vence = perfil.planVenceEn;
    final esVip = perfil.plan == PlanUsuario.vip;
    final colorAcento = esVip ? const Color(0xFFFFB800) : TdsColors.primaryContainer;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorAcento.withValues(alpha: 0.8), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: colorAcento.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorAcento.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorAcento.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorAcento.withValues(alpha: 0.4)),
                      ),
                      child: Icon(
                        esVip ? Icons.workspace_premium : Icons.bolt,
                        color: colorAcento,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                esVip ? 'PASE VIP ELITE' : 'PASE PRO MVP',
                                style: TdsText.label(12, color: colorAcento, letterSpacing: 1.2),
                              ),
                              const SizedBox(width: 8),
                              TdsPill(
                                color: TdsColors.exito.withValues(alpha: 0.18),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const TdsDot(color: TdsColors.exito, pulse: true),
                                    const SizedBox(width: 5),
                                    Text('ACTIVO', style: TdsText.label(10, color: TdsColors.exito)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(perfil.nombre, style: TdsText.headline(20)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TdsColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        perfil.planRenovar ? Icons.autorenew_rounded : Icons.event_available_outlined,
                        size: 16,
                        color: TdsColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vence == null
                              ? 'Membresía activa sin vencimiento programado'
                              : perfil.planRenovar
                                  ? 'Renovación automática: ${Formatos.fecha(vence)}'
                                  : 'Activo hasta: ${Formatos.fecha(vence)} (no se renovará)',
                          style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipBeneficio(icono: Icons.visibility_outlined, label: 'Rivales en vivo', color: colorAcento),
                    _ChipBeneficio(icono: Icons.edit_calendar_outlined, label: 'Edición libre', color: colorAcento),
                    _ChipBeneficio(
                      icono: esVip ? Icons.diamond_outlined : Icons.workspace_premium,
                      label: 'Insignia ${perfil.plan.etiqueta}',
                      color: colorAcento,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TdsPillButton(
                        icon: Icons.visibility_outlined,
                        label: 'Ver pronósticos de rivales',
                        primary: true,
                        onTap: () => context.go(Rutas.rivales),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TdsPillButton(
                        icon: Icons.sports_soccer_outlined,
                        label: 'Mis pronósticos',
                        onTap: () => context.go(Rutas.misPronosticos),
                      ),
                    ),
                  ],
                ),
                if (perfil.planRenovar) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: onCancelar,
                      style: TextButton.styleFrom(foregroundColor: TdsColors.error),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancelar renovación automática'),
                    ),
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

class _ChipBeneficio extends StatelessWidget {
  const _ChipBeneficio({required this.icono, required this.label, required this.color});

  final IconData icono;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TdsText.label(11, color: color)),
        ],
      ),
    );
  }
}

/// Historial "Mis pagos": fecha, plan, monto, tarjeta y estado.
class _MisPagos extends ConsumerWidget {
  const _MisPagos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagos = ref.watch(misPagosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: TdsColors.primaryContainer, size: 20),
            const SizedBox(width: 8),
            Text('HISTORIAL DE PAGOS', style: TdsText.headline(18)),
          ],
        ),
        const SizedBox(height: 12),
        pagos.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(padding: EdgeInsets.all(16), child: CargandoView()),
          error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(misPagosProvider)),
          data: (lista) => lista.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TdsColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      'Aún no registras pagos con tarjeta.',
                      textAlign: TextAlign.center,
                      style: TdsText.body(14, color: TdsColors.onSurfaceVariant),
                    ),
                  ),
                )
              : Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: TdsColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
                  ),
                  child: Column(children: [for (final p in lista) _FilaPago(pago: p)]),
                ),
        ),
      ],
    );
  }
}

class _FilaPago extends StatelessWidget {
  const _FilaPago({required this.pago});

  final Pago pago;

  @override
  Widget build(BuildContext context) {
    final aprobado = pago.estado == 'APROBADO';
    final esVip = pago.plan == PlanUsuario.vip;
    final colorPlan = esVip ? const Color(0xFFFFB800) : TdsColors.primaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: TdsColors.borde.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorPlan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esVip ? Icons.workspace_premium : Icons.bolt,
              color: colorPlan,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${pago.plan.etiqueta} • ${Formatos.moneda(pago.monto)}',
                  style: TdsText.label(14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatos.fecha(pago.fecha)} • ${pago.marca} •••• ${pago.ultimos4}',
                  style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TdsPill(
            color: aprobado ? TdsColors.exito.withValues(alpha: 0.18) : TdsColors.surfaceContainerHigh,
            child: Text(
              pago.estado,
              style: TdsText.label(10, color: aprobado ? TdsColors.exito : TdsColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
