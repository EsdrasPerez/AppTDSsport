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
    final datos = [
      // "16" → "Jornada: 16"; "Cuartos de Final (Ida)" se muestra tal cual
      if (partido.jornada != null)
        int.tryParse(partido.jornada!) != null ? 'Jornada: ${partido.jornada}' : partido.jornada!,
      if (partido.estadio != null) 'Estadio: ${partido.estadio}',
    ];
    if (datos.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: alineacion,
      children: [
        for (final texto in datos)
          Text(texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TdsText.label(11, color: TdsColors.textoSecundario)),
      ],
    );
  }
}
