import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../partidos/domain/partido.dart';
import '../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../domain/etiquetas_puntos.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_acciones.dart';
import '../providers/quinielas_providers.dart';
import 'widgets/pronosticos_torneo_card.dart';
import 'widgets/resultado_card.dart';


/// Un partido de una de mis quinielas, con mi pronóstico (si lo hice).
class _Fila {
  const _Fila(this.quiniela, this.partido, this.pronostico);

  final ResumenQuiniela quiniela;
  final Partido partido;
  final Pronostico? pronostico;
}

/// Mis pronósticos: todos los que hice en todas mis quinielas (sale de misQuinielasProvider).
class MisPronosticosScreen extends ConsumerStatefulWidget {
  const MisPronosticosScreen({super.key, this.filtroInicial});

  /// ?filtro=pendientes|enjuego|finalizados
  final String? filtroInicial;

  @override
  ConsumerState<MisPronosticosScreen> createState() => _MisPronosticosScreenState();
}

class _MisPronosticosScreenState extends ConsumerState<MisPronosticosScreen> {
  String? _quinielaId; // null = todas

  Future<void> _recargar() async {
    ref.invalidate(misQuinielasProvider);
    await ref.read(misQuinielasProvider.future);
  }

  int get _indiceInicial => switch (widget.filtroInicial) {
        'enjuego' => 1,
        'finalizados' => 2,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final quinielas = ref.watch(misQuinielasProvider);

    return Scaffold(
      appBar: TdsAppBar(titulo: 'MIS PRONÓSTICOS', onRefrescar: _recargar),
      body: AsyncValueView(
        value: quinielas,
        onReintentar: _recargar,
        data: _buildContenido,
      ),
    );
  }

