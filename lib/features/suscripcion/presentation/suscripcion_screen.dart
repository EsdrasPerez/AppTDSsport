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

/// Planes, plan actual, cancelación y "Mis pagos".
class SuscripcionScreen extends ConsumerStatefulWidget {
  const SuscripcionScreen({super.key});

  @override
  ConsumerState<SuscripcionScreen> createState() => _SuscripcionScreenState();
}

class _SuscripcionScreenState extends ConsumerState<SuscripcionScreen> {
  bool _procesando = false;

  void _suscribirme(PlanInfo plan) => context.push(Rutas.pago(plan.plan.codigo.toLowerCase()));

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
      appBar: const TdsAppBar(titulo: 'SUSCRIPCIÓN'),
      body: AsyncValueView(
        value: perfil,
        onReintentar: () => ref.invalidate(perfilActualProvider),
        data: (p) {
          final plan = p?.planVigente ?? PlanUsuario.gratis;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
                children: [
                  if (p != null && plan != PlanUsuario.gratis) ...[
                    _MiPlan(perfil: p, onCancelar: () => _cancelar(p)),
                    const SizedBox(height: 24),
                  ] else ...[
                    HeroPro(esPro: false),
                    const SizedBox(height: 24),
                  ],
                  PlanCard(
                    plan: planPro,
                    destacado: true,
                    activo: plan == PlanUsuario.pro,
                    onComprar: () => _suscribirme(planPro),
                  ),
                  const SizedBox(height: 24),
                  PlanCard(plan: planVip, activo: plan == PlanUsuario.vip, onComprar: () => _suscribirme(planVip)),
                  const SizedBox(height: 24),
                  PlanGratuitoCard(
                    activo: plan == PlanUsuario.gratis,
                    onVolver: () {
                      if (p != null) _cancelar(p);
                    },
                    puedeVolver: p?.planRenovar ?? true,
                  ),
                  const SizedBox(height: 24),
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

/// Plan actual con su renovación o vencimiento.
class _MiPlan extends StatelessWidget {
  const _MiPlan({required this.perfil, required this.onCancelar});

  final Perfil perfil;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final vence = perfil.planVenceEn;
    final texto = vence == null
        ? 'Plan activo'
        : perfil.planRenovar
            ? 'Se renueva el ${Formatos.fecha(vence)}'
            : 'Activo hasta el ${Formatos.fecha(vence)} · no se renovará';

    return TdsCard(
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: TdsColors.acento, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text('Tu plan: ${perfil.plan.etiqueta}', style: TdsText.headline(22))),
              TdsPill(
                color: TdsColors.exito,
                child: Text('ACTIVO', style: TdsText.label(10, color: TdsColors.texto)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(texto, style: TdsText.body(14, color: TdsColors.textoSecundario)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TdsPillButton(
                  icon: Icons.visibility_outlined,
                  label: 'Pronósticos de rivales',
                  primary: true,
                  onTap: () => context.go(Rutas.rivales),
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
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancelar suscripción'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Historial de pagos: fecha, plan, monto, tarjeta y estado.
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
            const Icon(Icons.receipt_long, color: TdsColors.acento, size: 20),
            const SizedBox(width: 8),
            Text('MIS PAGOS', style: TdsText.headline(18)),
          ],
        ),
        const SizedBox(height: 12),
        pagos.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(padding: EdgeInsets.all(16), child: CargandoView()),
          error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(misPagosProvider)),
          data: (lista) => lista.isEmpty
              ? TdsCard(
                  child: Text('Aún no tienes pagos.',
                      textAlign: TextAlign.center, style: TdsText.body(14, color: TdsColors.textoSecundario)),
                )
              : TdsCard(
                  padding: EdgeInsets.zero,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TdsColors.borde))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan ${pago.plan.etiqueta} · ${Formatos.moneda(pago.monto)}', style: TdsText.label(14)),
                Text('${Formatos.fecha(pago.fecha)} · ${pago.marca} •••• ${pago.ultimos4}',
                    style: TdsText.body(12, color: TdsColors.textoSecundario)),
              ],
            ),
          ),
          TdsPill(
            color: aprobado ? TdsColors.exito : TdsColors.superficieAlta,
            child: Text(pago.estado, style: TdsText.label(10, color: aprobado ? TdsColors.texto : TdsColors.textoSecundario)),
          ),
        ],
      ),
    );
  }
}
