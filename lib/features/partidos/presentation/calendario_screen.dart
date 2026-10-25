import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tds_ui.dart';
import '../domain/partido.dart';
import '../providers/partidos_providers.dart';
import 'widgets/partidos_filtros.dart';
import 'widgets/torneo_secciones.dart';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

/// Calendario de juegos: tira de días del mes, filtros por liga y partidos agrupados por torneo.
class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  DateTime _dia = _soloFecha(DateTime.now());
  bool _diaInicializado = false;
  bool _porMes = false; // false = partidos del día, true = todo el mes
  bool _soloAbiertos = false; // solo partidos que aceptan pronóstico
  String? _torneo; // null = todas las ligas
  String _busqueda = '';

  Future<void> _recargar() => ref.refresh(partidosProvider(null).future);

  void _cambiarMes(int delta) {
    final mes = DateTime(_dia.year, _dia.month + delta);
    final hoy = _soloFecha(DateTime.now());
    setState(() {
      _dia = (mes.year == hoy.year && mes.month == hoy.month) ? hoy : DateTime(mes.year, mes.month, 1);
      final todos = ref.read(partidosProvider(null)).valueOrNull ?? const <Partido>[];
      final delMes = todos.where((p) =>
          p.fecha != null &&
          p.fecha!.year == mes.year &&
          p.fecha!.month == mes.month &&
          (_torneo == null || p.torneo == _torneo)).toList();
      if (delMes.isNotEmpty) {
        final dias = delMes.map((p) => _soloFecha(p.fecha!)).toSet().toList()..sort();
        if (!dias.contains(_dia)) {
          final proximo = dias.where((d) => !d.isBefore(_dia)).firstOrNull ?? dias.first;
          _dia = proximo;
        }
      }
    });
  }

  /// Si el día elegido no tiene partidos de [partidos], el próximo que sí (o el primero del mes).
  DateTime? _diaConPartidos(Iterable<Partido> partidos) {
    final dias = partidos.map((p) => _soloFecha(p.fecha!)).toSet().toList()..sort();
    if (dias.isEmpty) return null;
    if (dias.contains(_dia)) return _dia;
    return dias.where((d) => d.isAfter(_dia)).firstOrNull ?? dias.first;
  }

  bool _pasaFiltros(Partido p) {
    if (_soloAbiertos && !p.aceptaPronostico) return false;
    if (_torneo != null && p.torneo != _torneo) return false;
    return p.coincideConBusqueda(_busqueda) || p.torneo.toLowerCase().contains(_busqueda.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TdsAppBar(titulo: 'CALENDARIO', onRefrescar: _recargar),
      body: AsyncValueView(
        value: ref.watch(partidosProvider(null)),
        onReintentar: _recargar,
        data: _buildContenido,
      ),
    );
  }

  Widget _buildContenido(List<Partido> todos) {
    // Si aún no se inicializó el día, buscar el día más cercano a hoy que sí tenga partidos
    if (!_diaInicializado && todos.isNotEmpty) {
      final hoy = _soloFecha(DateTime.now());
      final delMesActual = todos
          .where((p) => p.fecha != null && p.fecha!.year == hoy.year && p.fecha!.month == hoy.month)
          .toList();
      if (delMesActual.isNotEmpty) {
        final tieneHoy = delMesActual.any((p) => _soloFecha(p.fecha!) == hoy);
        if (!tieneHoy) {
          final dias = delMesActual.map((p) => _soloFecha(p.fecha!)).toSet().toList()..sort();
          final proximo = dias.where((d) => !d.isBefore(hoy)).firstOrNull ?? dias.first;
          _dia = proximo;
        }
      }
      _diaInicializado = true;
    }

    final delMes = todos
        .where((p) => p.fecha != null && p.fecha!.year == _dia.year && p.fecha!.month == _dia.month)
        .toList();
    final filtrados = delMes.where(_pasaFiltros).toList();
    final visibles = _porMes
        ? filtrados
        : filtrados.where((p) => _soloFecha(p.fecha!) == _dia).toList();

    // Conteo por día para la tira (respeta liga, búsqueda y "quiniela abierta")
    final conteo = <int, int>{};
    for (final p in filtrados) {
      conteo.update(p.fecha!.day, (n) => n + 1, ifAbsent: () => 1);
    }

    // Agrupados por torneo, en orden de hora
    final grupos = agruparPorTorneo(visibles..sort((a, b) => a.fecha!.compareTo(b.fecha!)));

    // Otros torneos con partidos que no salen en esta vista (con todas las ligas, sin buscar)
    final otros = _torneo != null || _busqueda.trim().isNotEmpty
        ? <List<Partido>>[]
        : (agruparPorTorneo(todos)..removeWhere((id, _) => grupos.containsKey(id))).values.toList()
      ..sort((a, b) => a.first.torneo.compareTo(b.first.torneo));

    final abiertos = visibles.where((p) => p.aceptaPronostico).length;
    final torneos = delMes.map((p) => p.torneo).toSet().toList()..sort();

    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Encabezado(
                  anio: _dia.year,
                  porMes: _porMes,
                  onModo: (v) => setState(() => _porMes = v),
                ),
                const SizedBox(height: 16),
                TdsBuscador(hint: 'Buscar equipo o liga...', onChanged: (v) => setState(() => _busqueda = v)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _SelectorMes(
                      texto: '${_meses[_dia.month - 1]} ${_dia.year}',
                      esHoy: _dia == _soloFecha(DateTime.now()),
                      onHoy: () => setState(() => _dia = _soloFecha(DateTime.now())),
                      onAnterior: () => _cambiarMes(-1),
                      onSiguiente: () => _cambiarMes(1),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _soloAbiertos = !_soloAbiertos),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _soloAbiertos ? TdsColors.acento : TdsColors.superficieAlta,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _soloAbiertos ? TdsColors.acento : TdsColors.borde.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 14,
                              color: _soloAbiertos ? TdsColors.sobreAcento : TdsColors.acento,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quiniela abierta',
                              style: TdsText.label(
                                11,
                                color: _soloAbiertos ? TdsColors.sobreAcento : TdsColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_porMes) ...[
            const SizedBox(height: 8),
            _TiraDias(
              mes: DateTime(_dia.year, _dia.month),
              seleccionado: _dia,
              conteo: conteo,
              // Con una liga elegida solo se muestran sus días de partido
              soloConPartidos: _torneo != null,
              onChanged: (d) => setState(() => _dia = d),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LigasChips(
              torneos: torneos,
              seleccionado: _torneo,
              onChanged: (t) => setState(() {
                _torneo = t;
                if (t != null) _dia = _diaConPartidos(delMes.where((p) => p.torneo == t)) ?? _dia;
              }),
            ),
          ),
          if (abiertos > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _BannerQuiniela(
                abiertos: abiertos,
                cuando: _porMes ? 'este mes' : Formatos.dia(_dia).toLowerCase(),
              ),
            ),
          const SizedBox(height: 24),
          if (grupos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  VacioView(
                    icono: Icons.event_busy_outlined,
                    texto: _porMes ? 'No hay partidos este mes' : 'No hay partidos este día',
                    subtitulo: _porMes
                        ? 'Prueba cambiando de mes o limpiando los filtros.'
                        : 'No hay encuentros programados para esta fecha.',
                  ),
                  if (!_porMes && delMes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final proximo = _diaConPartidos(delMes) ?? delMes.first.fecha;
                        if (proximo != null) {
                          setState(() => _dia = _soloFecha(proximo));
                        }
                      },
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text(
                        'VER DÍA CON PARTIDOS MÁS CERCANO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TdsColors.acento,
                        foregroundColor: TdsColors.sobreAcento,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else if (_porMes) ...[
            ..._construirVistaMes(filtrados),
          ] else ...[
            for (final grupo in grupos.values)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SeccionTorneo(partidos: grupo, conPronostico: true),
              ),
          ],
          if (!_porMes && otros.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _OtrosTorneos(grupos: otros),
            ),
          if (grupos.isNotEmpty) const _Final(),
        ],
      ),
    );
  }

  List<Widget> _construirVistaMes(List<Partido> partidos) {
    final partidosPorDia = <DateTime, List<Partido>>{};
    for (final p in partidos) {
      if (p.fecha == null) continue;
      final dia = _soloFecha(p.fecha!);
      partidosPorDia.putIfAbsent(dia, () => []).add(p);
    }

    final diasOrdenados = partidosPorDia.keys.toList()..sort();
    final widgets = <Widget>[];

    for (final dia in diasOrdenados) {
      final partidosDelDia = partidosPorDia[dia]!;
      final gruposTorneo = agruparPorTorneo(partidosDelDia..sort((a, b) => a.fecha!.compareTo(b.fecha!)));
      final esHoy = dia == _soloFecha(DateTime.now());

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: esHoy ? TdsColors.acento : TdsColors.superficieAlta,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esHoy ? TdsColors.acento : TdsColors.borde.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${_diasSemana[dia.weekday - 1].toUpperCase()} ${dia.day} DE ${_meses[dia.month - 1].toUpperCase()}',
                  style: TdsText.label(
                    11,
                    color: esHoy ? TdsColors.sobreAcento : TdsColors.acento,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${partidosDelDia.length} ${partidosDelDia.length == 1 ? 'partido' : 'partidos'}',
                style: TdsText.label(11, color: TdsColors.textoSecundario),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _dia = dia;
                  _porMes = false;
                }),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver día', style: TdsText.label(11, color: TdsColors.acento)),
                    const Icon(Icons.chevron_right, size: 14, color: TdsColors.acento),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      for (final grupo in gruposTorneo.values) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: SeccionTorneo(partidos: grupo, conPronostico: true),
          ),
        );
      }
    }

    return widgets;
  }
}

