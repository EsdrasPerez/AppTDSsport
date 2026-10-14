import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../perfil/domain/perfil.dart';
import '../../domain/precios.dart';

// -----------------------------------------------------------------------------
// Datos de los planes (precios en precios.dart)
// -----------------------------------------------------------------------------

class Beneficio {
  const Beneficio(this.icono, this.titulo, this.detalle, {this.proximamente = false});

  final IconData icono;
  final String titulo;
  final String detalle;

  /// Todavía no existe en la app: se muestra con la etiqueta "Próximamente".
  final bool proximamente;
}

class PlanInfo {
  const PlanInfo({
    required this.plan,
    required this.nombre,
    required this.descripcion,
    required this.precioMensual,
    required this.beneficios,
    required this.color,
  });

  final PlanUsuario plan;
  final String nombre;
  final String descripcion;
  final int precioMensual;
  final List<Beneficio> beneficios;
  final Color color;
}

// TODO(decision): D1 — "Quinielas sin límite" se quitó porque el plan gratis no tiene límite.
const planPro = PlanInfo(
  plan: PlanUsuario.pro,
  nombre: 'PLAN PRO MVP',
  descripcion: 'Para quienes quieren analizar cómo juegan sus rivales y ganar sus quinielas.',
  precioMensual: precioProMensual,
  color: TdsColors.primaryContainer,
  beneficios: [
    // Reales: RLS "Lectura pronosticos" (migración 03) y pantalla /rivales
    Beneficio(Icons.visibility_outlined, 'Pronósticos de rivales:',
        'mira lo que pronosticaron antes, durante y después de cada partido, y ajusta el tuyo antes de que empiece.'),
    Beneficio(Icons.workspace_premium, 'Insignia PRO', 'junto a tu nombre en la tabla de posiciones.'),
    Beneficio(Icons.groups_outlined, 'Quinielas más grandes:', 'hasta 100 participantes por quiniela.'),
    // Planeados
    Beneficio(Icons.smart_toy_outlined, 'TDS IA Predictor:', 'sugerencias de marcador basadas en estadísticas.',
        proximamente: true),
    Beneficio(Icons.notifications_active_outlined, 'Alertas al instante:', 'inicio de partidos y goles.',
        proximamente: true),
  ],
);

const planVip = PlanInfo(
  plan: PlanUsuario.vip,
  nombre: 'PLAN VIP ELITE',
  descripcion: 'Para creadores de comunidades y quinielas grandes entre amigos o la oficina.',
  precioMensual: precioVipMensual,
  color: TdsColors.secondaryContainer,
  beneficios: [
    Beneficio(Icons.verified_outlined, 'Todo lo del Plan PRO MVP', 'incluido.'),
    Beneficio(Icons.diamond_outlined, 'Insignia VIP', 'junto a tu nombre en la tabla de posiciones.'),
    Beneficio(Icons.group_add_outlined, 'Ligas privadas', 'con reglas de puntos personalizadas.', proximamente: true),
    Beneficio(Icons.headset_mic_outlined, 'Soporte prioritario', 'para ti y tu comunidad.', proximamente: true),
  ],
);

// -----------------------------------------------------------------------------
// Hero
// -----------------------------------------------------------------------------

class HeroPro extends StatelessWidget {
  const HeroPro({super.key, required this.esPro});

  final bool esPro;

