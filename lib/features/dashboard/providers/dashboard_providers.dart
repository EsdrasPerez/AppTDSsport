import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../partidos/domain/partido.dart';
import '../../partidos/providers/partidos_providers.dart';
import '../../quinielas/domain/quiniela_models.dart';
import '../../quinielas/providers/quinielas_providers.dart';
import '../../suscripcion/providers/suscripcion_providers.dart';
import '../domain/evento_actividad.dart';

/// Conteo de torneos con estado_activo = true.
final torneosActivosCountProvider = FutureProvider<int>((ref) {
  ref.watch(usuarioIdProvider);
  return ref.watch(partidosRepositoryProvider).contarTorneosActivos();
});

/// Números de las tarjetas que salen de misQuinielasProvider (sin consultas nuevas).
class ResumenDashboard {
  const ResumenDashboard({
    required this.enVivo,
    required this.porPronosticar,
    required this.activas,
    required this.porTorneo,
    required this.porPartido,
  });

  final int enVivo;
  final int porPronosticar;
  final int activas;
  final int porTorneo;
  final int porPartido;

  factory ResumenDashboard.desde(List<ResumenQuiniela> todas, DateTime ahora) {
    final activas = todas.where((q) => q.activa).toList();

    // Partidos en juego de mis quinielas (sin repetir si dos quinielas comparten partido)
    final enVivo = {
      for (final q in todas)
        for (final p in q.partidos)
          if (p.estado == EstadoPartido.enVivo) p.id,
    }.length;

    return ResumenDashboard(
      enVivo: enVivo,
      porPronosticar: activas.fold(0, (s, q) => s + q.pendientesDePronosticar(ahora)),
      activas: activas.length,
      porTorneo: activas.where((q) => q.tipo == TipoQuiniela.torneo).length,
      porPartido: activas.where((q) => q.tipo == TipoQuiniela.partido).length,
    );
  }
}

final resumenDashboardProvider = Provider<AsyncValue<ResumenDashboard>>((ref) {
  return ref.watch(misQuinielasProvider).whenData((l) => ResumenDashboard.desde(l, DateTime.now()));
});

/// Últimos 5 eventos del usuario: pronósticos, resultados, uniones, quinielas terminadas y pagos.
final actividadRecienteProvider = FutureProvider<List<EventoActividad>>((ref) async {
  final id = ref.watch(usuarioIdProvider);
  if (id == null) return [];

  final (recientes, quinielas, pagos) = await (
    ref.watch(quinielasRepositoryProvider).obtenerPronosticosRecientes(id),
    ref.watch(misQuinielasProvider.future),
    ref.watch(misPagosProvider.future),
  ).wait;

  final eventos = <EventoActividad>[
    for (final r in recientes)
      if (r.partido.estado == EstadoPartido.finalizado && r.partido.fecha != null)
        // Terminó un partido que pronostiqué: puntos leídos de la base, fecha del partido
        EventoActividad(
          titulo: '${r.partido.local.nombre} vs ${r.partido.visitante.nombre}',
          tipo: TipoEvento.resultado,
          estado: r.pronostico.puntos > 0 ? '+${r.pronostico.puntos} pts' : '0 pts',
          positivo: r.pronostico.puntos > 0,
          fecha: r.partido.fecha!,
        )
      else if (r.pronostico.actualizadoEn != null)
        EventoActividad(
          titulo: '${r.partido.local.nombre} vs ${r.partido.visitante.nombre}',
          tipo: TipoEvento.pronostico,
          estado: 'Guardado',
          fecha: r.pronostico.actualizadoEn!,
        ),
    for (final q in quinielas)
      if (q.unidoEn != null)
        EventoActividad(titulo: q.nombre, tipo: TipoEvento.quiniela, estado: 'Unido', fecha: q.unidoEn!, quinielaId: q.id),
    for (final q in quinielas)
      if (!q.activa && q.fechaUltimoPartido != null)
        EventoActividad(
          titulo: q.nombre,
          tipo: TipoEvento.quinielaFinalizada,
          estado: switch (q.resultado) {
            ResultadoQuiniela.ganada => 'Ganaste',
            ResultadoQuiniela.anulada => 'Anulada',
            _ => 'Perdiste',
          },
          positivo: q.resultado == ResultadoQuiniela.ganada,
          fecha: q.fechaUltimoPartido!,
          quinielaId: q.id,
        ),
    for (final p in pagos)
      if (p.fecha != null)
        EventoActividad(
          titulo: 'Plan ${p.plan.etiqueta}',
          tipo: TipoEvento.suscripcion,
          estado: p.estado == 'APROBADO' ? 'Aprobado' : p.estado,
          positivo: p.estado == 'APROBADO',
          fecha: p.fecha!,
        ),
  ]..sort((a, b) => b.fecha.compareTo(a.fecha));

  return eventos.take(5).toList();
});