/// "Temporada 2026" + título + selector Fecha / Mes.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.anio, required this.porMes, required this.onModo});

  final int anio;
  final bool porMes;
  final ValueChanged<bool> onModo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TdsDot(color: TdsColors.acento, pulse: true),
                  const SizedBox(width: 8),
                  Text('TEMPORADA $anio', style: TdsText.label(11, color: TdsColors.acento, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Calendario de Juegos', style: TdsText.headline(26)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: TdsColors.superficieAlta, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BotonModo(icono: Icons.calendar_month, texto: 'Fecha', activo: !porMes, onTap: () => onModo(false)),
              _BotonModo(icono: Icons.format_list_numbered, texto: 'Mes', activo: porMes, onTap: () => onModo(true)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonModo extends StatelessWidget {
  const _BotonModo({required this.icono, required this.texto, required this.activo, required this.onTap});

  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? TdsColors.sobreAcento : TdsColors.textoSecundario;
    return Semantics(
      button: true,
      selected: activo,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: activo ? TdsColors.acento : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 4),
              Text(texto, style: TdsText.label(12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "OCTUBRE 2026" con flechas para cambiar de mes.
class _SelectorMes extends StatelessWidget {
  const _SelectorMes({
    required this.texto,
    required this.onAnterior,
    required this.onSiguiente,
    this.onHoy,
    this.esHoy = false,
  });

  final String texto;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback? onHoy;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    Widget flecha(IconData icono, String tooltip, VoidCallback onTap) => IconButton(
          icon: Icon(icono, size: 20, color: TdsColors.acento),
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onTap,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        flecha(Icons.chevron_left, 'Mes anterior', onAnterior),
        Text(texto.toUpperCase(), style: TdsText.headline(13, weight: FontWeight.w700).copyWith(letterSpacing: 0.8)),
        flecha(Icons.chevron_right, 'Mes siguiente', onSiguiente),
        if (!esHoy && onHoy != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onHoy,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TdsColors.acento.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TdsColors.acento.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TdsDot(color: TdsColors.acento, size: 4, pulse: true),
                  const SizedBox(width: 4),
                  Text('HOY', style: TdsText.label(10, color: TdsColors.acento, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tira horizontal con los días del mes y cuántos partidos hay en cada uno.
class _TiraDias extends StatefulWidget {
  const _TiraDias({
    required this.mes,
    required this.seleccionado,
    required this.conteo,
    required this.onChanged,
    this.soloConPartidos = false,
  });

  final DateTime mes;
  final DateTime seleccionado;
  final Map<int, int> conteo;
  final ValueChanged<DateTime> onChanged;

  /// Solo los días que tienen partidos (cuando hay una liga elegida).
  final bool soloConPartidos;

  List<int> get dias {
    final total = DateTime(mes.year, mes.month + 1, 0).day;
    final todos = [for (var d = 1; d <= total; d++) d];
    return soloConPartidos ? todos.where((d) => (conteo[d] ?? 0) > 0).toList() : todos;
  }

  @override
  State<_TiraDias> createState() => _TiraDiasState();
}

class _TiraDiasState extends State<_TiraDias> {
  static const _ancho = 58.0;
  static const _separacion = 8.0;

  late final _scroll = ScrollController(initialScrollOffset: _offset());

  /// Deja el día elegido cerca del inicio de la tira.
  double _offset() {
    final i = widget.dias.indexOf(widget.seleccionado.day);
    return ((i < 0 ? 0 : i - 2) * (_ancho + _separacion)).clamp(0, double.infinity).toDouble();
  }

  @override
  void didUpdateWidget(_TiraDias oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cambio = widget.mes != oldWidget.mes ||
        widget.seleccionado != oldWidget.seleccionado ||
        widget.soloConPartidos != oldWidget.soloConPartidos;
    if (cambio && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          final target = _offset().clamp(0, _scroll.position.maxScrollExtent).toDouble();
          _scroll.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dias = widget.dias;
    final hoy = _soloFecha(DateTime.now());
    if (dias.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text('Esta liga no tiene partidos este mes',
              style: TdsText.body(13, color: TdsColors.textoSecundario)),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dias.length,
        separatorBuilder: (_, _) => const SizedBox(width: _separacion),
        itemBuilder: (_, i) {
          final fecha = DateTime(widget.mes.year, widget.mes.month, dias[i]);
          return _Dia(
            fecha: fecha,
            partidos: widget.conteo[dias[i]] ?? 0,
            activo: fecha == widget.seleccionado,
            esHoy: fecha == hoy,
            onTap: () => widget.onChanged(fecha),
          );
        },
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.fecha, required this.partidos, required this.activo, required this.esHoy, required this.onTap});

  final DateTime fecha;
  final int partidos;
  final bool activo;
  final bool esHoy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final conPartidos = partidos > 0;
    final resaltado = activo || conPartidos ? TdsColors.acento : TdsColors.textoSecundario;
    return Semantics(
      button: true,
      selected: activo,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _TiraDiasState._ancho,
          decoration: BoxDecoration(
            color: activo
                ? TdsColors.superficieAlta
                : conPartidos
                    ? TdsColors.acento.withValues(alpha: 0.12)
                    : TdsColors.superficie,
            borderRadius: BorderRadius.circular(24),
            border: conPartidos
                ? Border.all(
                    color: TdsColors.acento.withValues(alpha: activo ? 1 : 0.6),
                    width: activo ? 1.5 : 1,
                  )
                : Border.all(color: Colors.transparent),
            boxShadow: activo ? [BoxShadow(color: TdsColors.acento.withValues(alpha: 0.18), blurRadius: 15)] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (esHoy) ...[
                TdsDot(color: TdsColors.acento, size: 5, pulse: activo),
                const SizedBox(height: 2),
              ],
              Text(_diasSemana[fecha.weekday - 1].toUpperCase(), style: TdsText.label(10, color: resaltado)),
              const SizedBox(height: 2),
              Text('${fecha.day}',
                  style: TdsText.stats(activo ? 16 : 14, color: conPartidos ? TdsColors.acento : TdsColors.texto)),
              const SizedBox(height: 3),
              if (conPartidos)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: activo ? TdsColors.acento : TdsColors.acento.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$partidos',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: activo ? TdsColors.sobreAcento : TdsColors.acento,
                    ),
                  ),
                )
              else
                Text(
                  '—',
                  style: TdsText.label(9, color: TdsColors.textoTenue),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de partidos que todavía aceptan pronóstico.
class _BannerQuiniela extends StatelessWidget {
  const _BannerQuiniela({required this.abiertos, required this.cuando});

  final int abiertos;
  final String cuando;

  @override
  Widget build(BuildContext context) {
    return TdsCard(
      glow: true,
      color: TdsColors.superficieAlta,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: TdsColors.acento.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.bolt, size: 22, color: TdsColors.acento),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiniela abierta', style: TdsText.label(12, color: TdsColors.acento)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '$abiertos ${abiertos == 1 ? 'partido' : 'partidos'} de $cuando',
                      style: TdsText.label(12),
                    ),
                    TextSpan(
                      text: ' disponibles para pronosticar.',
                      style: TdsText.body(12, color: TdsColors.textoSecundario),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Torneos con partidos que no aparecen en la vista actual, con su opción de crear quiniela.
class _OtrosTorneos extends StatelessWidget {
  const _OtrosTorneos({required this.grupos});

  final List<List<Partido>> grupos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('OTROS TORNEOS', style: TdsText.label(12, color: TdsColors.textoSecundario, letterSpacing: 1)),
        const SizedBox(height: 12),
        for (final partidos in grupos) ...[
          TdsCard(
            child: EncabezadoTorneo(
              partidos: partidos,
              cantidad: partidos.length,
              textoCantidad: _proximos(partidos),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  static String _proximos(List<Partido> partidos) {
    final n = partidos.where((p) => p.estado == EstadoPartido.futuro).length;
    return n == 0 ? 'Sin partidos próximos' : '$n ${n == 1 ? 'partido próximo' : 'partidos próximos'}';
  }
}

/// Nota al final de la lista.
class _Final extends StatelessWidget {
  const _Final();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: TdsColors.superficie, shape: BoxShape.circle),
            child: const Icon(Icons.sports_score, color: TdsColors.acento),
          ),
          const SizedBox(height: 8),
          Text('Has llegado al final de la lista', style: TdsText.label(14)),
          const SizedBox(height: 4),
          Text(
            'Los horarios corresponden a tu zona horaria local.',
            textAlign: TextAlign.center,
            style: TdsText.body(12, color: TdsColors.textoTenue),
          ),
        ],
      ),
    );
  }
}
