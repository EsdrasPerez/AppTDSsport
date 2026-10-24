import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/detalles_partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../domain/quiniela_models.dart';
import 'pronostico_card.dart';

/// Formatea el texto de la jornada o fase (ej. "16" -> "Jornada 16", "Cuartos" -> "Cuartos").
String _nombreJornada(String? j) {
  if (j == null || j.trim().isEmpty) return 'General';
  final num = int.tryParse(j.trim());
  if (num != null) return 'Jornada $num';
  return j.trim();
}

/// Una sola tarjeta con todos los partidos pendientes del torneo: el marcador de cada uno
/// se captura en su fila y se guardan todos con un solo botón.
/// Regla de bloqueo: solo es editable el partido en FUTURO cuya hora de inicio no ha llegado.
class PronosticosTorneoCard extends StatefulWidget {
  const PronosticosTorneoCard({
    super.key,
    required this.titulo,
    required this.partidos,
    required this.pronosticos,
    required this.onGuardar,
    this.subtitulo,
    this.limite,
    this.buscador = false,
    this.filtroMarcador = false,
    this.guardarPorPartido = false,
    this.puedeEditar = false,
    this.partidoElegido,
  });

  /// Nombre del torneo (detalle) o de la quiniela (Mis pronósticos, con el torneo en [subtitulo]).
  final String titulo;
  final String? subtitulo;

  /// Partidos que se ven de entrada; el resto aparece con "Ver más" (lo escrito no se pierde al ocultar).
  /// null = todos.
  final int? limite;

  /// Barra para buscar partidos por equipo ("Municipal" o "Municipal vs Comunicaciones").
  final bool buscador;

  /// Botones para ver todos los partidos, solo los que aún no tienen mi marcador o solo los que ya.
  final bool filtroMarcador;

  /// En vez de un botón para todos, "Guardar" aparece solo en el partido seleccionado.
  final bool guardarPorPartido;

  /// Cuenta PRO/VIP: puede cambiar marcadores ya guardados. Gratis solo los asigna la primera vez.
  final bool puedeEditar;

  /// Partido al que se llega desde Mis Quinielas: se resalta, se desplaza hasta él y
  /// su primer campo de goles queda listo para escribir.
  final String? partidoElegido;
  final List<Partido> partidos;
  final Map<String, Pronostico> pronosticos;
  final GuardarPronostico onGuardar;

  @override
  State<PronosticosTorneoCard> createState() => _PronosticosTorneoCardState();
}

class _PronosticosTorneoCardState extends State<PronosticosTorneoCard> {
  final _local = <String, TextEditingController>{};
  final _visitante = <String, TextEditingController>{};
  final _elegidoKey = GlobalKey();
  final _tarjetaKey = GlobalKey();
  final _autoGuardarTimers = <String, Timer>{};

  bool _guardando = false;
  bool _verTodos = false;
  String _busqueda = '';
  _FiltroMarcador _filtro = _FiltroMarcador.todos;
  String? _jornadaSeleccionada;

  /// Partido que el usuario tocó o editó por última vez.
  String? _seleccionado;
  String? _guardandoId;

  String _guardado(int? goles) => goles?.toString() ?? '';

  List<String> _obtenerJornadas() {
    final lista = <String>[];
    for (final p in widget.partidos) {
      final j = _nombreJornada(p.jornada);
      if (!lista.contains(j)) {
        lista.add(j);
      }
    }
    return lista;
  }

  String? _determinarJornadaInicial(List<String> jornadas) {
    if (jornadas.isEmpty) return null;
    if (widget.partidoElegido != null) {
      final pElegido = widget.partidos.where((p) => p.id == widget.partidoElegido).firstOrNull;
      if (pElegido != null) return _nombreJornada(pElegido.jornada);
    }
    // Seleccionar por defecto la primera jornada con partidos pendientes sin pronosticar
    for (final j in jornadas) {
      final enJornada = widget.partidos.where((p) => _nombreJornada(p.jornada) == j);
      if (enJornada.any((p) => p.aceptaPronostico && !widget.pronosticos.containsKey(p.id))) {
        return j;
      }
    }
    return jornadas.first;
  }

