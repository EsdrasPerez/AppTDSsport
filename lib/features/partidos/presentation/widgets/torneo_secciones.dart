import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../quinielas/providers/quinielas_providers.dart';
import '../../domain/partido.dart';
import 'partido_cards.dart';

/// Partidos agrupados por torneo (en el orden en que llegan). Un torneo sin partidos nunca aparece.
Map<String, List<Partido>> agruparPorTorneo(Iterable<Partido> partidos) {
  final grupos = <String, List<Partido>>{};
  for (final p in partidos) {
    grupos.putIfAbsent(p.torneoId, () => []).add(p);
  }
  return grupos;
}

/// Se puede crear quiniela del torneo: activo y con al menos un partido que acepta pronóstico.
bool torneoAceptaQuiniela(List<Partido> partidos) =>
    partidos.any((p) => p.permiteCrearQuiniela && p.aceptaPronostico);

/// Encabezado de un torneo (nombre, cantidad de partidos y "Crear quiniela") con sus partidos.
class SeccionTorneo extends StatelessWidget {
  const SeccionTorneo({super.key, required this.partidos, this.separacion = 16});

  /// Partidos del torneo (no vacío).
  final List<Partido> partidos;
  final double separacion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoTorneo(partidos: partidos, cantidad: partidos.length),
        for (final p in partidos) ...[
          SizedBox(height: separacion),
          p.estado == EstadoPartido.futuro ? FuturoCard(partido: p) : MarcadorCard(partido: p),
        ],
      ],
    );
  }
}

/// "● LIGA NACIONAL · 3 partidos   [Crear quiniela]". El botón solo aparece si todavía no estoy
/// en una quiniela de ese torneo.
class EncabezadoTorneo extends ConsumerWidget {
  const EncabezadoTorneo({super.key, required this.partidos, required this.cantidad, this.textoCantidad});

  /// Partidos del torneo: de aquí salen el nombre, el id y si se puede crear quiniela.
  final List<Partido> partidos;
  final int cantidad;

  /// Texto bajo el nombre; por defecto "N partidos".
  final String? textoCantidad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = partidos.first;
    // Mientras cargan mis quinielas no se ofrece el botón (evita mostrarlo y luego quitarlo)
    final misQuinielas = ref.watch(misQuinielasProvider).valueOrNull;
    final yaEstoy = misQuinielas == null || misQuinielas.any((q) => q.torneoId == p.torneoId);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: TdsColors.acento, shape: BoxShape.circle),
          child: const TdsDot(color: TdsColors.sobreAcento, size: 6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.torneo.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TdsText.headline(16, weight: FontWeight.w700).copyWith(letterSpacing: 0.8),
              ),
              Text(textoCantidad ?? '$cantidad ${cantidad == 1 ? 'partido' : 'partidos'}',
                  style: TdsText.label(12, color: TdsColors.textoTenue)),
            ],
          ),
        ),
        if (!yaEstoy && torneoAceptaQuiniela(partidos)) ...[
          const SizedBox(width: 8),
          TdsPillButton(
            icon: Icons.emoji_events_outlined,
            label: 'Crear quiniela',
            primary: true,
            onTap: () => context.push(Rutas.crearQuiniela(torneoId: p.torneoId)),
          ),
        ],
      ],
    );
  }
}
