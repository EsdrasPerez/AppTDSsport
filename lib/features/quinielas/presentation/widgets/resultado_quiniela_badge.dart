import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../domain/quiniela_models.dart';

/// Badge único de resultado: trofeo lima "GANASTE", gris "PERDISTE #3/8", neutro "VAS #2/8".
/// Con [terceraPersona] dice "GANÓ" / "PERDIÓ" / "VA" (pantalla de participante).
class ResultadoQuinielaBadge extends StatelessWidget {
  const ResultadoQuinielaBadge({
    super.key,
    required this.resultado,
    required this.lugar,
    required this.total,
    this.empate = false,
    this.terceraPersona = false,
  });

  final ResultadoQuiniela resultado;
  final int? lugar;
  final int total;
  final bool empate;
  final bool terceraPersona;

  @override
  Widget build(BuildContext context) {
    final posicion = lugar == null ? '' : ' #$lugar/$total';

    final (texto, icono, fondo, color) = switch (resultado) {
      ResultadoQuiniela.ganada => (
          '${terceraPersona ? 'GANÓ' : 'GANASTE'}${empate ? ' · EMPATE' : ''}',
          Icons.emoji_events,
          TdsColors.exito,
          TdsColors.texto,
        ),
      ResultadoQuiniela.perdida => (
          '${terceraPersona ? 'PERDIÓ' : 'PERDISTE'}$posicion',
          Icons.sentiment_neutral,
          TdsColors.surfaceContainerHighest,
          TdsColors.onSurfaceVariant,
        ),
      ResultadoQuiniela.enJuego => (
          '${terceraPersona ? 'VA' : 'VAS'}$posicion',
          Icons.trending_up,
          TdsColors.surfaceContainerHighest,
          TdsColors.onSurface,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(texto, style: TdsText.label(11, color: color)),
        ],
      ),
    );
  }
}

/// Texto largo del resultado para banners: "¡Ganaste la quiniela!" / "Perdiste · quedaste #3 de 8".
String textoResultado(ResultadoQuiniela r, {required int? lugar, required int total, bool empate = false}) =>
    switch (r) {
      ResultadoQuiniela.ganada => empate ? '¡Ganaste! · empate en 1.er lugar' : '¡Ganaste la quiniela!',
      ResultadoQuiniela.perdida => 'Perdiste · quedaste #${lugar ?? '-'} de $total',
      ResultadoQuiniela.enJuego => 'Vas #${lugar ?? '-'} de $total',
    };
