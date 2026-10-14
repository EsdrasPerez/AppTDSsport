import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../domain/quiniela_models.dart';

/// Fila del ranking. El usuario actual se resalta en lima; con [finalizada], trofeo para el 1.er lugar.
class PosicionTile extends StatelessWidget {
  const PosicionTile({
    super.key,
    required this.posicion,
    required this.esYo,
    required this.onTap,
    this.finalizada = false,
  });

  final Posicion posicion;
  final bool esYo;
  final bool finalizada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorLugar = switch (posicion.lugar) {
      1 => TdsColors.primaryContainer,
      2 => TdsColors.secondaryContainer,
      3 => TdsColors.tertiaryFixed,
      _ => TdsColors.onSurfaceVariant,
    };
    final ganador = finalizada && posicion.lugar == 1;

    return Material(
      color: esYo ? TdsColors.primaryContainer.withValues(alpha: 0.12) : TdsColors.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: ganador
                    ? const Icon(Icons.emoji_events, color: TdsColors.primaryContainer, semanticLabel: 'Ganador')
                    : Text('${posicion.lugar}', style: TdsText.stats(20, color: colorLugar)),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: TdsColors.surfaceContainerHighest,
                child: Text(
                  posicion.nombre.isNotEmpty ? posicion.nombre[0].toUpperCase() : '?',
                  style: TdsText.label(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        esYo ? '${posicion.nombre} (Tú)' : posicion.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: TdsText.label(14, color: esYo ? TdsColors.primaryContainer : TdsColors.onSurface),
                      ),
                    ),
                    if (posicion.esPro) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.workspace_premium, size: 16, color: TdsColors.primaryContainer, semanticLabel: 'PRO'),
                    ],
                  ],
                ),
              ),
              Text('${posicion.puntos}', style: TdsText.stats(18)),
              const SizedBox(width: 4),
              Text('pts', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: TdsColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloque "Lugar X de Y" + puntos totales, usado en encabezados.
class ResumenPosicion extends StatelessWidget {
  const ResumenPosicion({super.key, required this.lugar, required this.total, required this.puntos});

  final int? lugar;
  final int total;
  final int puntos;

  @override
  Widget build(BuildContext context) {
    Widget dato(String titulo, String valor, String sufijo) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TdsText.label(11, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: Text(valor, style: TdsText.stats(28, color: TdsColors.primaryContainer))),
                  const SizedBox(width: 4),
                  Text(sufijo, style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        );

    return Row(
      children: [
        dato('POSICIÓN', lugar == null ? '-' : 'Lugar $lugar', 'de $total'),
        dato('PUNTOS TOTALES', '$puntos', 'pts'),
      ],
    );
  }
}
