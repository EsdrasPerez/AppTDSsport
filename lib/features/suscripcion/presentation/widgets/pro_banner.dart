import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../perfil/domain/perfil.dart';
import '../../../perfil/providers/perfil_providers.dart';
import '../../domain/precios.dart';

/// Banner del plan: si es gratis invita a PRO; si es PRO/VIP muestra el plan y su renovación.
class ProBanner extends ConsumerWidget {
  const ProBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider);
    // Solo se oculta mientras carga; si falla se muestra como plan gratis
    if (perfil.isLoading && !perfil.hasValue) return const SizedBox.shrink();
    final p = perfil.valueOrNull;
    final plan = p?.planVigente ?? PlanUsuario.gratis;
    final esPro = plan != PlanUsuario.gratis;

    final String titulo;
    final String subtitulo;
    if (!esPro) {
      titulo = 'Mira qué pronosticaron tus rivales';
      subtitulo = 'Antes de que empiece el partido · ${Formatos.moneda(precioProMensual)} al mes';
    } else {
      titulo = 'Tu plan ${plan.etiqueta} está activo';
      final vence = p?.planVenceEn;
      subtitulo = vence == null
          ? 'Toca para ver tu suscripción'
          : (p!.planRenovar ? 'Se renueva el ${Formatos.fecha(vence)}' : 'Activo hasta el ${Formatos.fecha(vence)}');
    }

    return TdsCard.modulo(
      onTap: () => context.go(Rutas.suscripcion),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: TdsColors.acento.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.stars, color: TdsColors.acento, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(esPro ? 'TDS ${plan.etiqueta}' : 'HAZTE TDS PRO',
                    style: TdsText.label(11, color: TdsColors.acento, letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text(titulo, style: TdsText.headline(18)),
                Text(subtitulo, style: TdsText.body(12, color: TdsColors.textoSecundario)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          esPro
              ? TdsPillButton(
                  icon: Icons.visibility_outlined,
                  label: 'Ver rivales',
                  primary: true,
                  onTap: () => context.go(Rutas.rivales),
                )
              : TdsPillButton(
                  icon: Icons.bolt,
                  label: 'Ver planes',
                  primary: true,
                  onTap: () => context.go(Rutas.suscripcion),
                ),
        ],
      ),
    );
  }
}
