import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../domain/partido.dart';
import 'detalles_partido.dart';
import 'estado_partido_pill.dart';

/// Card de partido EN VIVO, FINALIZADO o SUSPENDIDO, con marcador grande.
class MarcadorCard extends StatelessWidget {
  const MarcadorCard({super.key, required this.partido});

  final Partido partido;

  @override
  Widget build(BuildContext context) {
    final enVivo = partido.estado == EstadoPartido.enVivo;
    final gl = partido.golesLocal;
    final gv = partido.golesVisitante;

    // El marcador del equipo que va ganando se resalta en lima
    Color colorGoles(bool gana) => gana ? TdsColors.primaryContainer : TdsColors.onSurface;
    final separador = Text(':',
        style: TdsText.stats(32, color: enVivo ? TdsColors.primaryContainer : TdsColors.onSurfaceVariant));

    return TdsCard(
      glow: enVivo,
      child: Column(
        children: [
          _Encabezado(
            texto: '${partido.torneo.toUpperCase()} • ${Formatos.dia(partido.fecha)}',
            trailing: EstadoPartidoPill(estado: partido.estado),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: EquipoEscudo(
                  nombre: partido.local.nombre,
                  escudoUrl: partido.local.escudoUrl,
                  size: 56,
                  tamanoNombre: 16,
                  subtitulo: 'Local',
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(golesTexto(gl), style: TdsText.stats(32, color: colorGoles((gl ?? 0) > (gv ?? 0)))),
                    const SizedBox(width: 6),
                    enVivo ? TdsPulse(child: separador) : separador,
                    const SizedBox(width: 6),
                    Text(golesTexto(gv), style: TdsText.stats(32, color: colorGoles((gv ?? 0) > (gl ?? 0)))),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: EquipoEscudo(
                  nombre: partido.visitante.nombre,
                  escudoUrl: partido.visitante.escudoUrl,
                  size: 56,
                  tamanoNombre: 16,
                  subtitulo: 'Visitante',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DetallesPartido(partido: partido, alineacion: WrapAlignment.center),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Card de partido FUTURO, con horario (crear quiniela está en el encabezado de su torneo).
class FuturoCard extends StatelessWidget {
  const FuturoCard({super.key, required this.partido, this.pie});

  final Partido partido;

  /// Debajo de los equipos (en el calendario, el botón "Realizar pronóstico").
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final cuenta = Formatos.cuentaRegresiva(partido.fecha);

    return TdsCard(
      child: Column(
        children: [
          _Encabezado(
            texto: partido.torneo.toUpperCase(),
            trailing: cuenta != null
                ? TdsPill(
                    color: TdsColors.primaryContainer.withValues(alpha: 0.2),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: TdsColors.primaryContainer),
                        const SizedBox(width: 4),
                        Text(cuenta, style: TdsText.label(11, color: TdsColors.primaryContainer)),
                      ],
                    ),
                  )
                : Text(Formatos.diaHora(partido.fecha), style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: EquipoEscudo(
                  nombre: partido.local.nombre,
                  escudoUrl: partido.local.escudoUrl,
                  size: 40,
                  tamanoNombre: 15,
                  disposicion: DisposicionEscudo.horizontal,
                  subtitulo: 'Local',
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(Formatos.hora(partido.fecha), style: TdsText.stats(15)),
                    const SizedBox(height: 4),
                    Text(Formatos.dia(partido.fecha).toUpperCase(),
                        style: TdsText.body(10, color: TdsColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: EquipoEscudo(
                  nombre: partido.visitante.nombre,
                  escudoUrl: partido.visitante.escudoUrl,
                  size: 40,
                  tamanoNombre: 15,
                  disposicion: DisposicionEscudo.horizontalInvertida,
                  subtitulo: 'Visitante',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DetallesPartido(partido: partido, alineacion: WrapAlignment.center),
          if (pie != null) ...[const SizedBox(height: 16), pie!],
        ],
      ),
    );
  }
}

/// Fila superior de las cards: texto a la izquierda y un widget a la derecha.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.texto, required this.trailing});

  final String texto;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TdsText.label(12, color: TdsColors.onSurfaceVariant, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}
