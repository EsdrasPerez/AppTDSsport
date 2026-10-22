import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../partidos/domain/partido.dart';
import '../../partidos/providers/partidos_providers.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_acciones.dart';
import '../providers/quinielas_providers.dart';
import 'widgets/posiciones_list.dart';
import 'widgets/pronostico_card.dart';
import 'widgets/pronosticos_torneo_card.dart';
import 'widgets/quiniela_resumen_cards.dart';
import 'widgets/resultado_card.dart';
import 'widgets/resultado_quiniela_badge.dart';

/// Detalle de Quiniela: Pendientes (pronósticos), Finalizados y Posiciones.
/// Con [soloLectura] (desde el historial) no hay pestaña Pendientes ni invitación.
class QuinielaDetalleScreen extends ConsumerStatefulWidget {
  const QuinielaDetalleScreen({super.key, required this.quinielaId, this.soloLectura = false, this.partidoId});

  final String quinielaId;
  final bool soloLectura;

  /// Partido elegido en Mis Quinielas: Pendientes se abre resaltándolo.
  final String? partidoId;

  @override
  ConsumerState<QuinielaDetalleScreen> createState() => _QuinielaDetalleScreenState();
}

class _QuinielaDetalleScreenState extends ConsumerState<QuinielaDetalleScreen> with WidgetsBindingObserver {
  /// No hay Realtime en `partidos`: se consulta SOLO esa tabla, y solo con la pantalla visible.
  // TODO(decision): si se habilita Realtime en partidos (migración opcional), escuchar el canal en lugar de sondear.
  static const _intervaloSondeo = Duration(seconds: 60);