  @override
  void initState() {
    super.initState();
    _sincronizar(null);
    final j = _obtenerJornadas();
    _jornadaSeleccionada = _determinarJornadaInicial(j);
    if (widget.partidoElegido != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fila = _elegidoKey.currentContext;
        if (fila == null || !fila.mounted) return;
        Scrollable.ensureVisible(fila, duration: const Duration(milliseconds: 300), alignment: 0.2);
      });
    }
  }

  @override
  void didUpdateWidget(PronosticosTorneoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizar(oldWidget.pronosticos);
  }

  /// Crea los campos de partidos nuevos y refleja los pronósticos que cambiaron en la base.
  void _sincronizar(Map<String, Pronostico>? anteriores) {
    for (final p in widget.partidos) {
      final pr = widget.pronosticos[p.id];
      final local = _local.putIfAbsent(p.id, () => TextEditingController(text: _guardado(pr?.golesLocal)));
      final visitante =
          _visitante.putIfAbsent(p.id, () => TextEditingController(text: _guardado(pr?.golesVisitante)));
      if (anteriores != null && pr != null && pr != anteriores[p.id]) {
        local.text = pr.golesLocal.toString();
        visitante.text = pr.golesVisitante.toString();
      }
    }
  }

  @override
  void dispose() {
    for (final t in _autoGuardarTimers.values) {
      t.cancel();
    }
    for (final c in [..._local.values, ..._visitante.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Marcador completo, editable y distinto al guardado.
  bool _listoParaGuardar(Partido p) {
    final l = _local[p.id]?.text.trim() ?? '';
    final v = _visitante[p.id]?.text.trim() ?? '';
    final pr = widget.pronosticos[p.id];
    return p.aceptaPronostico &&
        (pr == null || widget.puedeEditar) &&
        l.isNotEmpty &&
        v.isNotEmpty &&
        int.tryParse(l) != null &&
        int.tryParse(v) != null &&
        (l != _guardado(pr?.golesLocal) || v != _guardado(pr?.golesVisitante));
  }

  /// Dispara auto-guardado en background con debounce de 500ms si ambos campos están llenos.
  void _alCambiarMarcador(Partido p) {
    setState(() => _seleccionado = p.id);
    final l = _local[p.id]?.text.trim() ?? '';
    final v = _visitante[p.id]?.text.trim() ?? '';

    // Si ambos tienen dígitos numéricos válidos, activar auto-guardado silencioso
    if (l.isNotEmpty && v.isNotEmpty && int.tryParse(l) != null && int.tryParse(v) != null) {
      _autoGuardarTimers[p.id]?.cancel();
      _autoGuardarTimers[p.id] = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _listoParaGuardar(p) && _guardandoId != p.id) {
          _guardarUno(p, silencioso: true);
        }
      });
    }
  }

  /// Guarda solo un partido (manual o auto-guardado).
  Future<void> _guardarUno(Partido p, {bool silencioso = false}) async {
    if (!p.aceptaPronostico) {
      if (!silencioso) {
        Notificacion.advertencia(context, 'El partido ya comenzó.', titulo: 'Pronósticos cerrados');
      }
      return;
    }
    final lStr = _local[p.id]?.text.trim() ?? '';
    final vStr = _visitante[p.id]?.text.trim() ?? '';
    if (lStr.isEmpty || vStr.isEmpty) return;
    final local = int.tryParse(lStr);
    final visitante = int.tryParse(vStr);
    if (local == null || visitante == null) return;

    setState(() => _guardandoId = p.id);
    try {
      await widget.onGuardar(p, local, visitante);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      if (!silencioso) {
        FocusScope.of(context).unfocus();
        setState(() => _seleccionado = null);
        Notificacion.exito(context, 'Tu pronóstico quedó guardado: $local - $visitante.', titulo: 'Pronóstico guardado');
      }
    } catch (e) {
      if (mounted && !silencioso) {
        Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
      }
    } finally {
      if (mounted) setState(() => _guardandoId = null);
    }
  }

  /// Guarda todos los partidos pendientes de la lista (jornada actual o lista completa).
  Future<void> _guardar(List<Partido> lista) async {
    FocusScope.of(context).unfocus();
    final porGuardar = lista.where(_listoParaGuardar).toList();
    if (porGuardar.isEmpty) return;

    setState(() => _guardando = true);
    var guardados = 0;
    Object? error;
    for (final p in porGuardar) {
      try {
        final l = int.parse(_local[p.id]!.text.trim());
        final v = int.parse(_visitante[p.id]!.text.trim());
        await widget.onGuardar(p, l, v);
        guardados++;
      } catch (e) {
        error ??= e;
      }
    }

    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      Notificacion.excepcion(
        context,
        error,
        titulo: guardados == 0 ? 'No se pudo guardar' : 'Se guardaron $guardados de ${porGuardar.length}',
      );
    } else {
      HapticFeedback.lightImpact();
      Notificacion.exito(
        context,
        guardados == 1 ? 'Tu pronóstico quedó guardado.' : 'Tus $guardados pronósticos quedaron guardados.',
        titulo: 'Pronósticos guardados',
      );
    }
  }

  /// "Ver menos" está al final: al ocultar, regresa al inicio de la tarjeta.
  void _verMenos() {
    setState(() => _verTodos = false);
    TdsVerMas.regresarA(_tarjetaKey);
  }

  @override
  Widget build(BuildContext context) {
    final buscando = _busqueda.trim().isNotEmpty;
    bool conMarcador(Partido p) => widget.pronosticos.containsKey(p.id);

    final jornadas = _obtenerJornadas();
    if (_jornadaSeleccionada != null && !jornadas.contains(_jornadaSeleccionada)) {
      _jornadaSeleccionada = _determinarJornadaInicial(jornadas);
    }

    // Partidos que corresponden a la jornada seleccionada (o todos si se eligió "Todas" o se busca)
    final partidosBase = _jornadaSeleccionada == null || buscando
        ? widget.partidos
        : widget.partidos.where((p) => _nombreJornada(p.jornada) == _jornadaSeleccionada).toList();

    final conMio = partidosBase.where(conMarcador).length;
    final coinciden = partidosBase
        .where(
          (p) => switch (_filtro) {
            _FiltroMarcador.todos => true,
            _FiltroMarcador.sinMarcador => !conMarcador(p),
            _FiltroMarcador.conMarcador => conMarcador(p),
          },
        )
        .where((p) => p.coincideConBusqueda(_busqueda))
        .toList();

    final limite = buscando ? null : widget.limite;
    final ocultos = limite == null ? 0 : coinciden.length - limite;
    final visibles = ocultos > 0 && !_verTodos ? coinciden.take(limite!).toList() : coinciden;
    final abiertos = partidosBase.where((p) => p.aceptaPronostico).toList();
    final listos = abiertos.where((p) => widget.pronosticos.containsKey(p.id)).length;
    final porGuardar = partidosBase.where(_listoParaGuardar).length;

    final contador = TdsPill(
      color: TdsColors.acento.withValues(alpha: 0.15),
      child: Text('$listos/${abiertos.length} pronosticados', style: TdsText.label(10, color: TdsColors.acento)),
    );

    final encabezado = Row(
      children: [
        const Icon(Icons.emoji_events_outlined, size: 18, color: TdsColors.acento),
        const SizedBox(width: 8),
        Expanded(
          child: widget.subtitulo == null
              ? Text(
                  widget.titulo.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TdsText.label(12, color: TdsColors.textoSecundario, letterSpacing: 1),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.titulo, overflow: TextOverflow.ellipsis, style: TdsText.headline(16)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(widget.subtitulo!, style: TdsText.body(12, color: TdsColors.textoSecundario)),
                        contador,
                      ],
                    ),
                  ],
                ),
        ),
        if (widget.subtitulo == null) contador,
      ],
    );

    final contenido = <Widget>[
      // Barra de búsqueda opcional
      if (widget.buscador) ...[
        const SizedBox(height: 4),
        TdsBuscador(
          hint: 'Buscar equipo: Equipo A vs Equipo B',
          color: TdsColors.surfaceContainerHigh,
          onChanged: (v) => setState(() => _busqueda = v),
        ),
        const SizedBox(height: 4),
      ],

      // Selector Horizontal de Jornadas / Fases
      if (jornadas.length > 1 && !buscando) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _BotonJornada(
                texto: 'Todas (${widget.partidos.length})',
                activo: _jornadaSeleccionada == null,
                onTap: () => setState(() => _jornadaSeleccionada = null),
              ),
              for (final j in jornadas) ...[
                const SizedBox(width: 8),
                _BotonJornada(
                  texto: j,
                  subtexto: '${widget.partidos.where((p) => _nombreJornada(p.jornada) == j).length}',
                  activo: _jornadaSeleccionada == j,
                  tienePendientes: widget.partidos
                      .where((p) => _nombreJornada(p.jornada) == j)
                      .any((p) => !widget.pronosticos.containsKey(p.id) && p.aceptaPronostico),
                  onTap: () => setState(() => _jornadaSeleccionada = j),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],

      // Filtros de estado de marcador (Todos / Sin mi marcador / Con mi marcador)
      if (widget.filtroMarcador) ...[
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _BotonFiltro(
              texto: 'Todos (${partidosBase.length})',
              icono: Icons.list,
              activo: _filtro == _FiltroMarcador.todos,
              onTap: () => setState(() => _filtro = _FiltroMarcador.todos),
            ),
            _BotonFiltro(
              texto: 'Sin marcador (${partidosBase.length - conMio})',
              icono: Icons.edit_outlined,
              activo: _filtro == _FiltroMarcador.sinMarcador,
              onTap: () => setState(() => _filtro = _FiltroMarcador.sinMarcador),
            ),
            _BotonFiltro(
              texto: 'Con marcador ($conMio)',
              icono: Icons.check_circle_outline,
              activo: _filtro == _FiltroMarcador.conMarcador,
              onTap: () => setState(() => _filtro = _FiltroMarcador.conMarcador),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],

      if (visibles.isEmpty && (buscando || _filtro != _FiltroMarcador.todos))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            buscando
                ? 'Ningún partido coincide con "${_busqueda.trim()}".'
                : (_filtro == _FiltroMarcador.sinMarcador
                    ? '¡Excelente! Ya pronosticaste todos los partidos de esta jornada.'
                    : 'Aún no tienes pronósticos guardados en esta sección.'),
            textAlign: TextAlign.center,
            style: TdsText.body(13, color: TdsColors.textoSecundario),
          ),
        ),

      // Filas de los partidos de la jornada seleccionada
      for (var i = 0; i < visibles.length; i++) ...[
        if (i > 0) const Divider(height: 1, color: TdsColors.borde),
        _FilaPartido(
          key: visibles[i].id == widget.partidoElegido ? _elegidoKey : null,
          partido: visibles[i],
          local: _local[visibles[i].id]!,
          visitante: _visitante[visibles[i].id]!,
          guardado: widget.pronosticos.containsKey(visibles[i].id),
          cargando: _guardandoId == visibles[i].id,
          bloqueadoPremium: !widget.puedeEditar && widget.pronosticos.containsKey(visibles[i].id),
          elegido: visibles[i].id == widget.partidoElegido,
          onChanged: () => _alCambiarMarcador(visibles[i]),
          onSeleccionar: () => setState(() => _seleccionado = visibles[i].id),
          boton: widget.guardarPorPartido && _seleccionado == visibles[i].id && visibles[i].aceptaPronostico
              ? TdsPillButton(
                  icon: Icons.save_outlined,
                  label: 'Guardar',
                  primary: true,
                  cargando: _guardandoId == visibles[i].id,
                  onTap: _guardandoId == null && _listoParaGuardar(visibles[i]) ? () => _guardarUno(visibles[i]) : null,
                )
              : null,
        ),
      ],

      if (ocultos > 0)
        TdsVerMas(
          ocultos: ocultos,
          abierto: _verTodos,
          onTap: _verTodos ? _verMenos : () => setState(() => _verTodos = true),
        ),

      const SizedBox(height: 12),

      // Botón o aviso de guardado específico para la jornada a la vista
      if (abiertos.isEmpty)
        const AvisoPronostico(icono: Icons.lock_outline, texto: 'Pronósticos cerrados', color: TdsColors.textoSecundario)
      else if (porGuardar == 0 && !_guardando && listos == abiertos.length)
        AvisoPronostico(
          icono: Icons.check_circle,
          texto: _jornadaSeleccionada == null
              ? 'Todos tus pronósticos están guardados'
              : 'Pronósticos de $_jornadaSeleccionada guardados',
          color: TdsColors.acento,
        )
      else if (!widget.guardarPorPartido)
        TdsPillButton(
          icon: Icons.save_outlined,
          label: porGuardar == 0
              ? 'Guardar pronósticos'
              : (_jornadaSeleccionada == null
                  ? 'Guardar pronósticos ($porGuardar)'
                  : 'Guardar $_jornadaSeleccionada ($porGuardar)'),
          primary: true,
          cargando: _guardando,
          onTap: porGuardar > 0 && !_guardando ? () => _guardar(partidosBase) : null,
        ),
    ];

    return TdsCard(
      key: _tarjetaKey,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [encabezado, const SizedBox(height: 8), ...contenido],
      ),
    );
  }
}

