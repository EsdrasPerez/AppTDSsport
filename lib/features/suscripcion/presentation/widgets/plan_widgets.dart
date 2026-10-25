import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../perfil/domain/perfil.dart';
import '../../domain/plan_suscripcion.dart';
import '../../domain/precios.dart';

// -----------------------------------------------------------------------------
// Beneficios y Modelos de Planes
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
    this.base,
  });

  /// Tarjeta de un plan de la tabla planes: fusiona los datos de base de datos
  /// con la plantilla rica de beneficios de PRO o VIP.
  factory PlanInfo.desde(PlanSuscripcion p) {
    final limite = p.limiteQuinielas;
    final esVip = p.tipo == PlanUsuario.vip;
    final plantilla = esVip ? planVip : planPro;

    final beneficiosCombinados = <Beneficio>[
      ...plantilla.beneficios,
      if (limite != null)
        Beneficio(Icons.groups_outlined, 'Hasta $limite participantes:', 'en tus quinielas activas.')
      else if (esVip)
        const Beneficio(Icons.all_inclusive_outlined, 'Participantes ilimitados:', 'organiza ligas sin restricción de tamaño.'),
    ];

    return PlanInfo(
      plan: p.tipo,
      nombre: p.nombre.isNotEmpty ? p.nombre : plantilla.nombre,
      descripcion: (p.descripcion != null && p.descripcion!.isNotEmpty) ? p.descripcion! : plantilla.descripcion,
      precioMensual: p.precio > 0 ? p.precio : plantilla.precioMensual,
      beneficios: beneficiosCombinados,
      color: plantilla.color,
      base: p,
    );
  }

  final PlanUsuario plan;
  final String nombre;
  final String descripcion;
  final num precioMensual;
  final List<Beneficio> beneficios;
  final Color color;

  /// El plan de la tabla planes que se cobra (null en [planPro] / [planVip], que solo son modelos).
  final PlanSuscripcion? base;
}

const planPro = PlanInfo(
  plan: PlanUsuario.pro,
  nombre: 'PLAN PRO MVP',
  descripcion: 'Para estrategas del fútbol que buscan ganar su quiniela viendo cómo juegan sus rivales.',
  precioMensual: precioProMensual,
  color: TdsColors.primaryContainer,
  beneficios: [
    Beneficio(
      Icons.visibility_outlined,
      'Pronósticos de rivales:',
      'Mira qué pronosticaron tus amigos antes, durante y después de cada partido.',
    ),
    Beneficio(
      Icons.edit_calendar_outlined,
      'Edición libre de marcadores:',
      'Modifica tus pronósticos cuantas veces quieras antes del silbatazo inicial.',
    ),
    Beneficio(
      Icons.workspace_premium,
      'Insignia oficial PRO:',
      'Destaca con badge oficial verde neón en la tabla general y quinielas.',
    ),
    Beneficio(
      Icons.groups_outlined,
      'Comunidades ampliadas:',
      'Hasta 100 participantes por quiniela activa.',
    ),
    Beneficio(
      Icons.smart_toy_outlined,
      'TDS IA Predictor:',
      'Sugerencias de marcador basadas en estadísticas avanzadas.',
      proximamente: true,
    ),
  ],
);