  Widget _buildContenido(List<ResumenQuiniela> todas) {
    final ahora = DateTime.now();
    final visibles = _quinielaId == null ? todas : todas.where((q) => q.id == _quinielaId).toList();

    final pendientes = <_Fila>[];
    final enJuego = <_Fila>[];
    final finalizados = <_Fila>[];
    for (final q in visibles) {
      for (final p in q.partidos) {
        final pr = q.pronosticos[p.id];
        if (q.activa && p.aceptaPronosticoEn(ahora)) {
          pendientes.add(_Fila(q, p, pr));
        } else if (p.estado == EstadoPartido.enVivo) {
          enJuego.add(_Fila(q, p, pr));
        } else if (p.estado == EstadoPartido.finalizado && pr != null) {
          finalizados.add(_Fila(q, p, pr));
        }
      }
    }
    // Pendientes: un card desplegable por quiniela activa con sus partidos abiertos
    final grupos = [
      for (final q in visibles)
        if (pendientes.any((f) => f.quiniela == q)) (q, [for (final f in pendientes) if (f.quiniela == q) f.partido]),
    ];
    finalizados.sort((a, b) => (b.partido.fecha ?? DateTime(0)).compareTo(a.partido.fecha ?? DateTime(0)));

    // Resumen: puntos leídos de pronosticos.puntos_obtenidos (solo se suman para mostrar el total)
    final mios = [for (final q in visibles) ...q.pronosticos.values];
    final aciertos = mios.where((p) => p.puntos > 0).length;
    final puntos = mios.fold(0, (s, p) => s + p.puntos);
    final faltan = pendientes.where((f) => f.pronostico == null).length;

    return DefaultTabController(
      length: 3,
      initialIndex: _indiceInicial,
      child: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverList.list(
              children: [
                _Resumen(total: mios.length, aciertos: aciertos, puntos: puntos, faltan: faltan),
                if (todas.length > 1) ...[
                  const SizedBox(height: 16),
                  TdsFilterChipsRow(
                    chips: [
                      TdsFilterChip(
                          texto: 'Todas', activo: _quinielaId == null, onTap: () => setState(() => _quinielaId = null)),
                      for (final q in todas)
                        TdsFilterChip(
                          texto: q.nombre,
                          activo: _quinielaId == q.id,
                          onTap: () => setState(() => _quinielaId = q.id),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TdsTabBar(desplazable: true, tabs: [
                'PENDIENTES (${pendientes.length})',
                'EN JUEGO (${enJuego.length})',
                'FINALIZADOS (${finalizados.length})',
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _Lista(
                    itemCount: grupos.length,
                    vacio: 'No tienes partidos por pronosticar',
                    onRecargar: _recargar,
                    itemBuilder: (i) {
                      final (q, partidos) = grupos[i];
                      return PronosticosTorneoCard(
                        key: ValueKey(q.id),
                        titulo: q.nombre,
                        subtitulo: q.torneoNombre,
                        partidos: partidos,
                        pronosticos: q.pronosticos,
                        // 2 partidos de entrada; el resto con "Ver más"
                        limite: 2,
                        buscador: true,
                        guardarPorPartido: true,
                        onGuardar: (p, l, v) => ref.read(quinielasAccionesProvider).guardarPronostico(
                            quinielaId: q.id, partidoId: p.id, golesLocal: l, golesVisitante: v),
                      );
                    },
                  ),
                  _Lista(
                    itemCount: enJuego.length,
                    vacio: 'No hay partidos en juego',
                    onRecargar: _recargar,
                    itemBuilder: (i) => _ConQuiniela(fila: enJuego[i], child: _EnJuegoCard(fila: enJuego[i])),
                  ),
                  _Lista(
                    itemCount: finalizados.length,
                    vacio: 'Aún no hay resultados',
                    onRecargar: _recargar,
                    itemBuilder: (i) => _ConQuiniela(
                      fila: finalizados[i],
                      child: ResultadoCard(partido: finalizados[i].partido, pronostico: finalizados[i].pronostico),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.total, required this.aciertos, required this.puntos, required this.faltan});

  final int total;
  final int aciertos;
  final int puntos;
  final int faltan;

  @override
  Widget build(BuildContext context) {
    Widget dato(String valor, String texto, Color color) => Expanded(
          child: Column(
            children: [
              Text(valor, style: TdsText.stats(24, color: color)),
              const SizedBox(height: 4),
              Text(texto, textAlign: TextAlign.center, style: TdsText.body(11, color: TdsColors.textoSecundario)),
            ],
          ),
        );

    return TdsCard(
      child: Row(
        children: [
          dato('$total', 'Pronósticos', TdsColors.texto),
          dato('$aciertos', 'Aciertos', TdsColors.exito),
          dato('$puntos', 'Puntos', TdsColors.acento),
          dato('$faltan', 'Por hacer', faltan > 0 ? TdsColors.advertencia : TdsColors.textoSecundario),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.itemCount, required this.vacio, required this.onRecargar, required this.itemBuilder});

  final int itemCount;
  final String vacio;
  final Future<void> Function() onRecargar;
  final Widget Function(int i) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRecargar,
      child: itemCount == 0
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [VacioView(icono: Icons.edit_note, texto: vacio)],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (_, i) => itemBuilder(i),
            ),
    );
  }
}

/// Partido con el nombre de su quiniela arriba (En juego y Finalizados).
class _ConQuiniela extends StatelessWidget {
  const _ConQuiniela({required this.fila, required this.child});

  final _Fila fila;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EncabezadoQuiniela(quiniela: fila.quiniela),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// "Quiniela de la Oficina · TORNEO  Ver quiniela ›"
class _EncabezadoQuiniela extends StatelessWidget {
  const _EncabezadoQuiniela({required this.quiniela});

  final ResumenQuiniela quiniela;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(Rutas.quiniela(quiniela.id, soloLectura: !quiniela.activa)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 16, color: TdsColors.textoSecundario),
            const SizedBox(width: 8),
            Expanded(child: Text(quiniela.nombre, overflow: TextOverflow.ellipsis, style: TdsText.label(13))),
            Text('Ver quiniela', style: TdsText.label(12, color: TdsColors.acento)),
            const Icon(Icons.chevron_right, size: 18, color: TdsColors.acento),
          ],
        ),
      ),
    );
  }
}

/// Partido EN JUEGO: mi pronóstico frente al marcador actual (sin editar).
class _EnJuegoCard extends StatelessWidget {
  const _EnJuegoCard({required this.fila});

  final _Fila fila;

  @override
  Widget build(BuildContext context) {
    final p = fila.partido;
    final pr = fila.pronostico;
    final acertando = pr != null &&
        p.tieneMarcador &&
        signo(pr.golesLocal, pr.golesVisitante) == signo(p.golesLocal!, p.golesVisitante!);

    return TdsCard(
      glow: true,
      onTap: () => context.push(Rutas.quiniela(fila.quiniela.id)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(Formatos.diaHora(p.fecha),
                    style: TdsText.label(12, color: TdsColors.textoSecundario, letterSpacing: 0.5)),
              ),
              EstadoPartidoPill(estado: p.estado),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: EquipoEscudo(nombre: p.local.nombre, escudoUrl: p.local.escudoUrl, size: 40)),
              Column(
                children: [
                  Text('EN VIVO', style: TdsText.label(10, color: TdsColors.error, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${golesTexto(p.golesLocal)} : ${golesTexto(p.golesVisitante)}', style: TdsText.stats(30)),
                ],
              ),
              Expanded(child: EquipoEscudo(nombre: p.visitante.nombre, escudoUrl: p.visitante.escudoUrl, size: 40)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: TdsColors.superficieAlta, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Text('Mi pronóstico: ', style: TdsText.label(12, color: TdsColors.textoSecundario)),
                Text(pr == null ? '—' : '${pr.golesLocal} : ${pr.golesVisitante}', style: TdsText.stats(14)),
                const Spacer(),
                if (pr == null)
                  Text('No pronosticaste', style: TdsText.label(11, color: TdsColors.textoSecundario))
                else
                  Text(acertando ? 'Va acertando' : 'En riesgo',
                      style: TdsText.label(11, color: acertando ? TdsColors.exito : TdsColors.advertencia)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