/// Botón píldora para seleccionar Jornada / Fase.
class _BotonJornada extends StatelessWidget {
  const _BotonJornada({
    required this.texto,
    this.subtexto,
    required this.activo,
    this.tienePendientes = false,
    required this.onTap,
  });

  final String texto;
  final String? subtexto;
  final bool activo;
  final bool tienePendientes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? TdsColors.acento : TdsColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: activo
                ? TdsColors.acento
                : (tienePendientes ? TdsColors.advertencia.withValues(alpha: 0.6) : Colors.transparent),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tienePendientes && !activo) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TdsColors.advertencia,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              texto,
              style: TdsText.label(
                12,
                color: activo ? TdsColors.sobreAcento : TdsColors.texto,
              ),
            ),
            if (subtexto != null) ...[
              const SizedBox(width: 4),
              Text(
                '($subtexto)',
                style: TdsText.label(
                  11,
                  color: activo ? TdsColors.sobreAcento.withValues(alpha: 0.7) : TdsColors.textoSecundario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filtro de la tarjeta: todos los partidos, sin mi marcador o con mi marcador.
enum _FiltroMarcador { todos, sinMarcador, conMarcador }

/// Botón píldora del filtro; el activo va en lima.
class _BotonFiltro extends StatelessWidget {
  const _BotonFiltro({required this.texto, required this.icono, required this.activo, required this.onTap});

  final String texto;
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? TdsColors.onPrimaryContainer : TdsColors.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? TdsColors.primaryContainer : TdsColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 6),
            Text(texto, style: TdsText.label(11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _FilaPartido extends StatelessWidget {
  const _FilaPartido({
    super.key,
    required this.partido,
    required this.local,
    required this.visitante,
    required this.guardado,
    required this.onChanged,
    this.cargando = false,
    this.elegido = false,
    this.bloqueadoPremium = false,
    this.onSeleccionar,
    this.boton,
  });

  final bool cargando;
  final bool bloqueadoPremium;
  final Partido partido;
  final TextEditingController local;
  final TextEditingController visitante;
  final bool guardado;
  final VoidCallback onChanged;
  final VoidCallback? onSeleccionar;
  final Widget? boton;
  final bool elegido;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final abierto = p.aceptaPronostico;
    final editable = abierto && !bloqueadoPremium;

    final localLleno = local.text.trim().isNotEmpty;
    final visitanteLleno = visitante.text.trim().isNotEmpty;
    final incompleto = abierto && ((localLleno && !visitanteLleno) || (!localLleno && visitanteLleno));

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: elegido ? 10 : 0),
      decoration: elegido
          ? BoxDecoration(
              color: TdsColors.acento.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TdsColors.acento),
            )
          : null,
      child: Column(
        children: [
          Row(
            children: [
              Icon(abierto ? Icons.event : Icons.lock_outline, size: 13, color: TdsColors.textoSecundario),
              const SizedBox(width: 4),
              Expanded(
                child: Text(Formatos.diaHora(p.fecha), style: TdsText.label(11, color: TdsColors.textoSecundario)),
              ),
              if (cargando) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: TdsColors.acento),
                ),
                const SizedBox(width: 4),
                Text('Guardando…', style: TdsText.label(10, color: TdsColors.acento)),
                const SizedBox(width: 6),
              ] else if (incompleto) ...[
                const Icon(Icons.info_outline, size: 13, color: TdsColors.advertencia),
                const SizedBox(width: 3),
                Text(
                  localLleno ? 'Falta visitante' : 'Falta local',
                  style: TdsText.label(10, color: TdsColors.advertencia),
                ),
                const SizedBox(width: 6),
              ] else if (guardado && abierto) ...[
                const Icon(Icons.check_circle, size: 14, color: TdsColors.acento),
                const SizedBox(width: 3),
                Text('Guardado', style: TdsText.label(10, color: TdsColors.acento)),
                const SizedBox(width: 6),
              ],
              if (abierto && bloqueadoPremium) const LapizEditarPremium(),
              EstadoPartidoPill(estado: p.estado),
            ],
          ),
          const SizedBox(height: 6),
          DetallesPartido(partido: p),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: EquipoEscudo(
                  nombre: p.local.nombre,
                  escudoUrl: p.local.escudoUrl,
                  size: 32,
                  disposicion: DisposicionEscudo.horizontal,
                ),
              ),
              GolesField(
                controller: local,
                enabled: editable,
                autofocus: elegido,
                etiqueta: 'Goles de ${p.local.nombre}',
                onChanged: () {
                  // Si completó local y visitante está vacío, saltar al visitante automáticamente
                  if (local.text.trim().isNotEmpty && visitante.text.trim().isEmpty) {
                    FocusScope.of(context).nextFocus();
                  }
                  onChanged();
                },
                onTap: onSeleccionar,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(':', style: TdsText.stats(22, color: TdsColors.textoSecundario)),
              ),
              GolesField(
                controller: visitante,
                enabled: editable,
                etiqueta: 'Goles de ${p.visitante.nombre}',
                onChanged: onChanged,
                onTap: onSeleccionar,
              ),
              Expanded(
                child: EquipoEscudo(
                  nombre: p.visitante.nombre,
                  escudoUrl: p.visitante.escudoUrl,
                  size: 32,
                  disposicion: DisposicionEscudo.horizontalInvertida,
                ),
              ),
            ],
          ),
          if (boton != null) ...[
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: boton),
          ],
        ],
      ),
    );
  }
}
