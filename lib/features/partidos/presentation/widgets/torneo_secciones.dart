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
bool torneoAceptaQuiniela(List<Partido> partidos) => partidos.any((p) => p.permiteCrearQuiniela && p.aceptaPronostico);

/// Encabezado de un torneo (nombre, cantidad de partidos y "Crear quiniela") con sus partidos.
class SeccionTorneo extends StatelessWidget {
  const SeccionTorneo({super.key, required this.partidos, this.separacion = 16, this.conPronostico = false});

  /// Partidos del torneo (no vacío).
  final List<Partido> partidos;
  final double separacion;

  /// Botón "Realizar pronóstico" en los partidos que todavía lo aceptan (calendario).
  final bool conPronostico;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoTorneo(partidos: partidos, cantidad: partidos.length),
        for (final p in partidos) ...[
          SizedBox(height: separacion),
          p.estado == EstadoPartido.futuro
              ? FuturoCard(
                  partido: p,
                  pie: conPronostico && p.aceptaPronostico ? BotonPronosticar(partido: p) : null,
                )
              : MarcadorCard(partido: p),
        ],
      ],
    );
  }
}

/// "Realizar pronóstico": abre la quiniela del torneo en ese partido, listo para poner los goles.
/// Con varias quinielas del torneo pregunta en cuál; sin ninguna lleva a crear una de ese torneo.
/// Solo en el calendario: si ya tengo marcador en ese partido (en todas mis quinielas del torneo)
/// el botón queda bloqueado; editarlo sigue siendo posible desde la propia quiniela.
class BotonPronosticar extends ConsumerWidget {
  const BotonPronosticar({super.key, required this.partido});

  final Partido partido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = partido;
    final quinielas = (ref.watch(quinielasActivasProvider).valueOrNull ?? [])
        .where((q) => q.torneoId == p.torneoId)
        .toList();
    final sinMarcador = quinielas.where((q) => !q.pronosticos.containsKey(p.id)).toList();

    if (quinielas.isNotEmpty && sinMarcador.isEmpty) {
      final mio = quinielas.first.pronosticos[p.id]!;
      return Center(
        child: TdsPillButton(
          icon: Icons.lock_outline,
          label: quinielas.length == 1
              ? 'Ya pronosticaste: ${mio.golesLocal} - ${mio.golesVisitante}'
              : 'Ya pronosticaste en tus ${quinielas.length} quinielas',
          onTap: null,
        ),
      );
    }

    void abrir(String quinielaId) => context.push(Rutas.quiniela(quinielaId, partidoId: p.id));

    Future<void> onTap() async {
      if (quinielas.isEmpty) {
        Notificacion.info(
          context,
          'Crea una quiniela de ${p.torneo} o únete a la de un amigo.',
          titulo: 'Necesitas una quiniela para pronosticar',
        );
        context.push(Rutas.crearQuiniela(torneoId: p.torneoId));
        return;
      }
      // Solo queda una quiniela sin mi marcador: se abre directo
      if (sinMarcador.length == 1) return abrir(sinMarcador.first.id);

      final elegida = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        backgroundColor: TdsColors.surfaceContainer,
        builder: (hoja) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('¿En qué quiniela pronosticas?', style: TdsText.headline(18)),
              ),
              // Las que ya tienen mi marcador se ven bloqueadas
              for (final q in quinielas)
                ListTile(
                  enabled: !q.pronosticos.containsKey(p.id),
                  leading: Icon(
                    q.pronosticos.containsKey(p.id) ? Icons.lock_outline : Icons.emoji_events_outlined,
                    color: q.pronosticos.containsKey(p.id) ? TdsColors.textoTenue : TdsColors.acento,
                  ),
                  title: Text(q.nombre, style: TdsText.label(14)),
                  subtitle: Text(
                    q.pronosticos[p.id] == null
                        ? 'Sin tu marcador'
                        : 'Ya pronosticaste: ${q.pronosticos[p.id]!.golesLocal} - ${q.pronosticos[p.id]!.golesVisitante}',
                    style: TdsText.body(12, color: TdsColors.textoSecundario),
                  ),
                  trailing: q.pronosticos.containsKey(p.id) ? null : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(hoja, q.id),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (elegida != null && context.mounted) abrir(elegida);
    }

    return Center(
      child: TdsPillButton(icon: Icons.edit_outlined, label: 'Realizar pronóstico', primary: true, onTap: onTap),
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
              Text(
                textoCantidad ?? '$cantidad ${cantidad == 1 ? 'partido' : 'partidos'}',
                style: TdsText.label(12, color: TdsColors.textoTenue),
              ),
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
