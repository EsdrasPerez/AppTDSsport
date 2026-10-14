import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../domain/etiquetas_puntos.dart';
import '../../domain/quiniela_models.dart';

/// Tab Finalizados: marcador real oficial frente al pronóstico, con badge de puntos
/// (los puntos vienen de pronosticos.puntos_obtenidos; aquí no se calcula nada).
class ResultadoCard extends StatelessWidget {
  const ResultadoCard({super.key, required this.partido, this.pronostico});

  final Partido partido;
  final Pronostico? pronostico;

  @override
  Widget build(BuildContext context) {
    final p = pronostico;
    final puntos = p?.puntos ?? 0;
    final acerto = puntos > 0;

    return TdsCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatos.diaHora(partido.fecha),
                  style: TdsText.label(12, color: TdsColors.onSurfaceVariant, letterSpacing: 0.5),
                ),
              ),
              TdsPill(
                color: acerto ? TdsColors.exito : TdsColors.surfaceContainerHighest,
                child: Text(
                  p == null ? 'SIN PRONÓSTICO' : '+$puntos PTS',
                  style: TdsText.label(11, color: acerto ? TdsColors.texto : TdsColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EquipoEscudo(nombre: partido.local.nombre, escudoUrl: partido.local.escudoUrl, size: 40),
              ),
              Column(
                children: [
                  Text('REAL', style: TdsText.label(10, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${golesTexto(partido.golesLocal)} : ${golesTexto(partido.golesVisitante)}',
                      style: TdsText.stats(30)),
                ],
              ),
              Expanded(
                child: EquipoEscudo(
                    nombre: partido.visitante.nombre, escudoUrl: partido.visitante.escudoUrl, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: TdsColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  acerto ? Icons.verified : Icons.edit_note,
                  size: 18,
                  color: acerto ? TdsColors.exito : TdsColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text('Pronóstico: ', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
                Text(
                  p == null ? '—' : '${p.golesLocal} : ${p.golesVisitante}',
                  style: TdsText.stats(14, color: acerto ? TdsColors.exito : TdsColors.onSurface),
                ),
                const Spacer(),
                if (p != null)
                  Flexible(
                    child: Text(detallePuntos(p.puntos),
                        overflow: TextOverflow.ellipsis, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
