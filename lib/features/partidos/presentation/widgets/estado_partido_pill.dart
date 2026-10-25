import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_pill.dart';
import '../../domain/partido.dart';

/// Etiqueta única del estado de un partido (antes se repetía en 3 widgets).
/// Para FUTURO muestra la fecha si se pasa [fecha]; si no, "ABIERTO".
class EstadoPartidoPill extends StatelessWidget {
  const EstadoPartidoPill({super.key, required this.estado, this.fecha, this.partido});

  final EstadoPartido estado;
  final DateTime? fecha;
  final Partido? partido;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final f = p?.fecha ?? fecha;
    final ahora = DateTime.now();

    final (String texto, Color color, bool punto) = () {
      // 1. Si tenemos el objeto Partido completo
      if (p != null) {
        if (p.estado == EstadoPartido.suspendido) {
          return ('SUSPENDIDO', TdsColors.advertencia, false);
        }
        if (p.estaEnJuegoEn(ahora)) {
          return ('EN VIVO', TdsColors.exito, true);
        }
        if (p.estadoEfectivoEn(ahora) == EstadoPartido.finalizado) {
          return ('FINALIZADO', TdsColors.textoSecundario, false);
        }
        if (p.aceptaPronosticoEn(ahora)) {
          return ('ABIERTO', TdsColors.acento, false);
        }
        return ('CERRADO', TdsColors.textoSecundario, false);
      }

      // 2. Si solo tenemos estado / fecha
      if (estado == EstadoPartido.suspendido) {
        return ('SUSPENDIDO', TdsColors.advertencia, false);
      }
      if (estado == EstadoPartido.finalizado) {
        return ('FINALIZADO', TdsColors.textoSecundario, false);
      }
      if (f != null) {
        if (ahora.isAfter(f.add(const Duration(minutes: 135)))) {
          return ('FINALIZADO', TdsColors.textoSecundario, false);
        }
        if (ahora.isAfter(f) && ahora.isBefore(f.add(const Duration(minutes: 135)))) {
          return ('EN VIVO', TdsColors.exito, true);
        }
        if (ahora.isAfter(f)) {
          return ('CERRADO', TdsColors.textoSecundario, false);
        }
        if (estado == EstadoPartido.futuro) {
          return ('ABIERTO', TdsColors.acento, false);
        }
      }
      if (estado == EstadoPartido.enVivo) {
        return ('EN VIVO', TdsColors.exito, true);
      }
      return ('ABIERTO', TdsColors.acento, false);
    }();

    return TdsPill(
      color: punto ? TdsColors.exito.withValues(alpha: 0.15) : TdsColors.superficieAlta,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (punto) ...[TdsDot(color: color, pulse: true), const SizedBox(width: 4)],
          // Flexible: con textos largos no debe desbordar en filas angostas
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TdsText.label(10, color: color, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// "2" o "–" si el partido aún no tiene goles.
String golesTexto(int? goles) => goles?.toString() ?? '–';
