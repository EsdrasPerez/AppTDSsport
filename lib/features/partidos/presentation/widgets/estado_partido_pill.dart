import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_pill.dart';
import '../../domain/partido.dart';

/// Etiqueta única del estado de un partido (antes se repetía en 3 widgets).
/// Para FUTURO muestra la fecha si se pasa [fecha]; si no, "ABIERTO".
class EstadoPartidoPill extends StatelessWidget {
  const EstadoPartidoPill({super.key, required this.estado, this.fecha});

  final EstadoPartido estado;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final (texto, color, punto) = switch (estado) {
      EstadoPartido.futuro => (fecha == null ? 'ABIERTO' : Formatos.diaHora(fecha), TdsColors.primaryContainer, false),
      EstadoPartido.enVivo => ('EN VIVO', TdsColors.primaryContainer, true),
      EstadoPartido.finalizado => ('FINALIZADO', TdsColors.onSurfaceVariant, false),
      EstadoPartido.suspendido => ('SUSPENDIDO', TdsColors.onSurfaceVariant, false),
    };

    return TdsPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (punto) ...[TdsDot(color: color, pulse: true), const SizedBox(width: 4)],
          // Flexible: con la hora en AM/PM ("Mañana 9:00 PM") no debe desbordar en filas angostas
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
