import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../domain/partido.dart';

/// Jornada y estadio del partido ("Jornada: 16   Estadio: Mario Camposeco" o
/// "Cuartos de Final (Ida)   Estadio: Mario Camposeco").
/// No ocupa espacio si el partido no tiene ninguno de los dos.
class DetallesPartido extends StatelessWidget {
  const DetallesPartido({super.key, required this.partido, this.alineacion = WrapAlignment.start});

  final Partido partido;
  final WrapAlignment alineacion;

  @override
  Widget build(BuildContext context) {
    final tieneJornada = partido.jornada != null && partido.jornada!.trim().isNotEmpty;
    final tieneEstadio = partido.estadio != null && partido.estadio!.trim().isNotEmpty;
    if (!tieneJornada && !tieneEstadio) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: alineacion,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (tieneJornada)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TdsColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              partido.nombreJornada,
              style: TdsText.label(11, color: TdsColors.textoSecundario),
            ),
          ),
        if (tieneEstadio)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TdsColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: TdsColors.borde.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 12, color: TdsColors.primaryContainer),
                const SizedBox(width: 4),
                Text(
                  'Estadio: ${partido.estadio!}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TdsText.label(11, color: TdsColors.onSurface),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
