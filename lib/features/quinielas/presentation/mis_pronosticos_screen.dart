import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../partidos/domain/partido.dart';
import '../../partidos/presentation/widgets/detalles_partido.dart';
import '../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../domain/etiquetas_puntos.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_acciones.dart';
import '../providers/quinielas_providers.dart';
import 'widgets/pronostico_card.dart';
import 'widgets/resultado_card.dart';

/// Un partido de una de mis quinielas, con mi pronóstico (si lo hice).
class _Fila {
  const _Fila(this.quiniela, this.partido, this.pronostico);

  final ResumenQuiniela quiniela;
  final Partido partido;
  final Pronostico? pronostico;
}

/// Mis pronósticos: historial y estado de todos los pronósticos realizados por el usuario.
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
    ref.invalidate(perfilActualProvider);
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

    // Solo se agrupan los pronósticos que el usuario efectivamente YA REALIZÓ
    final pendientes = <_Fila>[];
    final enJuego = <_Fila>[];
    final finalizados = <_Fila>[];
    int porPronosticar = 0;

    for (final q in visibles) {
      for (final p in q.partidos) {
        final pr = q.pronosticos[p.id];
        if (p.estaEnJuegoEn(ahora)) {
          if (pr != null) enJuego.add(_Fila(q, p, pr));
        } else if (p.estado == EstadoPartido.finalizado) {
          if (pr != null) finalizados.add(_Fila(q, p, pr));
        } else if (q.activa && p.aceptaPronosticoEn(ahora)) {
          if (pr != null) {
            pendientes.add(_Fila(q, p, pr));
          } else {
            porPronosticar++;
          }
        }
      }
    }

    pendientes.sort((a, b) => (a.partido.fecha ?? DateTime(9999)).compareTo(b.partido.fecha ?? DateTime(9999)));
    finalizados.sort((a, b) => (b.partido.fecha ?? DateTime(0)).compareTo(a.partido.fecha ?? DateTime(0)));

    final mios = [for (final q in visibles) ...q.pronosticos.values];
    final aciertos = mios.where((p) => p.puntos > 0).length;
    final puntos = mios.fold(0, (s, p) => s + p.puntos);
    final esPro = ref.watch(perfilActualProvider).valueOrNull?.esPro ?? false;

    return DefaultTabController(
      length: 3,
      initialIndex: _indiceInicial,
      child: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverList.list(
              children: [
                _Resumen(total: mios.length, aciertos: aciertos, puntos: puntos, faltan: porPronosticar),
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
                if (porPronosticar > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: TdsColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TdsColors.borde.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: TdsColors.primaryContainer.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sports_soccer_rounded, size: 18, color: TdsColors.primaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$porPronosticar ${porPronosticar == 1 ? 'partido pendiente' : 'partidos pendientes'}',
                                style: TdsText.headline(13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Asigna tus marcadores en tus quinielas activas',
                                style: TdsText.body(11, color: TdsColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TdsPillButton(
                          icon: Icons.edit_note_rounded,
                          label: 'Pronosticar más',
                          primary: true,
                          onTap: () => context.push(Rutas.quinielas),
                        ),
                      ],
                    ),
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
                'POR JUGAR (${pendientes.length})',
                'EN JUEGO (${enJuego.length})',
                'FINALIZADOS (${finalizados.length})',
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _Lista(
                    itemCount: pendientes.length,
                    vacio: 'No tienes pronósticos por jugar',
                    subtituloVacio: porPronosticar > 0
                        ? 'Tienes $porPronosticar partidos pendientes por pronosticar en tus quinielas activas.'
                        : 'Cuando pronostiques partidos en tus quinielas aparecerán aquí.',
                    botonVacioTexto: 'Pronosticar más partidos',
                    onBotonVacio: () => context.push(Rutas.quinielas),
                    onRecargar: _recargar,
                    itemBuilder: (i) => _ConQuiniela(
                      fila: pendientes[i],
                      child: _PronosticoRealizadoCard(
                        fila: pendientes[i],
                        puedeEditar: esPro,
                        onGuardar: (p, l, v) => ref.read(quinielasAccionesProvider).guardarPronostico(
                              quinielaId: pendientes[i].quiniela.id,
                              partidoId: p.id,
                              golesLocal: l,
                              golesVisitante: v,
                            ),
                      ),
                    ),
                  ),
                  _Lista(
                    itemCount: enJuego.length,
                    vacio: 'No hay partidos en juego con pronóstico',
                    subtituloVacio: 'Los partidos en directo de tus quinielas aparecerán aquí.',
                    onRecargar: _recargar,
                    itemBuilder: (i) => _ConQuiniela(fila: enJuego[i], child: _EnJuegoCard(fila: enJuego[i])),
                  ),
                  _Lista(
                    itemCount: finalizados.length,
                    vacio: 'Aún no hay resultados de tus pronósticos',
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
  const _Lista({
    required this.itemCount,
    required this.vacio,
    required this.onRecargar,
    required this.itemBuilder,
    this.subtituloVacio,
    this.botonVacioTexto,
    this.onBotonVacio,
  });

  final int itemCount;
  final String vacio;
  final String? subtituloVacio;
  final String? botonVacioTexto;
  final VoidCallback? onBotonVacio;
  final Future<void> Function() onRecargar;
  final Widget Function(int i) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRecargar,
      child: itemCount == 0
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: VacioView(
                    icono: Icons.sports_score_outlined,
                    texto: vacio,
                    subtitulo: subtituloVacio,
                    acciones: [
                      if (botonVacioTexto != null && onBotonVacio != null)
                        TdsPillButton(
                          icon: Icons.sports_soccer_rounded,
                          label: botonVacioTexto!,
                          primary: true,
                          onTap: onBotonVacio,
                        ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => itemBuilder(i),
            ),
    );
  }
}

/// Partido con el nombre de su quiniela arriba.
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

/// Tarjeta para un pronóstico YA REALIZADO que todavía no se ha jugado.
/// Muestra el partido, el marcador pronosticado, y permite editar si el usuario es PRO/VIP.
/// Si no tiene suscripción, muestra el candado y abre la ventana para suscribirse.
class _PronosticoRealizadoCard extends StatefulWidget {
  const _PronosticoRealizadoCard({
    required this.fila,
    required this.puedeEditar,
    required this.onGuardar,
  });

  final _Fila fila;
  final bool puedeEditar;
  final GuardarPronostico onGuardar;

  @override
  State<_PronosticoRealizadoCard> createState() => _PronosticoRealizadoCardState();
}

class _PronosticoRealizadoCardState extends State<_PronosticoRealizadoCard> {
  bool _editando = false;
  late final _localController = TextEditingController(text: widget.fila.pronostico?.golesLocal.toString() ?? '');
  late final _visitanteController = TextEditingController(text: widget.fila.pronostico?.golesVisitante.toString() ?? '');
  bool _guardando = false;

  @override
  void didUpdateWidget(_PronosticoRealizadoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fila.pronostico != oldWidget.fila.pronostico) {
      _localController.text = widget.fila.pronostico?.golesLocal.toString() ?? '';
      _visitanteController.text = widget.fila.pronostico?.golesVisitante.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _localController.dispose();
    _visitanteController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final l = int.tryParse(_localController.text.trim());
    final v = int.tryParse(_visitanteController.text.trim());
    if (l == null || v == null) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(widget.fila.partido, l, v);
      if (!mounted) return;
      setState(() => _editando = false);
      HapticFeedback.lightImpact();
      Notificacion.exito(context, 'Pronóstico actualizado: $l - $v.');
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo actualizar');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.fila.partido;
    final pr = widget.fila.pronostico;

    return TdsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila superior: Fecha + Badge de edición
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: TdsColors.onSurfaceVariant),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  Formatos.diaHora(p.fecha),
                  style: TdsText.label(12, color: TdsColors.onSurfaceVariant, letterSpacing: 0.5),
                ),
              ),
              if (widget.puedeEditar)
                TdsPill(
                  color: TdsColors.primaryContainer.withValues(alpha: 0.15),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 12, color: TdsColors.primaryContainer),
                      const SizedBox(width: 4),
                      Text('PRO • EDITABLE', style: TdsText.label(10, color: TdsColors.primaryContainer)),
                    ],
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => mostrarSuscribeteParaEditar(context),
                  child: TdsPill(
                    color: TdsColors.surfaceContainerHighest,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 12, color: TdsColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('FIJO (PRO PARA EDITAR)', style: TdsText.label(10, color: TdsColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DetallesPartido(partido: p),
          const SizedBox(height: 16),

          // Escudos y enfrentamiento
          Row(
            children: [
              Expanded(
                child: EquipoEscudo(
                  nombre: p.local.nombre,
                  escudoUrl: p.local.escudoUrl,
                  size: 40,
                ),
              ),
              Column(
                children: [
                  Text('VS', style: TdsText.stats(16, color: TdsColors.onSurfaceVariant)),
                  if (p.fecha != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      Formatos.cuentaRegresiva(p.fecha) ?? '',
                      style: TdsText.label(10, color: TdsColors.advertencia),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: EquipoEscudo(
                  nombre: p.visitante.nombre,
                  escudoUrl: p.visitante.escudoUrl,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Caja de Pronóstico
          if (!_editando)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: TdsColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_score_rounded, size: 20, color: TdsColors.primaryContainer),
                  const SizedBox(width: 10),
                  Text('Tu pronóstico: ', style: TdsText.label(13, color: TdsColors.onSurfaceVariant)),
                  Text(
                    pr == null ? '—' : '${pr.golesLocal}  :  ${pr.golesVisitante}',
                    style: TdsText.stats(20, color: TdsColors.texto),
                  ),
                  const Spacer(),
                  if (widget.puedeEditar)
                    TdsPillButton(
                      icon: Icons.edit_outlined,
                      label: 'Editar marcador',
                      primary: false,
                      onTap: () => setState(() => _editando = true),
                    )
                  else
                    TdsPillButton(
                      icon: Icons.lock_outline,
                      label: 'Editar (PRO)',
                      primary: false,
                      onTap: () => mostrarSuscribeteParaEditar(context),
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TdsColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TdsColors.primaryContainer.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GolesField(
                        controller: _localController,
                        enabled: !_guardando,
                        etiqueta: 'Goles ${p.local.nombre}',
                        onChanged: () {
                          if (_localController.text.isNotEmpty && _visitanteController.text.isEmpty) {
                            FocusScope.of(context).nextFocus();
                          }
                          setState(() {});
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(':', style: TdsText.stats(24, color: TdsColors.onSurfaceVariant)),
                      ),
                      GolesField(
                        controller: _visitanteController,
                        enabled: !_guardando,
                        etiqueta: 'Goles ${p.visitante.nombre}',
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _guardando ? null : () => setState(() => _editando = false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      TdsPillButton(
                        icon: Icons.check,
                        label: 'Guardar cambio',
                        primary: true,
                        cargando: _guardando,
                        onTap: (_localController.text.isNotEmpty && _visitanteController.text.isNotEmpty)
                            ? _guardar
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
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
              EstadoPartidoPill(estado: p.estado, partido: p),
            ],
          ),
          const SizedBox(height: 8),
          DetallesPartido(partido: p),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: EquipoEscudo(nombre: p.local.nombre, escudoUrl: p.local.escudoUrl, size: 40)),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TdsDot(color: TdsColors.primaryContainer, pulse: true),
                      const SizedBox(width: 4),
                      Text('EN VIVO', style: TdsText.label(10, color: TdsColors.primaryContainer, letterSpacing: 1)),
                    ],
                  ),
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
                  Text('Sin pronóstico', style: TdsText.label(11, color: TdsColors.textoSecundario))
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
