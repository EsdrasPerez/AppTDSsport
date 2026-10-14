import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../domain/etiquetas_puntos.dart';
import '../../domain/quiniela_models.dart';
import 'resultado_quiniela_badge.dart';

/// Card grande de la quiniela destacada: métricas, avance y desglose de pronósticos.
class QuinielaDestacadaCard extends StatelessWidget {
  const QuinielaDestacadaCard({super.key, required this.quiniela});

  final ResumenQuiniela quiniela;

  @override
  Widget build(BuildContext context) {
    final q = quiniela;
    final pctAvance = (q.avance * 100).round();

    return TdsCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cabecera(quiniela: q),
          const SizedBox(height: 12),
          Text(q.nombre, style: TdsText.headline(26).copyWith(height: 1.15)),
          Text(q.torneoNombre, style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                _Metrica(titulo: 'ACIERTOS', valor: '${q.aciertos}', sufijo: '/ ${q.finalizados.length} jug.'),
                _Metrica(
                  titulo: 'TU POSICIÓN',
                  valor: '#${q.lugar}',
                  sufijo: '/ ${q.participantes}',
                  color: TdsColors.secondaryContainer,
                  resaltada: true,
                ),
                _Metrica(titulo: 'PUNTOS', valor: '${q.puntos}', sufijo: 'pts', color: TdsColors.onSurface),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Avance de la Quiniela', style: TdsText.label(12, color: TdsColors.onSurfaceVariant))),
              Text('$pctAvance% (${q.finalizados.length} de ${q.totalPartidos} partidos)',
                  style: TdsText.label(12, color: TdsColors.primaryContainer)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: q.avance,
              minHeight: 8,
              backgroundColor: TdsColors.surfaceContainerHighest,
              semanticsLabel: 'Avance de la quiniela',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.checklist, color: TdsColors.primaryContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('DESGLOSE DE TUS PRONÓSTICOS (${q.pronosticos.length})',
                    style: TdsText.label(12, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (q.partidos.isEmpty)
            Text('Este torneo aún no tiene partidos.', style: TdsText.body(13, color: TdsColors.onSurfaceVariant))
          else
            for (final p in _ordenDesglose(q.partidos)) PronosticoFila(partido: p, pronostico: q.pronosticos[p.id]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TdsPillButton(
                  icon: Icons.share_outlined,
                  label: 'Copiar código',
                  onTap: () => copiarCodigo(context, q.codigoAcceso),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TdsPillButton(
                  icon: Icons.open_in_new,
                  label: 'Ver detalle',
                  primary: true,
                  onTap: () => context.push(Rutas.quiniela(q.id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Finalizados → en vivo → futuros → suspendidos.
  List<Partido> _ordenDesglose(List<Partido> partidos) {
    int peso(EstadoPartido e) => switch (e) {
          EstadoPartido.finalizado => 0,
          EstadoPartido.enVivo => 1,
          EstadoPartido.futuro => 2,
          EstadoPartido.suspendido => 3,
        };
    return [...partidos]..sort((a, b) => peso(a.estado).compareTo(peso(b.estado)));
  }
}

/// Card compacta, con desglose desplegable. En una quiniela finalizada muestra el resultado (4.7).
class QuinielaCompactaCard extends StatefulWidget {
  const QuinielaCompactaCard({super.key, required this.quiniela, this.miId});

  final ResumenQuiniela quiniela;

  /// Para la etiqueta "Creada por ti".
  final String? miId;

  @override
  State<QuinielaCompactaCard> createState() => _QuinielaCompactaCardState();
}

class _QuinielaCompactaCardState extends State<QuinielaCompactaCard> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quiniela;
    final finalizada = !q.activa; // finalizada o anulada
    final conPronostico = q.partidos.where((p) => q.pronosticos.containsKey(p.id)).toList();

    return TdsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(Rutas.quiniela(q.id, soloLectura: finalizada)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Cabecera(quiniela: q, compacta: true),
                          if (finalizada)
                            ResultadoQuinielaBadge(
                              resultado: q.resultado,
                              lugar: q.lugar,
                              total: q.participantes,
                              empate: q.empateEnPrimero,
                            ),
                          if (q.esCreador(widget.miId))
                            TdsPill(child: Text('CREADA POR TI', style: TdsText.label(10, color: TdsColors.secondaryContainer))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(q.nombre, style: TdsText.headline(18)),
                      Text(q.torneoNombre, style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: TdsColors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: finalizada
                  ? [
                      _Dato(titulo: 'Resultado', valor: '${q.aciertos} / ${q.finalizados.length} aciertos'),
                      _Dato(
                          titulo: 'Posición final',
                          valor: '#${q.lugar} de ${q.participantes}',
                          color: TdsColors.secondaryContainer),
                      _Dato(titulo: 'Puntos', valor: '${q.puntos} pts', color: TdsColors.primaryContainer),
                    ]
                  : [
                      _Dato(titulo: 'Participantes', valor: '${q.participantes} / ${q.limiteUsuarios}'),
                      _Dato(titulo: 'Pronósticos', valor: '${q.futurosListos} de ${q.futuros.length} listos'),
                      _Dato(titulo: 'Puntos', valor: '${q.puntos} pts', color: TdsColors.primaryContainer),
                    ],
            ),
          ),
          if (conPronostico.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('TUS ${conPronostico.length} SELECCIONES GUARDADAS:',
                style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final p in conPronostico)
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TdsColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(signo(q.pronosticos[p.id]!.golesLocal, q.pronosticos[p.id]!.golesVisitante),
                        style: TdsText.label(12, color: TdsColors.primaryContainer)),
                  ),
                if (!finalizada && q.futuros.isNotEmpty && q.futurosListos == q.futuros.length)
                  Text('✓ Completos', style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Material(
            color: TdsColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expandida = !_expandida),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(finalizada ? 'Ver pronósticos y resultados' : 'Ver todos los pronósticos',
                        style: TdsText.label(12)),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expandida ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 18, color: TdsColors.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _expandida
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        if (q.partidos.isEmpty)
                          Text('Este torneo aún no tiene partidos.',
                              style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
                        for (final p in q.partidos) PronosticoFila(partido: p, pronostico: q.pronosticos[p.id]),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Fila del desglose: estado + marcador, mi pronóstico y badge de puntos.
class PronosticoFila extends StatelessWidget {
  const PronosticoFila({super.key, required this.partido, this.pronostico});

  final Partido partido;
  final Pronostico? pronostico;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final pr = pronostico;
    final marcador = '${golesTexto(p.golesLocal)} - ${golesTexto(p.golesVisitante)}';
    final partidoTexto = switch (p.estado) {
      EstadoPartido.finalizado || EstadoPartido.enVivo => '${p.local.nombre} $marcador ${p.visitante.nombre}',
      _ => '${p.local.nombre} vs ${p.visitante.nombre}',
    };

    // ¿El signo de mi pronóstico coincide con el marcador actual? (solo para la etiqueta "PARCIAL")
    final acertando = pr != null &&
        p.tieneMarcador &&
        signo(pr.golesLocal, pr.golesVisitante) == signo(p.golesLocal!, p.golesVisitante!);
    final fallado = p.estado == EstadoPartido.finalizado && (pr == null || pr.puntos == 0);

    final Widget badge = switch (p.estado) {
      EstadoPartido.finalizado when pr != null && pr.puntos > 0 => _Badge(
          icono: Icons.check_circle,
          texto: '+${pr.puntos} pts',
          fondo: TdsColors.exito,
          color: TdsColors.texto),
      EstadoPartido.finalizado => const _Badge(icono: Icons.cancel, texto: '0 pts'),
      EstadoPartido.enVivo when pr == null => const _Badge(texto: 'SIN PRONÓSTICO'),
      EstadoPartido.enVivo => _Badge(
          icono: acertando ? Icons.sync : Icons.warning_amber_rounded,
          texto: acertando ? 'PARCIAL' : 'EN RIESGO',
          color: acertando ? TdsColors.primaryContainer : TdsColors.error,
        ),
      EstadoPartido.suspendido => const _Badge(texto: 'SUSPENDIDO'),
      EstadoPartido.futuro => const _Badge(texto: 'PENDIENTE'),
    };

    return Opacity(
      opacity: fallado ? 0.8 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.estado == EstadoPartido.futuro
              ? TdsColors.surfaceContainerHigh.withValues(alpha: 0.6)
              : TdsColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      EstadoPartidoPill(estado: p.estado, fecha: p.fecha),
                      Text(partidoTexto, style: TdsText.label(12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Tu pronóstico:', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                      _PronosticoChip(pronostico: pr, partido: p, fallado: fallado, acertando: acertando),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            badge,
          ],
        ),
      ),
    );
  }
}

class _PronosticoChip extends StatelessWidget {
  const _PronosticoChip({
    required this.pronostico,
    required this.partido,
    required this.fallado,
    required this.acertando,
  });

  final Pronostico? pronostico;
  final Partido partido;
  final bool fallado;
  final bool acertando;

  @override
  Widget build(BuildContext context) {
    final pr = pronostico;
    if (pr == null) return Text('—', style: TdsText.label(12, color: TdsColors.onSurfaceVariant));

    final s = signo(pr.golesLocal, pr.golesVisitante);
    final texto = '${pr.golesLocal}-${pr.golesVisitante} · $s (${nombreSigno(s)})';
    final enVivo = partido.estado == EstadoPartido.enVivo;
    final finalizado = partido.estado == EstadoPartido.finalizado;

    final (fondo, color) = fallado
        ? (TdsColors.surfaceContainerHighest, TdsColors.onSurfaceVariant)
        : enVivo && acertando
            ? (TdsColors.primaryContainer, TdsColors.onPrimary)
            : (enVivo || finalizado)
                ? (TdsColors.primaryContainer.withValues(alpha: 0.2), TdsColors.primaryContainer)
                : (TdsColors.surfaceContainerHighest, TdsColors.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(6)),
      child: Text(
        texto,
        style: TdsText.label(11, color: color).copyWith(
          decoration: fallado ? TextDecoration.lineThrough : null,
          decorationColor: color,
        ),
      ),
    );
  }
}

/// Fila superior: estado de la quiniela, código y fecha de creación.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.quiniela, this.compacta = false});

  final ResumenQuiniela quiniela;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final q = quiniela;
    final proximo = q.proximoPartido;

    final (texto, color, fondo, punto) = switch (q.estado) {
      EstadoQuiniela.enCurso => (
          q.enVivo > 0 ? 'EN CURSO • EN VIVO' : 'EN CURSO',
          TdsColors.primaryContainer,
          TdsColors.surfaceContainerHighest,
          q.enVivo > 0,
        ),
      EstadoQuiniela.porIniciar => (
          'POR INICIAR${proximo == null ? '' : ' • ${Formatos.cuentaRegresiva(proximo.fecha) ?? Formatos.diaHora(proximo.fecha)}'}',
          TdsColors.secondaryContainer,
          TdsColors.secondaryContainer.withValues(alpha: 0.15),
          false,
        ),
      EstadoQuiniela.finalizada => (
          q.torneoActivo ? 'FINALIZADA' : 'FINALIZADA • TORNEO CERRADO',
          TdsColors.onSurfaceVariant,
          TdsColors.surfaceContainerHighest,
          false,
        ),
      EstadoQuiniela.anulada => ('ANULADA • PARTIDO SUSPENDIDO', TdsColors.advertencia, TdsColors.superficieAlta, false),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        EtiquetaTipoQuiniela(tipo: q.tipo),
        TdsPill(
          color: fondo,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (punto) ...[TdsDot(color: color, pulse: true), const SizedBox(width: 4)],
              Text(texto, style: TdsText.label(11, color: color, letterSpacing: 0.5)),
            ],
          ),
        ),
        if (!compacta) ...[
          Text('#${q.codigoAcceso}', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
          if (q.creadoEn != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 14, color: TdsColors.onSurfaceVariant),
                const SizedBox(width: 2),
                Text('Creada ${Formatos.diaMes(q.creadoEn)}', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
              ],
            ),
        ],
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.titulo,
    required this.valor,
    required this.sufijo,
    this.color = TdsColors.primaryContainer,
    this.resaltada = false,
  });

  final String titulo;
  final String valor;
  final String sufijo;
  final Color color;
  final bool resaltada;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: resaltada
            ? BoxDecoration(
                color: TdsColors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          children: [
            Text(titulo,
                textAlign: TextAlign.center,
                style: TdsText.label(10, color: TdsColors.onSurfaceVariant, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(valor, style: TdsText.stats(24, color: color)),
                  const SizedBox(width: 3),
                  Text(sufijo, style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor, this.color = TdsColors.onSurface});

  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(valor, style: TdsText.label(12, color: color)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.texto,
    this.icono,
    this.color = TdsColors.onSurfaceVariant,
    this.fondo = TdsColors.surfaceContainerHighest,
  });

  final String texto;
  final IconData? icono;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 14, color: color), const SizedBox(width: 4)],
          Text(texto, style: TdsText.label(10, color: color)),
        ],
      ),
    );
  }
}

/// Copia el código de una quiniela al portapapeles y avisa.
void copiarCodigo(BuildContext context, String codigo) {
  Clipboard.setData(ClipboardData(text: codigo));
  Notificacion.exito(context, 'Compártelo para invitar a tus amigos.', titulo: 'Código $codigo copiado');
}

/// Etiqueta "TORNEO" / "PARTIDO" de una quiniela.
class EtiquetaTipoQuiniela extends StatelessWidget {
  const EtiquetaTipoQuiniela({super.key, required this.tipo});

  final TipoQuiniela tipo;

  @override
  Widget build(BuildContext context) {
    return TdsPill(
      color: TdsColors.superficieAlta,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tipo == TipoQuiniela.partido ? Icons.sports_soccer : Icons.emoji_events_outlined,
              size: 12, color: TdsColors.textoSecundario),
          const SizedBox(width: 4),
          Text(tipo.etiqueta.toUpperCase(), style: TdsText.label(10, color: TdsColors.textoSecundario)),
        ],
      ),
    );
  }
}