  @override
  Widget build(BuildContext context) {
    return TdsCard(
      glow: true,
      child: Column(
        children: [
          const SizedBox(height: 8),
          TdsPulse(
            child: TdsPill(
              color: TdsColors.surfaceContainerHigh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, size: 18, color: TdsColors.primaryContainer),
                  const SizedBox(width: 6),
                  Text(esPro ? 'ERES TDS PRO' : 'TDS PRO PASS • VIP',
                      style: TdsText.label(11, color: TdsColors.primaryContainer, letterSpacing: 1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: TdsText.headline(28).copyWith(height: 1.2),
              children: const [
                TextSpan(text: 'ELEVA TUS PRONÓSTICOS AL NIVEL '),
                TextSpan(text: 'PRO', style: TextStyle(color: TdsColors.primaryContainer)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Descubre cómo pronostican tus rivales, presume tu insignia y prepárate para las nuevas funciones.',
            textAlign: TextAlign.center,
            style: TdsText.body(15, color: TdsColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _Contador(valor: Formatos.moneda(precioProMensual), texto: 'Al mes', color: TdsColors.primaryContainer),
                const _Contador(valor: '1 clic', texto: 'Activación', color: TdsColors.onSurface),
                const _Contador(valor: '1 clic', texto: 'Cancelación', color: TdsColors.secondaryContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.texto, required this.color});

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
          Text(texto.toUpperCase(), style: TdsText.label(10, color: TdsColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cards de planes
// -----------------------------------------------------------------------------

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.activo,
    required this.onComprar,
    this.onCancelar,
    this.destacado = false,
  });

  final PlanInfo plan;

  /// El usuario ya es PRO (la base solo tiene es_pro, sin distinguir PRO/VIP).
  final bool activo;
  final bool destacado;
  final VoidCallback onComprar;

  /// Si se pasa y el plan está activo, muestra el botón "Cancelar plan".
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: destacado ? TdsColors.surfaceContainerHigh : TdsColors.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: activo && destacado ? Border.all(color: TdsColors.primaryContainer, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TdsPill(
                color: destacado ? TdsColors.primaryContainer : plan.color.withValues(alpha: 0.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(destacado ? Icons.bolt : Icons.diamond_outlined,
                        size: 14, color: destacado ? TdsColors.onPrimary : plan.color),
                    const SizedBox(width: 4),
                    Text(destacado ? 'MÁS POPULAR' : 'CLUB PRIVADO',
                        style: TdsText.label(11, color: destacado ? TdsColors.onPrimary : plan.color)),
                  ],
                ),
              ),
              const Spacer(),
              if (destacado) ...[
                const TdsDot(color: TdsColors.primaryContainer, pulse: true),
                const SizedBox(width: 6),
                Text('RECOMENDADO', style: TdsText.label(12, color: TdsColors.primaryContainer, letterSpacing: 1.5)),
              ] else
                Text('ALTA COMPETENCIA', style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Text(plan.nombre, style: TdsText.headline(28)),
          const SizedBox(height: 4),
          Text(plan.descripcion, style: TdsText.body(14, color: TdsColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: TdsColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatos.moneda(plan.precioMensual), style: TdsText.stats(44, color: plan.color)),
                const SizedBox(width: 8),
                Text('/ mes', style: TdsText.body(14, color: TdsColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final b in plan.beneficios) _BeneficioFila(beneficio: b, color: plan.color),
          const SizedBox(height: 16),
          if (activo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: TdsColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 18, color: TdsColors.primaryContainer),
                  const SizedBox(width: 6),
                  Text('YA TIENES PRO ACTIVO', style: TdsText.label(14, color: TdsColors.primaryContainer)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: TdsPillButton(
                icon: Icons.arrow_forward,
                label: 'Suscribirme',
                primary: destacado,
                onTap: onComprar,
              ),
            ),
          if (activo && onCancelar != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onCancelar,
                style: TextButton.styleFrom(foregroundColor: TdsColors.error),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancelar plan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BeneficioFila extends StatelessWidget {
  const _BeneficioFila({required this.beneficio, required this.color});

  final Beneficio beneficio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final b = beneficio;
    return Opacity(
      opacity: b.proximamente ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(b.icono, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TdsText.body(14),
                  children: [
                    TextSpan(text: '${b.titulo} ', style: TdsText.label(14)),
                    TextSpan(text: b.detalle),
                  ],
                ),
              ),
            ),
            if (b.proximamente) ...[
              const SizedBox(width: 6),
              TdsPill(child: Text('PRÓXIMAMENTE', style: TdsText.label(9, color: TdsColors.onSurfaceVariant))),
            ],
          ],
        ),
      ),
    );
  }
}

class PlanGratuitoCard extends StatelessWidget {
  const PlanGratuitoCard({super.key, required this.activo, required this.onVolver, this.puedeVolver = true});

  final bool activo;
  final VoidCallback onVolver;

  /// false si la suscripción ya está cancelada (solo falta que venza).
  final bool puedeVolver;

  @override
  Widget build(BuildContext context) {
    Widget fila(IconData icono, String texto, {Color color = TdsColors.onSurfaceVariant}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(texto, style: TdsText.body(14, color: TdsColors.onSurfaceVariant))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdsColors.surfaceContainerLow, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('PLAN GRATUITO', style: TdsText.label(14, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
              ),
              if (activo) TdsPill(child: Text('PLAN ACTIVO', style: TdsText.label(10, color: TdsColors.onSurfaceVariant))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatos.moneda(precioGratis), style: TdsText.stats(32)),
              const SizedBox(width: 8),
              Text('· siempre libre', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          fila(Icons.check, 'Crea quinielas, únete con código y haz tus pronósticos.'),
          fila(Icons.check, 'Tabla de posiciones y puntos automáticos.'),
          fila(Icons.close, 'Solo ves tus propios pronósticos.', color: TdsColors.error),
          const SizedBox(height: 8),
          if (activo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: TdsColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
              child: Text('TU PLAN ACTUAL',
                  textAlign: TextAlign.center, style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
            )
          else if (puedeVolver)
            SizedBox(
              width: double.infinity,
              child: TdsPillButton(icon: Icons.undo, label: 'Cancelar suscripción', onTap: onVolver),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Garantías y FAQ
// -----------------------------------------------------------------------------

class GarantiasCard extends StatelessWidget {
  const GarantiasCard({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icono, Color color, String titulo, String texto) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: TdsColors.surfaceContainer, child: Icon(icono, size: 20, color: color)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: TdsText.label(14)),
                    Text(texto, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TdsColors.surfaceContainerLow, borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          item(Icons.bolt, TdsColors.acento, 'Activación inmediata', 'Tu plan se activa al aprobarse el pago'),
          item(Icons.cancel_outlined, TdsColors.secondaryContainer, 'Cancela en 1 clic', 'Desde esta misma pantalla'),
          item(Icons.lock_outline, TdsColors.primaryContainer, 'Pago seguro', 'No guardamos los datos de tu tarjeta'),
        ],
      ),
    );
  }
}

class PreguntasFrecuentes extends StatelessWidget {
  const PreguntasFrecuentes({super.key});

  static final _preguntas = [
    (
      '¿Cuánto cuesta?',
      'PRO MVP cuesta ${precioPorMes(precioProMensual)} y VIP Elite ${precioPorMes(precioVipMensual)}. '
          'El pago es mensual con tarjeta de crédito o débito (Visa, Mastercard o American Express).'
    ),
    (
      '¿Cómo se realiza el cobro?',
      'El cobro se hace a tu tarjeta cada mes. Puedes cancelar cuando quieras desde esta pantalla.'
    ),
    (
      '¿Qué gano con PRO?',
      'Ves lo que pronosticaron los demás participantes de tus quinielas antes, durante y después de cada partido, '
          'y puedes ajustar tu pronóstico mientras el partido no empiece. Además, tu nombre lleva la insignia PRO.'
    ),
    (
      '¿Qué pasa si cancelo?',
      'Tu plan sigue activo hasta el final del periodo pagado y después tu cuenta pasa al plan gratuito.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline, color: TdsColors.primaryContainer, size: 20),
            const SizedBox(width: 8),
            Text('PREGUNTAS FRECUENTES', style: TdsText.headline(18)),
          ],
        ),
        const SizedBox(height: 12),
        for (final (pregunta, respuesta) in _preguntas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: TdsColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: TdsColors.onSurfaceVariant,
                collapsedIconColor: TdsColors.onSurfaceVariant,
                title: Text(pregunta, style: TdsText.label(14)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(respuesta, style: TdsText.body(14, color: TdsColors.onSurfaceVariant))],
              ),
            ),
          ),
      ],
    );
  }
}
