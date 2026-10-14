import 'package:flutter/material.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../domain/quiniela_models.dart';
import 'pronostico_card.dart';

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
  bool _guardando = false;
  bool _verTodos = false;
  String _busqueda = '';

  /// Partido que el usuario tocó o editó por última vez (guardarPorPartido).
  String? _seleccionado;
  String? _guardandoId;

  String _guardado(int? goles) => goles?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _sincronizar(null);
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
    for (final c in [..._local.values, ..._visitante.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Marcador completo, editable y distinto al guardado.
  bool _listoParaGuardar(Partido p) {
    final l = _local[p.id]!.text;
    final v = _visitante[p.id]!.text;
    final pr = widget.pronosticos[p.id];
    return p.aceptaPronostico &&
        (pr == null || widget.puedeEditar) &&
        l.isNotEmpty &&
        v.isNotEmpty &&
        (l != _guardado(pr?.golesLocal) || v != _guardado(pr?.golesVisitante));
  }

  List<Partido> get _porGuardar => widget.partidos.where(_listoParaGuardar).toList();

  /// Guarda solo el partido seleccionado (guardarPorPartido).
  Future<void> _guardarUno(Partido p) async {
    FocusScope.of(context).unfocus();
    if (!p.aceptaPronostico) {
      Notificacion.advertencia(context, 'El partido ya comenzó.', titulo: 'Pronósticos cerrados');
      return;
    }
    final local = int.parse(_local[p.id]!.text);
    final visitante = int.parse(_visitante[p.id]!.text);
    setState(() => _guardandoId = p.id);
    try {
      await widget.onGuardar(p, local, visitante);
      if (!mounted) return;
      setState(() => _seleccionado = null);
      Notificacion.exito(context, 'Tu pronóstico quedó guardado: $local - $visitante.', titulo: 'Pronóstico guardado');
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _guardandoId = null);
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final lista = _porGuardar;
    setState(() => _guardando = true);

    var guardados = 0;
    Object? error;
    for (final p in lista) {
      try {
        await widget.onGuardar(p, int.parse(_local[p.id]!.text), int.parse(_visitante[p.id]!.text));
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
        titulo: guardados == 0 ? 'No se pudo guardar' : 'Se guardaron $guardados de ${lista.length}',
      );
    } else {
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
    // Buscando se muestran todos los que coinciden; sin búsqueda, los primeros [limite] y "Ver más"
    final buscando = _busqueda.trim().isNotEmpty;
    final coinciden = widget.partidos.where((p) => p.coincideConBusqueda(_busqueda)).toList();
    final limite = buscando ? null : widget.limite;
    final ocultos = limite == null ? 0 : coinciden.length - limite;
    final visibles = ocultos > 0 && !_verTodos ? coinciden.take(limite!).toList() : coinciden;
    final abiertos = widget.partidos.where((p) => p.aceptaPronostico).toList();
    final listos = abiertos.where((p) => widget.pronosticos.containsKey(p.id)).length;
    final porGuardar = _porGuardar.length;

    final contador = TdsPill(
      color: TdsColors.acento.withValues(alpha: 0.15),
      child: Text('$listos/${abiertos.length} pronosticados', style: TdsText.label(10, color: TdsColors.acento)),
    );

    // Con subtítulo (Mis pronósticos) el contador va debajo del nombre
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
      if (widget.buscador) ...[
        const SizedBox(height: 4),
        TdsBuscador(
          hint: 'Buscar equipo: Equipo A vs Equipo B',
          color: TdsColors.surfaceContainerHigh,
          onChanged: (v) => setState(() => _busqueda = v),
        ),
        const SizedBox(height: 4),
      ],
      if (visibles.isEmpty && buscando)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Ningún partido coincide con "${_busqueda.trim()}".',
              style: TdsText.body(13, color: TdsColors.textoSecundario)),
        ),
      for (var i = 0; i < visibles.length; i++) ...[
        if (i > 0) const Divider(height: 1, color: TdsColors.borde),
        _FilaPartido(
          key: visibles[i].id == widget.partidoElegido ? _elegidoKey : null,
          partido: visibles[i],
          local: _local[visibles[i].id]!,
          visitante: _visitante[visibles[i].id]!,
          guardado: widget.pronosticos.containsKey(visibles[i].id),
          bloqueadoPremium: !widget.puedeEditar && widget.pronosticos.containsKey(visibles[i].id),
          elegido: visibles[i].id == widget.partidoElegido,
          onChanged: () => setState(() => _seleccionado = visibles[i].id),
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
      if (abiertos.isEmpty)
        const AvisoPronostico(icono: Icons.lock_outline, texto: 'Pronósticos cerrados', color: TdsColors.textoSecundario)
      else if (porGuardar == 0 && !_guardando && listos == abiertos.length)
        const AvisoPronostico(icono: Icons.check_circle, texto: 'Todos tus pronósticos están guardados', color: TdsColors.acento)
      else if (!widget.guardarPorPartido)
        TdsPillButton(
          icon: Icons.save_outlined,
          label: porGuardar == 0 ? 'Guardar pronósticos' : 'Guardar pronósticos ($porGuardar)',
          primary: true,
          cargando: _guardando,
          onTap: porGuardar > 0 && !_guardando ? _guardar : null,
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

/// Fila de un partido: fecha y estado arriba; local, marcador y visitante abajo.
class _FilaPartido extends StatelessWidget {
  const _FilaPartido({
    super.key,
    required this.partido,
    required this.local,
    required this.visitante,
    required this.guardado,
    required this.onChanged,
    this.elegido = false,
    this.bloqueadoPremium = false,
    this.onSeleccionar,
    this.boton,
  });

  /// Marcador guardado en cuenta gratis: campos bloqueados y lápiz que invita a suscribirse.
  final bool bloqueadoPremium;

  final Partido partido;
  final TextEditingController local;
  final TextEditingController visitante;
  final bool guardado;
  final VoidCallback onChanged;
  final VoidCallback? onSeleccionar;

  /// Botón "Guardar" de este partido (solo en el seleccionado).
  final Widget? boton;

  /// Resaltada con borde lima (partido elegido en Mis Quinielas).
  final bool elegido;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final abierto = p.aceptaPronostico;
    final editable = abierto && !bloqueadoPremium;

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
              if (guardado && abierto) ...[
                const Icon(Icons.check_circle, size: 14, color: TdsColors.acento),
                const SizedBox(width: 6),
              ],
              if (abierto && bloqueadoPremium) const LapizEditarPremium(),
              EstadoPartidoPill(estado: p.estado),
            ],
          ),
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
                onChanged: onChanged,
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
