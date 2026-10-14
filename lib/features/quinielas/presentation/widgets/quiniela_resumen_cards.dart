import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../../perfil/providers/perfil_providers.dart';
import '../../domain/etiquetas_puntos.dart';
import '../../domain/quiniela_models.dart';
import '../../providers/quinielas_acciones.dart';
import 'pronostico_card.dart';
import 'resultado_quiniela_badge.dart';

/// Card grande de la quiniela destacada: métricas, avance y partidos desplegables.
class QuinielaDestacadaCard extends StatelessWidget {
  const QuinielaDestacadaCard({super.key, required this.quiniela});

  final ResumenQuiniela quiniela;

  @override
  Widget build(BuildContext context) {
    final q = quiniela;
    final pctAvance = (q.avance * 100).round();
    final porJugar = q.porJugar;

    return TdsCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cabecera(quiniela: q),
          const SizedBox(height: 12),
          Text(q.nombre, style: TdsText.headline(26).copyWith(height: 1.15)),
          Text(q.torneoNombre, style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                _Metrica(titulo: 'ACIERTOS', valor: '${q.aciertos}', sufijo: '/ ${q.finalizados.length} jug.'),
                _Metrica(
                  titulo: 'TU POSICIÓN',
                  valor: '#${q.lugar}',
                  sufijo: '/ ${q.participantes}',
                  color: TdsColors.secondaryContainer,
                  resaltada: true,
                ),
                _Metrica(titulo: 'PUNTOS', valor: '${q.puntos}', sufijo: 'pts', color: TdsColors.onSurface),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Avance de la Quiniela', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
              ),
              Text(
                '$pctAvance% (${q.finalizados.length} de ${q.totalPartidos} partidos)',
                style: TdsText.label(12, color: TdsColors.primaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: q.avance,
              minHeight: 8,
              backgroundColor: TdsColors.surfaceContainerHighest,
              semanticsLabel: 'Avance de la quiniela',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.checklist, color: TdsColors.primaryContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PARTIDOS EN JUEGO Y POR JUGAR (${porJugar.length})',
                  style: TdsText.label(12, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (porJugar.isEmpty)
            Text(
              'No quedan partidos en juego ni por jugar.',
              style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
            )
          else
            _PartidosConBuscador(quiniela: q, partidos: porJugar),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TdsPillButton(
              icon: Icons.share_outlined,
              label: 'Copiar código',
              onTap: () => copiarCodigo(context, q.codigoAcceso),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card compacta, con desglose desplegable. En una quiniela finalizada muestra el resultado (4.7).
class QuinielaCompactaCard extends StatelessWidget {
  const QuinielaCompactaCard({super.key, required this.quiniela, this.miId});

  final ResumenQuiniela quiniela;

  /// Para la etiqueta "Creada por ti".
  final String? miId;

  @override
  Widget build(BuildContext context) {
    final q = quiniela;
    final finalizada = !q.activa;
    // Activa: solo partidos en juego o por jugar. Finalizada (historial): todos.
    final partidos = finalizada ? q.partidos : q.porJugar;
    final conPronostico = partidos.where((p) => q.pronosticos.containsKey(p.id)).toList();

    return TdsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(Rutas.quiniela(q.id, soloLectura: finalizada)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Cabecera(quiniela: q, compacta: true),
                          if (finalizada)
                            ResultadoQuinielaBadge(
                              resultado: q.resultado,
                              lugar: q.lugar,
                              total: q.participantes,
                              empate: q.empateEnPrimero,
                            ),
                          if (q.esCreador(miId))
                            TdsPill(
                              child: Text(
                                'CREADA POR TI',
                                style: TdsText.label(10, color: TdsColors.secondaryContainer),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(q.nombre, style: TdsText.headline(18)),
                      Text(q.torneoNombre, style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: TdsColors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: finalizada
                  ? [
                      _Dato(titulo: 'Resultado', valor: '${q.aciertos} / ${q.finalizados.length} aciertos'),
                      _Dato(
                        titulo: 'Posición final',
                        valor: '#${q.lugar} de ${q.participantes}',
                        color: TdsColors.secondaryContainer,
                      ),
                      _Dato(titulo: 'Puntos', valor: '${q.puntos} pts', color: TdsColors.primaryContainer),
                    ]
                  : [
                      _Dato(titulo: 'Participantes', valor: '${q.participantes} / ${q.limiteUsuarios}'),
                      _Dato(titulo: 'Pronósticos', valor: '${q.futurosListos} de ${q.futuros.length} listos'),
                      _Dato(titulo: 'Puntos', valor: '${q.puntos} pts', color: TdsColors.primaryContainer),
                    ],
            ),
          ),
          if (conPronostico.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'TUS ${conPronostico.length} SELECCIONES GUARDADAS:',
              style: TdsText.label(11, color: TdsColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final p in conPronostico)
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TdsColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      signo(q.pronosticos[p.id]!.golesLocal, q.pronosticos[p.id]!.golesVisitante),
                      style: TdsText.label(12, color: TdsColors.primaryContainer),
                    ),
                  ),
                if (!finalizada && q.futuros.isNotEmpty && q.futurosListos == q.futuros.length)
                  Text('✓ Completos', style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            finalizada ? 'PRONÓSTICOS Y RESULTADOS (${partidos.length})' : 'PARTIDOS EN JUEGO Y POR JUGAR (${partidos.length})',
            style: TdsText.label(11, color: TdsColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (partidos.isEmpty)
            Text(
              finalizada ? 'Este torneo aún no tiene partidos.' : 'No quedan partidos en juego ni por jugar.',
              style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
            )
          else
            _PartidosConBuscador(quiniela: q, partidos: partidos),
        ],
      ),
    );
  }
}

/// Buscador de equipos ("Municipal" o "Municipal vs Comunicaciones") y los partidos: 2 a la vista y el
/// resto con "Ver más". Buscando se muestran todos los que coinciden.
class _PartidosConBuscador extends ConsumerStatefulWidget {
  const _PartidosConBuscador({required this.quiniela, required this.partidos});

  final ResumenQuiniela quiniela;
  final List<Partido> partidos;

  @override
  ConsumerState<_PartidosConBuscador> createState() => _PartidosConBuscadorState();
}

class _PartidosConBuscadorState extends ConsumerState<_PartidosConBuscador> {
  static const _aLaVista = 2;

  final _listaKey = GlobalKey();
  String _busqueda = '';
  bool _verTodos = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quiniela;
    // Cambiar un marcador ya guardado es beneficio PRO/VIP
    final puedeEditar = ref.watch(perfilActualProvider).valueOrNull?.esPro ?? false;
    final coinciden = widget.partidos.where((p) => p.coincideConBusqueda(_busqueda)).toList();
    final buscando = _busqueda.trim().isNotEmpty;
    final ocultos = buscando ? 0 : coinciden.length - _aLaVista;
    final visibles = ocultos > 0 && !_verTodos ? coinciden.take(_aLaVista).toList() : coinciden;

    return Column(
      key: _listaKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TdsBuscador(
          hint: 'Buscar equipo: Equipo A vs Equipo B',
          color: TdsColors.surfaceContainerHigh,
          onChanged: (v) => setState(() => _busqueda = v),
        ),
        const SizedBox(height: 12),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Ningún partido coincide con "${_busqueda.trim()}".',
              style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
            ),
          ),
        for (final p in visibles)
          PronosticoFila(
            key: ValueKey(p.id),
            partido: p,
            pronostico: q.pronosticos[p.id],
            puedeEditar: puedeEditar,
            // Misma acción que Mis pronósticos: guarda en pronosticos (usuario + quiniela + partido)
            onGuardar: q.activa
                ? (p, l, v) => ref
                      .read(quinielasAccionesProvider)
                      .guardarPronostico(quinielaId: q.id, partidoId: p.id, golesLocal: l, golesVisitante: v)
                : null,
          ),
        if (ocultos > 0)
          TdsVerMas(
            ocultos: ocultos,
            abierto: _verTodos,
            onTap: () {
              setState(() => _verTodos = !_verTodos);
              if (!_verTodos) TdsVerMas.regresarA(_listaKey);
            },
          ),
      ],
    );
  }
}

/// Fila del desglose: estado + marcador, mi pronóstico y badge de puntos.
class PronosticoFila extends StatelessWidget {
  const PronosticoFila({super.key, required this.partido, this.pronostico, this.onGuardar, this.puedeEditar = false});

  final Partido partido;
  final Pronostico? pronostico;

  /// Con valor, el partido abierto muestra "Asignar marcador" / "Editar marcador" para poner
  /// los goles ahí mismo. null = solo lectura (historial).
  final GuardarPronostico? onGuardar;

  /// Cuenta PRO/VIP: puede cambiar un marcador ya guardado. Gratis solo lo asigna la primera vez.
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final pr = pronostico;
    final marcador = '${golesTexto(p.golesLocal)} - ${golesTexto(p.golesVisitante)}';
    final partidoTexto = switch (p.estado) {
      EstadoPartido.finalizado || EstadoPartido.enVivo => '${p.local.nombre} $marcador ${p.visitante.nombre}',
      _ => '${p.local.nombre} vs ${p.visitante.nombre}',
    };

    // ¿El signo de mi pronóstico coincide con el marcador actual? (solo para la etiqueta "PARCIAL")
    final acertando =
        pr != null &&
        p.tieneMarcador &&
        signo(pr.golesLocal, pr.golesVisitante) == signo(p.golesLocal!, p.golesVisitante!);
    final fallado = p.estado == EstadoPartido.finalizado && (pr == null || pr.puntos == 0);

    final Widget badge = switch (p.estado) {
      EstadoPartido.finalizado when pr != null && pr.puntos > 0 => _Badge(
        icono: Icons.check_circle,
        texto: '+${pr.puntos} pts',
        fondo: TdsColors.exito,
        color: TdsColors.texto,
      ),
      EstadoPartido.finalizado => const _Badge(icono: Icons.cancel, texto: '0 pts'),
      EstadoPartido.enVivo when pr == null => const _Badge(texto: 'SIN PRONÓSTICO'),
      EstadoPartido.enVivo => _Badge(
        icono: acertando ? Icons.sync : Icons.warning_amber_rounded,
        texto: acertando ? 'PARCIAL' : 'EN RIESGO',
        color: acertando ? TdsColors.primaryContainer : TdsColors.error,
      ),
      EstadoPartido.suspendido => const _Badge(texto: 'SUSPENDIDO'),
      EstadoPartido.futuro => const _Badge(texto: 'PENDIENTE'),
    };

    return Opacity(
      opacity: fallado ? 0.8 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.estado == EstadoPartido.futuro
              ? TdsColors.surfaceContainerHigh.withValues(alpha: 0.6)
              : TdsColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        // El editor va debajo, a todo lo ancho de la fila, para que quepan los campos en celular
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _contenido(p, partidoTexto, pr, fallado, acertando, badge),
            if (onGuardar != null && p.aceptaPronostico) ...[
              const SizedBox(height: 10),
              _EditorMarcador(partido: p, pronostico: pr, onGuardar: onGuardar!, puedeEditar: puedeEditar),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contenido(Partido p, String partidoTexto, Pronostico? pr, bool fallado, bool acertando, Widget badge) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  EstadoPartidoPill(estado: p.estado, fecha: p.fecha),
                  Text(partidoTexto, style: TdsText.label(12)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Tu pronóstico:', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                  _PronosticoChip(pronostico: pr, partido: p, fallado: fallado, acertando: acertando),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }
}

/// Botón "Asignar marcador" / "Editar marcador" que abre, dentro de la misma fila, los campos de goles
/// (local y visitante) con Guardar y Cancelar. Los campos solo aceptan enteros de 0 a 99.
class _EditorMarcador extends StatefulWidget {
  const _EditorMarcador({
    required this.partido,
    required this.pronostico,
    required this.onGuardar,
    required this.puedeEditar,
  });

  final Partido partido;
  final Pronostico? pronostico;
  final GuardarPronostico onGuardar;
  final bool puedeEditar;

  @override
  State<_EditorMarcador> createState() => _EditorMarcadorState();
}

class _EditorMarcadorState extends State<_EditorMarcador> {
  final _local = TextEditingController();
  final _visitante = TextEditingController();
  bool _editando = false;
  bool _guardando = false;

  @override
  void dispose() {
    _local.dispose();
    _visitante.dispose();
    super.dispose();
  }

  void _abrir() {
    // Con marcador previo, los campos llegan con esos valores
    _local.text = widget.pronostico?.golesLocal.toString() ?? '';
    _visitante.text = widget.pronostico?.golesVisitante.toString() ?? '';
    setState(() => _editando = true);
  }

  bool get _completo => _local.text.isNotEmpty && _visitante.text.isNotEmpty;

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final local = int.tryParse(_local.text);
    final visitante = int.tryParse(_visitante.text);
    if (local == null || visitante == null || local < 0 || visitante < 0) {
      Notificacion.advertencia(context, 'Escribe los goles de los dos equipos.', titulo: 'Falta el marcador');
      return;
    }
    // El partido pudo empezar mientras se escribía
    if (!widget.partido.aceptaPronostico) {
      Notificacion.advertencia(context, 'El partido ya comenzó.', titulo: 'Pronósticos cerrados');
      setState(() => _editando = false);
      return;
    }

    setState(() => _guardando = true);
    try {
      await widget.onGuardar(widget.partido, local, visitante);
      if (!mounted) return;
      setState(() => _editando = false);
      Notificacion.exito(context, 'Tu pronóstico quedó guardado: $local - $visitante.', titulo: 'Pronóstico guardado');
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partido;
    final tieneMarcador = widget.pronostico != null;

    if (!_editando) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TdsPillButton(
          icon: tieneMarcador ? Icons.edit_note : Icons.edit_outlined,
          label: tieneMarcador ? 'Editar marcador' : 'Asignar marcador',
          primary: !tieneMarcador,
          // Ya tiene marcador y la cuenta es gratis: en vez de editar, ventanita para suscribirse
          onTap: tieneMarcador && !widget.puedeEditar ? () => mostrarSuscribeteParaEditar(context) : _abrir,
        ),
      );
    }

    Widget equipo(String nombre, TextAlign alineacion) => Expanded(
      child: Text(
        nombre,
        textAlign: alineacion,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TdsText.label(12, color: TdsColors.onSurfaceVariant),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            equipo(p.local.nombre, TextAlign.right),
            const SizedBox(width: 8),
            GolesField(
              controller: _local,
              enabled: !_guardando,
              autofocus: true,
              etiqueta: 'Goles de ${p.local.nombre}',
              onChanged: () => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(':', style: TdsText.stats(22, color: TdsColors.onSurfaceVariant)),
            ),
            GolesField(
              controller: _visitante,
              enabled: !_guardando,
              etiqueta: 'Goles de ${p.visitante.nombre}',
              onChanged: () => setState(() {}),
            ),
            const SizedBox(width: 8),
            equipo(p.visitante.nombre, TextAlign.left),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            TdsPillButton(
              icon: Icons.close,
              label: 'Cancelar',
              onTap: _guardando ? null : () => setState(() => _editando = false),
            ),
            TdsPillButton(
              icon: Icons.save_outlined,
              label: 'Guardar',
              primary: true,
              cargando: _guardando,
              onTap: _completo && !_guardando ? _guardar : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _PronosticoChip extends StatelessWidget {
  const _PronosticoChip({
    required this.pronostico,
    required this.partido,
    required this.fallado,
    required this.acertando,
  });

  final Pronostico? pronostico;
  final Partido partido;
  final bool fallado;
  final bool acertando;

  @override
  Widget build(BuildContext context) {
    final pr = pronostico;
    if (pr == null) return Text('—', style: TdsText.label(12, color: TdsColors.onSurfaceVariant));

    final s = signo(pr.golesLocal, pr.golesVisitante);
    final texto = '${pr.golesLocal}-${pr.golesVisitante} · $s (${nombreSigno(s)})';
    final enVivo = partido.estado == EstadoPartido.enVivo;
    final finalizado = partido.estado == EstadoPartido.finalizado;

    final (fondo, color) = fallado
        ? (TdsColors.surfaceContainerHighest, TdsColors.onSurfaceVariant)
        : enVivo && acertando
            ? (TdsColors.primaryContainer, TdsColors.onPrimary)
            : (enVivo || finalizado)
                ? (TdsColors.primaryContainer.withValues(alpha: 0.2), TdsColors.primaryContainer)
                : (TdsColors.surfaceContainerHighest, TdsColors.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(6)),
      child: Text(
        texto,
        style: TdsText.label(11, color: color).copyWith(
          decoration: fallado ? TextDecoration.lineThrough : null,
          decorationColor: color,
        ),
      ),
    );
  }
}

/// Fila superior: estado de la quiniela, código y fecha de creación.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.quiniela, this.compacta = false});

  final ResumenQuiniela quiniela;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final q = quiniela;
    final proximo = q.proximoPartido;

    final (texto, color, fondo, punto) = switch (q.estado) {
      EstadoQuiniela.enCurso => (
          q.enVivo > 0 ? 'EN CURSO • EN VIVO' : 'EN CURSO',
          TdsColors.primaryContainer,
          TdsColors.surfaceContainerHighest,
          q.enVivo > 0,
        ),
      EstadoQuiniela.porIniciar => (
          'POR INICIAR${proximo == null ? '' : ' • ${Formatos.cuentaRegresiva(proximo.fecha) ?? Formatos.diaHora(proximo.fecha)}'}',
          TdsColors.secondaryContainer,
          TdsColors.secondaryContainer.withValues(alpha: 0.15),
          false,
        ),
      EstadoQuiniela.finalizada => (
          q.torneoActivo ? 'FINALIZADA' : 'FINALIZADA • TORNEO CERRADO',
          TdsColors.onSurfaceVariant,
          TdsColors.surfaceContainerHighest,
          false,
        ),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TdsPill(
          color: fondo,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (punto) ...[TdsDot(color: color, pulse: true), const SizedBox(width: 4)],
              Text(texto, style: TdsText.label(11, color: color, letterSpacing: 0.5)),
            ],
          ),
        ),
        if (!compacta) ...[
          Text('#${q.codigoAcceso}', style: TdsText.label(12, color: TdsColors.onSurfaceVariant)),
          if (q.creadoEn != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 14, color: TdsColors.onSurfaceVariant),
                const SizedBox(width: 2),
                Text('Creada ${Formatos.diaMes(q.creadoEn)}', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
              ],
            ),
        ],
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.titulo,
    required this.valor,
    required this.sufijo,
    this.color = TdsColors.primaryContainer,
    this.resaltada = false,
  });

  final String titulo;
  final String valor;
  final String sufijo;
  final Color color;
  final bool resaltada;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: resaltada
            ? BoxDecoration(
                color: TdsColors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          children: [
            Text(titulo,
                textAlign: TextAlign.center,
                style: TdsText.label(10, color: TdsColors.onSurfaceVariant, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(valor, style: TdsText.stats(24, color: color)),
                  const SizedBox(width: 3),
                  Text(sufijo, style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor, this.color = TdsColors.onSurface});

  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(valor, style: TdsText.label(12, color: color)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.texto,
    this.icono,
    this.color = TdsColors.onSurfaceVariant,
    this.fondo = TdsColors.surfaceContainerHighest,
  });

  final String texto;
  final IconData? icono;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 14, color: color), const SizedBox(width: 4)],
          Text(texto, style: TdsText.label(10, color: color)),
        ],
      ),
    );
  }
}

/// Copia el código de una quiniela al portapapeles y avisa.
void copiarCodigo(BuildContext context, String codigo) {
  Clipboard.setData(ClipboardData(text: codigo));
  Notificacion.exito(context, 'Compártelo para invitar a tus amigos.', titulo: 'Código $codigo copiado');
}