  Timer? _sondeo;
  Timer? _siguienteInicio;
  bool _appActiva = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sondeo = Timer.periodic(_intervaloSondeo, (_) => _sondear());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sondeo?.cancel();
    _siguienteInicio?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActiva = state == AppLifecycleState.resumed;
  }

  String? get _torneoId => ref.read(quinielaDetalleProvider(widget.quinielaId)).valueOrNull?.quiniela.torneoId;

  void _sondear() {
    final visible = ModalRoute.of(context)?.isCurrent ?? false;
    final torneoId = _torneoId;
    if (!_appActiva || !visible || torneoId == null) return;
    ref.invalidate(partidosProvider(torneoId));
  }

  Future<void> _recargar() => ref.refresh(quinielaDetalleProvider(widget.quinielaId).future);

  /// Reconstruye la pantalla justo cuando empieza el siguiente partido, para bloquear su tarjeta
  /// aunque el administrador todavía no haya cambiado el estado.
  void _programarSiguienteInicio(List<Partido> partidos) {
    _siguienteInicio?.cancel();
    final ahora = DateTime.now();
    final proximos = partidos
        .where((p) => p.aceptaPronosticoEn(ahora))
        .map((p) => p.fecha)
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (proximos.isEmpty) return;
    _siguienteInicio = Timer(proximos.first.difference(ahora) + const Duration(seconds: 1), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _guardarPronostico(Partido partido, int local, int visitante) {
    return ref.read(quinielasAccionesProvider).guardarPronostico(
          quinielaId: widget.quinielaId,
          partidoId: partido.id,
          golesLocal: local,
          golesVisitante: visitante,
        );
  }

  Future<void> _unirme(String codigo) async {
    try {
      await ref.read(quinielasAccionesProvider).unirse(codigo);
      if (mounted) Notificacion.exito(context, 'Ya puedes hacer tus pronósticos.', titulo: '¡Te uniste!');
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo unir');
    }
  }

  void _compartirInvitacion(QuinielaDetalle q) {
    // En web la app usa rutas con "#": el enlace abre la hoja "Unirse" ya llenada.
    final enlace = kIsWeb ? '\n${Uri.base.origin}/#${Rutas.unirseConCodigo(q.codigoAcceso)}' : '';
    Clipboard.setData(ClipboardData(
      text: 'Únete a mi quiniela "${q.nombre}" (${q.torneoNombre}) en TDS Sport.\n'
          'Código: ${q.codigoAcceso}$enlace',
    ));
    Notificacion.exito(context, 'Pega el mensaje en tu chat para invitar a tus amigos.', titulo: 'Invitación copiada');
  }

  @override
  Widget build(BuildContext context) {
    final detalle = ref.watch(quinielaDetalleProvider(widget.quinielaId));
    final d = detalle.valueOrNull;

    // Partidos frescos del sondeo; si cambiaron (estado o marcador), se recarga el detalle completo
    // porque también pudieron cambiar los puntos y las posiciones.
    if (d != null) {
      ref.listen(partidosProvider(d.quiniela.torneoId), (anterior, siguiente) {
        final antes = anterior?.valueOrNull;
        final ahora = siguiente.valueOrNull;
        if (antes != null && ahora != null && !listEquals(antes, ahora)) {
          ref.invalidate(quinielaDetalleProvider(widget.quinielaId));
        }
      });
    }

    final puedeInvitar = d != null && d.soyMiembro && !d.finalizada && !widget.soloLectura;

    return Scaffold(
      appBar: TdsAppBar(
        titulo: 'QUINIELA',
        onRefrescar: _recargar,
        acciones: [
          if (puedeInvitar)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Compartir invitación',
              onPressed: () => _compartirInvitacion(d.quiniela),
            ),
        ],
      ),
      body: AsyncValueView(
        value: detalle,
        onReintentar: _recargar,
        data: (d) {
          _programarSiguienteInicio(d.partidos);
          if (!d.soyMiembro) return _NoMiembro(quiniela: d.quiniela, onUnirme: () => _unirme(d.quiniela.codigoAcceso));
          return _Contenido(
            detalle: d,
            soloLectura: widget.soloLectura,
            partidoId: widget.partidoId,
            // Cambiar un marcador ya guardado es beneficio PRO/VIP
            puedeEditar: ref.watch(perfilActualProvider).valueOrNull?.esPro ?? false,
            onGuardar: _guardarPronostico,
            onRecargar: _recargar,
          );
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.detalle,
    required this.soloLectura,
    required this.onGuardar,
    required this.onRecargar,
    required this.puedeEditar,
    this.partidoId,
  });

  final DetalleQuiniela detalle;
  final bool soloLectura;
  final bool puedeEditar;
  final String? partidoId;
  final GuardarPronostico onGuardar;
  final Future<void> Function() onRecargar;

  @override
  Widget build(BuildContext context) {
    final d = detalle;
    final conPendientes = !soloLectura;

    return DefaultTabController(
      length: conPendientes ? 3 : 2,
      child: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            sliver: SliverToBoxAdapter(child: _Encabezado(detalle: d)),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Deslizable como en Mis pronósticos: con las cantidades no caben fijas en pantallas angostas
              child: TdsTabBar(desplazable: true, tabs: [
                if (conPendientes) 'PENDIENTES (${d.pendientes.length})',
                'FINALIZADOS (${d.finalizados.length})',
                'POSICIONES',
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  if (conPendientes)
                    // Una sola tarjeta con todos los partidos pendientes del torneo, con buscador y
                    // filtro por marcador (todos / sin mi marcador / con mi marcador)
                    _Lista(
                      onRecargar: onRecargar,
                      vacio: 'No hay partidos pendientes',
                      itemCount: d.pendientes.isEmpty ? 0 : 1,
                      itemBuilder: (_, _) => PronosticosTorneoCard(
                        titulo: d.quiniela.torneoNombre,
                        partidos: d.pendientes,
                        pronosticos: d.misPronosticos,
                        onGuardar: onGuardar,
                        partidoElegido: partidoId,
                        puedeEditar: puedeEditar,
                        buscador: true,
                        filtroMarcador: true,
                      ),
                    ),
                  _Lista(
                    onRecargar: onRecargar,
                    vacio: 'Aún no hay partidos finalizados',
                    itemCount: d.finalizados.length,
                    itemBuilder: (_, i) =>
                        ResultadoCard(partido: d.finalizados[i], pronostico: d.misPronosticos[d.finalizados[i].id]),
                  ),
                  _Lista(
                    onRecargar: onRecargar,
                    vacio: 'Todavía no hay participantes',
                    separacion: 8,
                    itemCount: d.posiciones.length,
                    itemBuilder: (context, i) {
                      final pos = d.posiciones[i];
                      return PosicionTile(
                        posicion: pos,
                        esYo: pos.usuarioId == d.miId,
                        finalizada: d.estado == EstadoQuiniela.finalizada,
                        onTap: () => context.push(Rutas.participante(d.quiniela.id, pos.usuarioId)),
                      );
                    },
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

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.detalle});

  final DetalleQuiniela detalle;

  @override
  Widget build(BuildContext context) {
    final q = detalle.quiniela;
    final yo = detalle.miPosicion;
    final resultado = detalle.miResultado;
    final empate = resultado == ResultadoQuiniela.ganada && detalle.posiciones.where((p) => p.lugar == 1).length > 1;

    return Column(
      children: [
        if (detalle.finalizada) ...[
          _BannerResultado(
            resultado: resultado,
            texto: textoResultado(resultado, lugar: yo?.lugar, total: detalle.posiciones.length, empate: empate),
            puntos: yo?.puntos ?? 0,
          ),
          const SizedBox(height: 12),
        ],
        TdsCard(
          glow: !detalle.finalizada,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 16, color: TdsColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.torneoNombre.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TdsText.label(12, color: TdsColors.onSurfaceVariant, letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text(q.nombre, style: TdsText.headline(24))),
                  Tooltip(
                    message: 'Copiar código',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => copiarCodigo(context, q.codigoAcceso),
                      child: TdsPill(
                        child: Row(
                          children: [
                            Text(q.codigoAcceso, style: TdsText.stats(12, color: TdsColors.primaryContainer)),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12, color: TdsColors.primaryContainer),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResumenPosicion(lugar: yo?.lugar, total: detalle.posiciones.length, puntos: yo?.puntos ?? 0),
              const SizedBox(height: 16),
              ParticipantesQuiniela(
                posiciones: detalle.posiciones,
                creadorId: q.creadorId,
                limiteUsuarios: q.limiteUsuarios,
                miId: detalle.miId,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerResultado extends StatelessWidget {
  const _BannerResultado({required this.resultado, required this.texto, required this.puntos});

  final ResultadoQuiniela resultado;
  final String texto;
  final int puntos;

  @override
  Widget build(BuildContext context) {
    final gano = resultado == ResultadoQuiniela.ganada;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gano ? TdsColors.exito : TdsColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(gano ? Icons.emoji_events : Icons.flag_outlined,
              size: 32, color: gano ? TdsColors.texto : TdsColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUINIELA FINALIZADA',
                    style: TdsText.label(11,
                        color: gano ? TdsColors.onPrimaryContainer : TdsColors.onSurfaceVariant, letterSpacing: 1)),
                Text(texto, style: TdsText.headline(18, color: gano ? TdsColors.texto : TdsColors.onSurface)),
              ],
            ),
          ),
          Text('$puntos pts', style: TdsText.stats(20, color: gano ? TdsColors.texto : TdsColors.primaryContainer)),
        ],
      ),
    );
  }
}

class _NoMiembro extends StatelessWidget {
  const _NoMiembro({required this.quiniela, required this.onUnirme});

  final QuinielaDetalle quiniela;
  final VoidCallback onUnirme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: TdsCard(
          child: VacioView(
            icono: Icons.lock_outline,
            texto: 'No perteneces a esta quiniela',
            subtitulo: '"${quiniela.nombre}" · ${quiniela.torneoNombre}',
            compacto: true,
            acciones: [
              if (quiniela.torneoActivo)
                TdsPillButton(icon: Icons.group_add_outlined, label: 'Unirme', primary: true, onTap: onUnirme),
            ],
          ),
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.onRecargar,
    required this.vacio,
    required this.itemCount,
    required this.itemBuilder,
    this.separacion = 16,
  });

  final Future<void> Function() onRecargar;
  final String vacio;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separacion;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRecargar,
      child: itemCount == 0
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [VacioView(icono: Icons.sports_soccer_outlined, texto: vacio)],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(height: separacion),
              itemBuilder: itemBuilder,
            ),
    );
  }
}