const planVip = PlanInfo(
  plan: PlanUsuario.vip,
  nombre: 'PLAN VIP ELITE',
  descripcion: 'Máxima distinción y poder para creadores de comunidades, empresas y grandes ligas.',
  precioMensual: precioVipMensual,
  color: Color(0xFFFFB800), // Oro puro de alta distinción
  beneficios: [
    Beneficio(
      Icons.verified_outlined,
      'Todo lo del Plan PRO MVP:',
      'Acceso total a pronósticos de rivales y edición libre de marcadores.',
    ),
    Beneficio(
      Icons.diamond_outlined,
      'Insignia Dorada VIP Elite:',
      'Máximo prestigio visual y distinción en avatar, perfil y clasificaciones.',
    ),
    Beneficio(
      Icons.all_inclusive_outlined,
      'Participantes ilimitados:',
      'Crea ligas grandes de amigos u oficina sin ningún tope de miembros.',
    ),
    Beneficio(
      Icons.headset_mic_outlined,
      'Soporte prioritario 24/7:',
      'Atención rápida y canal preferencial para ti y tu comunidad.',
    ),
    Beneficio(
      Icons.auto_awesome,
      'Acceso anticipado TDS IA:',
      'Sé el primero en probar nuevas funciones predictivas y torneos.',
      proximamente: true,
    ),
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TdsColors.primaryContainer.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TdsPulse(
                  child: TdsPill(
                    color: TdsColors.surfaceContainerHigh,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 16, color: TdsColors.primaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          esPro ? 'ERES MIEMBRO TDS SPORT' : 'MEMBRESÍAS OFICIALES • TDS SPORT',
                          style: TdsText.label(11, color: TdsColors.primaryContainer, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: TdsText.headline(26).copyWith(height: 1.25),
                    children: const [
                      TextSpan(text: 'LLEVA TUS QUINIELAS AL '),
                      TextSpan(
                        text: 'SIGUIENTE NIVEL',
                        style: TextStyle(color: TdsColors.primaryContainer),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Descubre los pronósticos de tus rivales, ajusta tus marcadores antes del pitazo inicial y lidera la tabla con insignias exclusivas.',
                  textAlign: TextAlign.center,
                  style: TdsText.body(14, color: TdsColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: TdsColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      _Contador(
                        valor: Formatos.moneda(precioProMensual),
                        texto: 'PRO / mes',
                        color: TdsColors.primaryContainer,
                      ),
                      const _Contador(
                        valor: 'Sin plazos',
                        texto: 'Libertad total',
                        color: TdsColors.onSurface,
                      ),
                      const _Contador(
                        valor: '1 clic',
                        texto: 'Cancela cuando quieras',
                        color: Color(0xFFFFB800),
                      ),
                    ],
                  ),
                ),
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
          Text(valor, style: TdsText.stats(20, color: color)),
          const SizedBox(height: 4),
          Text(
            texto.toUpperCase(),
            textAlign: TextAlign.center,
            style: TdsText.label(10, color: TdsColors.onSurfaceVariant),
          ),
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
  final bool activo;
  final bool destacado;
  final VoidCallback onComprar;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final esVip = plan.plan == PlanUsuario.vip;
    final colorAcento = esVip ? const Color(0xFFFFB800) : TdsColors.primaryContainer;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: destacado || esVip ? TdsColors.surfaceContainerHigh : TdsColors.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: activo
              ? colorAcento
              : destacado
                  ? TdsColors.primaryContainer.withValues(alpha: 0.8)
                  : esVip
                      ? const Color(0xFFFFB800).withValues(alpha: 0.6)
                      : TdsColors.borde.withValues(alpha: 0.6),
          width: destacado || esVip || activo ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: activo
                ? colorAcento.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: activo ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TdsPill(
                color: colorAcento.withValues(alpha: 0.18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(esVip ? Icons.diamond_outlined : Icons.bolt, size: 14, color: colorAcento),
                    const SizedBox(width: 5),
                    Text(
                      esVip ? 'CLUB VIP ELITE' : 'MÁS POPULAR',
                      style: TdsText.label(11, color: colorAcento),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (destacado) ...[
                const TdsDot(color: TdsColors.primaryContainer, pulse: true),
                const SizedBox(width: 6),
                Text('RECOMENDADO', style: TdsText.label(11, color: TdsColors.primaryContainer, letterSpacing: 1.2)),
              ] else if (esVip) ...[
                const Icon(Icons.workspace_premium, size: 14, color: Color(0xFFFFB800)),
                const SizedBox(width: 4),
                Text('MÁXIMO NIVEL', style: TdsText.label(11, color: const Color(0xFFFFB800), letterSpacing: 1)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(plan.nombre, style: TdsText.headline(24)),
          const SizedBox(height: 6),
          Text(
            plan.descripcion,
            style: TdsText.body(13, color: TdsColors.onSurfaceVariant).copyWith(height: 1.35),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TdsColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TdsColors.borde.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatos.moneda(plan.precioMensual), style: TdsText.stats(38, color: colorAcento)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('/ mes', style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('LO QUE INCLUYE:', style: TdsText.label(11, color: TdsColors.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          for (final b in plan.beneficios) _BeneficioFila(beneficio: b, color: colorAcento),
          const SizedBox(height: 16),
          if (activo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorAcento.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colorAcento.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: colorAcento),
                  const SizedBox(width: 8),
                  Text('TU PLAN ACTUAL', style: TdsText.label(13, color: colorAcento)),
                ],
              ),
            )
          else if (esVip)
            SizedBox(
              width: double.infinity,
              child: Material(
                color: const Color(0xFFFFB800),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onComprar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.diamond_outlined, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text('Obtener VIP Elite', style: TdsText.label(13, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: TdsPillButton(
                icon: Icons.bolt,
                label: 'Obtener PRO MVP',
                primary: true,
                onTap: onComprar,
              ),
            ),
          if (activo && onCancelar != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onCancelar,
                style: TextButton.styleFrom(foregroundColor: TdsColors.error),
                icon: const Icon(Icons.cancel_outlined, size: 16),
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
      opacity: b.proximamente ? 0.65 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(b.icono, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TdsText.body(13).copyWith(height: 1.35),
                  children: [
                    TextSpan(text: '${b.titulo} ', style: TdsText.label(13)),
                    TextSpan(text: b.detalle, style: const TextStyle(color: TdsColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            if (b.proximamente) ...[
              const SizedBox(width: 6),
              TdsPill(
                color: TdsColors.surfaceContainerHighest,
                child: Text('PRÓX.', style: TdsText.label(9, color: TdsColors.onSurfaceVariant)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PlanGratuitoCard extends StatelessWidget {
  const PlanGratuitoCard({
    super.key,
    required this.activo,
    required this.onVolver,
    this.puedeVolver = true,
  });

  final bool activo;
  final VoidCallback onVolver;
  final bool puedeVolver;

  @override
  Widget build(BuildContext context) {
    Widget fila(IconData icono, String titulo, String detalle, {bool esNegativo = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: esNegativo
                      ? TdsColors.error.withValues(alpha: 0.12)
                      : TdsColors.onSurfaceVariant.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  size: 14,
                  color: esNegativo ? TdsColors.error : TdsColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TdsText.body(13).copyWith(height: 1.35),
                    children: [
                      TextSpan(text: '$titulo ', style: TdsText.label(13)),
                      TextSpan(
                        text: detalle,
                        style: TextStyle(
                          color: esNegativo ? TdsColors.onSurfaceVariant.withValues(alpha: 0.7) : TdsColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: activo ? TdsColors.primaryContainer.withValues(alpha: 0.5) : TdsColors.borde.withValues(alpha: 0.4),
          width: activo ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TdsPill(
                color: TdsColors.surfaceContainerHigh,
                child: Text('PLAN BÁSICO', style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
              ),
              const Spacer(),
              Text('SIEMPRE LIBRE', style: TdsText.label(11, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text('PLAN GRATUITO', style: TdsText.headline(24)),
          const SizedBox(height: 6),
          Text(
            'Disfruta de la emoción del fútbol y compite con amigos sin costo.',
            style: TdsText.body(13, color: TdsColors.onSurfaceVariant).copyWith(height: 1.35),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TdsColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TdsColors.borde.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatos.moneda(precioGratis), style: TdsText.stats(38, color: TdsColors.onSurface)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('· sin costo mensual', style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('LO QUE INCLUYE:', style: TdsText.label(11, color: TdsColors.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          fila(Icons.check, 'Quinielas privadas y públicas:', 'Crea quinielas y únete con el código de tus amigos.'),
          fila(Icons.check, 'Puntos y posiciones:', 'Cálculo automático de la tabla con cada resultado.'),
          fila(Icons.lock_outline, 'Marcadores fijos:', 'Sin cambios tras guardar tu pronóstico inicial.', esNegativo: true),
          fila(Icons.visibility_off_outlined, 'Sin vista de rivales:', 'Solo puedes ver tus propios marcadores.', esNegativo: true),
          const SizedBox(height: 16),
          if (activo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: TdsColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: TdsColors.borde.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text('TU PLAN ACTUAL', style: TdsText.label(13, color: TdsColors.onSurfaceVariant)),
              ),
            )
          else if (puedeVolver)
            SizedBox(
              width: double.infinity,
              child: TdsPillButton(
                icon: Icons.undo,
                label: 'Volver a Plan Gratuito',
                onTap: onVolver,
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tabla Comparativa de Planes (Free vs PRO vs VIP)
// -----------------------------------------------------------------------------

class _ItemComparativo {
  const _ItemComparativo({
    required this.caracteristica,
    required this.detalle,
    required this.gratis,
    required this.pro,
    required this.vip,
  });

  final String caracteristica;
  final String detalle;
  final String gratis;
  final String pro;
  final String vip;
}

class TablaComparativaPlanes extends StatelessWidget {
  const TablaComparativaPlanes({super.key});

  static const _filas = [
    _ItemComparativo(
      caracteristica: 'Ver pronósticos de rivales',
      detalle: 'Conoce los marcadores que eligieron los demás participantes',
      gratis: 'no',
      pro: 'si',
      vip: 'si',
    ),
    _ItemComparativo(
      caracteristica: 'Edición de marcadores',
      detalle: 'Modifica tus goles las veces que quieras antes de iniciar el partido',
      gratis: 'fijo',
      pro: 'si',
      vip: 'si',
    ),
    _ItemComparativo(
      caracteristica: 'Insignia oficial en perfil y ranking',
      detalle: 'Distintivo visual junto a tu nombre en todas las tablas',
      gratis: 'no',
      pro: 'badge_pro',
      vip: 'badge_vip',
    ),
    _ItemComparativo(
      caracteristica: 'Participantes por quiniela',
      detalle: 'Capacidad máxima de amigos en las quinielas que administras',
      gratis: 'Hasta 20',
      pro: 'Hasta 100',
      vip: 'Ilimitados',
    ),
    _ItemComparativo(
      caracteristica: 'Crear y unirte a quinielas',
      detalle: 'Ligas con amigos mediante código de acceso',
      gratis: 'si',
      pro: 'si',
      vip: 'si',
    ),
    _ItemComparativo(
      caracteristica: 'Puntos y posiciones al instante',
      detalle: 'Actualización en vivo al finalizar los partidos oficiales',
      gratis: 'si',
      pro: 'si',
      vip: 'si',
    ),
    _ItemComparativo(
      caracteristica: 'Soporte al usuario',
      detalle: 'Canal de atención y resolución ante dudas o problemas',
      gratis: 'Estándar',
      pro: 'Estándar',
      vip: '⭐ 24/7 VIP',
    ),
    _ItemComparativo(
      caracteristica: 'TDS IA Predictor',
      detalle: 'Recomendaciones inteligentes basadas en estadísticas',
      gratis: 'no',
      pro: 'prox',
      vip: 'prox_vip',
    ),
  ];

  Widget _celda(String valor, {bool esVip = false, bool esPro = false}) {
    if (valor == 'si') {
      final color = esVip ? const Color(0xFFFFB800) : TdsColors.exito;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text('Sí', style: TdsText.label(12, color: color)),
        ],
      );
    }
    if (valor == 'no') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close_rounded, size: 16, color: TdsColors.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(width: 4),
          Text('No', style: TdsText.body(12, color: TdsColors.onSurfaceVariant.withValues(alpha: 0.5))),
        ],
      );
    }
    if (valor == 'fijo') {
      return Text('Fijo al guardar', style: TdsText.body(11, color: TdsColors.advertencia));
    }
    if (valor == 'badge_pro') {
      return TdsPill(
        color: TdsColors.primaryContainer.withValues(alpha: 0.2),
        child: Text('PRO ⚡', style: TdsText.label(10, color: TdsColors.primaryContainer)),
      );
    }
    if (valor == 'badge_vip') {
      return TdsPill(
        color: const Color(0xFFFFB800).withValues(alpha: 0.2),
        child: Text('VIP 👑', style: TdsText.label(10, color: const Color(0xFFFFB800))),
      );
    }
    if (valor == 'prox') {
      return TdsPill(
        color: TdsColors.surfaceContainerHighest,
        child: Text('Próx.', style: TdsText.label(9, color: TdsColors.onSurfaceVariant)),
      );
    }
    if (valor == 'prox_vip') {
      return TdsPill(
        color: const Color(0xFFFFB800).withValues(alpha: 0.15),
        child: Text('Anticipado', style: TdsText.label(9, color: const Color(0xFFFFB800))),
      );
    }
    return Text(
      valor,
      style: TdsText.label(12, color: esVip ? const Color(0xFFFFB800) : esPro ? TdsColors.primaryContainer : TdsColors.onSurface),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TdsColors.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.table_chart_outlined, size: 20, color: TdsColors.primaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TABLA COMPARATIVA DE PLANES', style: TdsText.headline(16)),
                      Text(
                        'Conoce a fondo las diferencias entre cada nivel de membresía',
                        style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TdsColors.borde),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 640),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(TdsColors.surfaceContainerHigh),
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                horizontalMargin: 20,
                columnSpacing: 24,
                columns: [
                  DataColumn(
                    label: Text('CARACTERÍSTICA', style: TdsText.label(11, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
                  ),
                  DataColumn(
                    label: Text('GRATIS (Q0)', style: TdsText.label(11, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
                  ),
                  DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 14, color: TdsColors.primaryContainer),
                        const SizedBox(width: 4),
                        Text('PRO MVP (Q50)', style: TdsText.label(11, color: TdsColors.primaryContainer, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_outlined, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                        Text('VIP ELITE (Q100)', style: TdsText.label(11, color: const Color(0xFFFFB800), letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
                rows: [
                  for (final (i, f) in _filas.indexed)
                    DataRow(
                      color: WidgetStateProperty.all(
                        i.isEven ? Colors.transparent : TdsColors.surfaceContainerLow.withValues(alpha: 0.5),
                      ),
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.caracteristica, style: TdsText.label(13)),
                              Text(f.detalle, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        DataCell(_celda(f.gratis)),
                        DataCell(_celda(f.pro, esPro: true)),
                        DataCell(_celda(f.vip, esVip: true)),
                      ],
                    ),
                ],
              ),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: TdsColors.surfaceContainer,
                child: Icon(icono, size: 20, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: TdsText.label(14)),
                    Text(texto, style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: TdsColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          item(Icons.bolt_rounded, TdsColors.primaryContainer, 'Activación Inmediata', 'Tu plan se activa al segundo de aprobarse el pago.'),
          item(Icons.cancel_outlined, const Color(0xFFFFB800), 'Cancela en 1 Clic', 'Sin penalizaciones ni llamadas. Directo desde esta pantalla.'),
          item(Icons.lock_outline_rounded, TdsColors.exito, 'Pago 100% Seguro', 'Cifrado de grado bancario. Nunca guardamos datos de tu tarjeta.'),
        ],
      ),
    );
  }
}

class PreguntasFrecuentes extends StatelessWidget {
  const PreguntasFrecuentes({super.key});

  static final _preguntas = [
    (
      '¿Cuánto cuesta cada membresía?',
      'El Plan PRO MVP tiene un costo de ${precioPorMes(precioProMensual)} y el Plan VIP Elite cuesta ${precioPorMes(precioVipMensual)}. '
          'El pago es mensual con tarjeta de crédito o débito (Visa, Mastercard o American Express).'
    ),
    (
      '¿Qué gano viendo los pronósticos de mis rivales?',
      'Tienes acceso total para ver en tiempo real qué marcador y resultado pronosticaron todos los participantes '
          'de tus quinielas en la pantalla dedicada "Pronósticos de rivales". Esto te permite jugar con ventaja táctica.'
    ),
    (
      '¿Cómo funciona la edición de marcadores?',
      'En el Plan Gratuito, una vez que guardas un pronóstico, queda bloqueado. Con PRO MVP o VIP Elite, '
          'puedes modificar y ajustar tus marcadores cuantas veces quieras hasta el momento exacto en que inicia el partido.'
    ),
    (
      '¿Cómo se realiza el cobro y la cancelación?',
      'El cobro se procesa mensualmente de forma automática. Puedes cancelar la renovación en cualquier momento '
          'desde esta misma pantalla en 1 clic. Mantendrás todos los beneficios activos hasta que venza tu ciclo pagado.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: TdsColors.primaryContainer, size: 20),
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
                iconColor: TdsColors.primaryContainer,
                collapsedIconColor: TdsColors.onSurfaceVariant,
                title: Text(pregunta, style: TdsText.label(14)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    respuesta,
                    style: TdsText.body(13, color: TdsColors.onSurfaceVariant).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
