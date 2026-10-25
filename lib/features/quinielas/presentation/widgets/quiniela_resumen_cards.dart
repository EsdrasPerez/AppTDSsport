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
import '../../../partidos/presentation/widgets/detalles_partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../../perfil/providers/perfil_providers.dart';
import '../../domain/etiquetas_puntos.dart';
import '../../domain/quiniela_models.dart';
import '../../providers/quinielas_acciones.dart';
import '../../providers/quinielas_providers.dart';
import 'pronostico_card.dart';
import 'resultado_quiniela_badge.dart';

/// Card grande y moderna de Mis Quinielas: métricas, avance, avatares y banner de pronóstico directo.
class QuinielaDestacadaCard extends ConsumerWidget {
  const QuinielaDestacadaCard({super.key, required this.quiniela, this.miId});

  final ResumenQuiniela quiniela;

  /// Para la etiqueta "Creada por ti" y el "(tú)" de participantes.
  final String? miId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quiniela;
    final pctAvance = (q.avance * 100).round();
    final finalizada = !q.activa;
    final ahora = DateTime.now();
    final pendientes = q.pendientesDePronosticar(ahora);
    final esCreador = q.esCreador(miId);

    return TdsCard(
      glow: q.activa && pendientes > 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(Rutas.quiniela(q.id, soloLectura: finalizada)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Superior: Estado + Badges + Código interactivo + Opciones
              Row(
                children: [
                  Expanded(
                    child: Wrap(
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
                            color: TdsColors.secondaryContainer.withValues(alpha: 0.15),
                            child: Text(
                              'CREADA POR TI',
                              style: TdsText.label(10, color: TdsColors.secondaryContainer),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón chip para copiar el código con 1 toque
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => copiarCodigo(context, q.codigoAcceso),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: TdsColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 12, color: TdsColors.textoSecundario),
                          const SizedBox(width: 5),
                          Text('#${q.codigoAcceso}', style: TdsText.label(11, color: TdsColors.texto)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: TdsColors.textoSecundario),
                    tooltip: 'Opciones de la quiniela',
                    color: TdsColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (opcion) async {
                      if (opcion == 'eliminar') {
                        final confirmado = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('¿Eliminar "${q.nombre}"?'),
                            content: Text(
                              'Esta acción es permanente e irreversible. Se eliminará la quiniela y los pronósticos de todos los participantes (${q.participantes} miembros).',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: TdsColors.error),
                                child: const Text('Sí, eliminar definitivamente'),
                              ),
                            ],
                          ),
                        );
                        if (confirmado == true && context.mounted) {
                          try {
                            await ref.read(quinielasAccionesProvider).eliminar(q.id);
                            if (context.mounted) Notificacion.info(context, 'La quiniela "${q.nombre}" fue eliminada.');
                          } catch (e) {
                            if (context.mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo eliminar');
                          }
                        }
                      } else if (opcion == 'salir') {
                        final confirmado = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('¿Salirte de "${q.nombre}"?'),
                            content: const Text(
                              'Dejarás de competir en esta quiniela y se borrarán tus puntos y pronósticos en ella.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Seguir en la quiniela'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: TdsColors.error),
                                child: const Text('Sí, salirme'),
                              ),
                            ],
                          ),
                        );
                        if (confirmado == true && context.mounted) {
                          try {
                            await ref.read(quinielasAccionesProvider).salir(q.id);
                            if (context.mounted) Notificacion.info(context, 'Has salido de la quiniela "${q.nombre}".');
                          } catch (e) {
                            if (context.mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo salir');
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (esCreador)
                        PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: TdsColors.error, size: 18),
                              const SizedBox(width: 8),
                              Text('Eliminar quiniela', style: TdsText.label(13, color: TdsColors.error)),
                            ],
                          ),
                        )
                      else
                        PopupMenuItem(
                          value: 'salir',
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, color: TdsColors.advertencia, size: 18),
                              const SizedBox(width: 8),
                              Text('Salirme de la quiniela', style: TdsText.label(13, color: TdsColors.advertencia)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nombre de la Quiniela y Torneo
              Text(q.nombre, style: TdsText.headline(22).copyWith(height: 1.15)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 14, color: TdsColors.textoSecundario),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      q.torneoNombre,
                      style: TdsText.body(13, color: TdsColors.textoSecundario),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Panel de Métricas: Posición, Puntos, Aciertos
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: TdsColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(
                  children: [
                    _Metrica(
                      titulo: 'TU POSICIÓN',
                      valor: '#${q.lugar}',
                      sufijo: '/ ${q.participantes}',
                      color: q.lugar == 1 ? TdsColors.acento : TdsColors.secondaryContainer,
                      resaltada: q.lugar <= 3,
                    ),
                    _Metrica(
                      titulo: 'PUNTOS',
                      valor: '${q.puntos}',
                      sufijo: 'pts',
                      color: TdsColors.texto,
                    ),
                    _Metrica(
                      titulo: 'ACIERTOS',
                      valor: '${q.aciertos}',
                      sufijo: '/ ${q.finalizados.length} jug.',
                      color: TdsColors.texto,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Avance de la Quiniela
              Row(
                children: [
                  Expanded(
                    child: Text('Progreso del torneo', style: TdsText.label(11, color: TdsColors.textoSecundario)),
                  ),
                  Text(
                    '$pctAvance% (${q.finalizados.length} de ${q.totalPartidos} jugados)',
                    style: TdsText.label(11, color: TdsColors.textoSecundario),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: q.avance,
                  minHeight: 6,
                  backgroundColor: TdsColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    q.avance >= 1.0 ? TdsColors.exito : TdsColors.acento,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Participantes en formato compacto con avatares apilados
              _AvataresParticipantes(quiniela: q, miId: miId),
              const SizedBox(height: 14),

              // Callout de Acción Inteligente
              if (!finalizada && pendientes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TdsColors.advertencia.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TdsColors.advertencia.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: TdsColors.advertencia.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 16, color: TdsColors.advertencia),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$pendientes ${pendientes == 1 ? 'partido pendiente' : 'partidos pendientes'}',
                              style: TdsText.label(13, color: TdsColors.texto),
                            ),
                            Text(
                              q.proximoPartido != null
                                  ? 'Cierra ${Formatos.cuentaRegresiva(q.proximoPartido!.fecha) ?? Formatos.diaHora(q.proximoPartido!.fecha)}'
                                  : 'Asigna tus marcadores',
                              style: TdsText.body(11, color: TdsColors.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                      TdsPillButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Asignar marcadores',
                        primary: true,
                        onTap: () => context.push(Rutas.quiniela(q.id)),
                      ),
                    ],
                  ),
                )
              else if (!finalizada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TdsColors.exito.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TdsColors.exito.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: TdsColors.exito),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Todos tus pronósticos listos (${q.futurosListos} asignados)',
                          style: TdsText.label(12, color: TdsColors.exito),
                        ),
                      ),
                      Text(
                        'Ver quiniela ➔',
                        style: TdsText.label(12, color: TdsColors.acento),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TdsColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ResultadoQuinielaBadge(
                        resultado: q.resultado,
                        lugar: q.lugar,
                        total: q.participantes,
                        empate: q.empateEnPrimero,
                      ),
                      const Spacer(),
                      Text(
                        'Ver resultados finales ➔',
                        style: TdsText.label(12, color: TdsColors.textoSecundario),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
    final enVivo = p.estaEnJuego;
    final partidoTexto = enVivo || p.estado == EstadoPartido.finalizado
        ? '${p.local.nombre} $marcador ${p.visitante.nombre}'
        : '${p.local.nombre} vs ${p.visitante.nombre}';

    // ¿El signo de mi pronóstico coincide con el marcador actual? (solo para la etiqueta "PARCIAL")
    final acertando =
        pr != null &&
        p.tieneMarcador &&
        signo(pr.golesLocal, pr.golesVisitante) == signo(p.golesLocal!, p.golesVisitante!);
    final fallado = p.estado == EstadoPartido.finalizado && (pr == null || pr.puntos == 0);

    final Widget badge = switch (p.estado) {
      _ when enVivo && pr == null => const _Badge(texto: 'SIN PRONÓSTICO'),
      _ when enVivo => _Badge(
        icono: acertando ? Icons.sync : Icons.warning_amber_rounded,
        texto: acertando ? 'PARCIAL' : 'EN RIESGO',
        color: acertando ? TdsColors.primaryContainer : TdsColors.error,
      ),
      EstadoPartido.enVivo when pr == null => const _Badge(texto: 'SIN PRONÓSTICO'),
      EstadoPartido.enVivo => _Badge(
        icono: acertando ? Icons.sync : Icons.warning_amber_rounded,
        texto: acertando ? 'PARCIAL' : 'EN RIESGO',
        color: acertando ? TdsColors.primaryContainer : TdsColors.error,
      ),
      EstadoPartido.finalizado when pr != null && pr.puntos > 0 => _Badge(
        icono: Icons.check_circle,
        texto: '+${pr.puntos} pts',
        fondo: TdsColors.exito,
        color: TdsColors.texto,
      ),
      EstadoPartido.finalizado => const _Badge(icono: Icons.cancel, texto: '0 pts'),
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
              const SizedBox(height: 4),
              DetallesPartido(partido: p),
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
    final enVivo = partido.estaEnJuego;
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

/// Card del panel principal: nombre, métricas y los partidos a los que ya les asigné marcador.
class QuinielaPanelCard extends StatelessWidget {
  const QuinielaPanelCard({super.key, required this.quiniela, this.maxPartidos = 3});

  final ResumenQuiniela quiniela;
  final int maxPartidos;

  @override
  Widget build(BuildContext context) {
    final q = quiniela;
    final jugables = q.partidos.where((p) => p.estado != EstadoPartido.suspendido);
    // En juego y por jugar primero; luego los ya jugados, del más reciente al más antiguo.
    final conMarcador = [
      ...q.porJugar.where((p) => q.pronosticos.containsKey(p.id)),
      ...q.finalizados.reversed.where((p) => q.pronosticos.containsKey(p.id)),
    ];
    final restantes = conMarcador.length - maxPartidos;

    return TdsCard.modulo(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(Rutas.quiniela(q.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Cabecera(quiniela: q, compacta: true),
                      const SizedBox(height: 6),
                      Text(q.nombre, style: TdsText.headline(18)),
                      Text(q.torneoNombre, style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: TdsColors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _Dato(titulo: 'Con marcador', valor: '${conMarcador.length} de ${jugables.length}'),
                  _Dato(
                    titulo: 'Posición',
                    valor: '#${q.lugar} de ${q.participantes}',
                    color: TdsColors.secondaryContainer,
                  ),
                  _Dato(titulo: 'Puntos', valor: '${q.puntos} pts', color: TdsColors.primaryContainer),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (conMarcador.isEmpty)
              Text(
                'Aún no has asignado goles. Toca para hacer tus pronósticos.',
                style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
              )
            else ...[
              Text('PARTIDOS CON TU MARCADOR', style: TdsText.label(11, color: TdsColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              for (final p in conMarcador.take(maxPartidos))
                _MarcadorAsignado(partido: p, pronostico: q.pronosticos[p.id]!),
              if (restantes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('y $restantes más ➔', style: TdsText.label(12, color: TdsColors.primaryContainer)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Participantes en formato compacto con avatares circulares superpuestos (Sleek Stack).
class _AvataresParticipantes extends ConsumerWidget {
  const _AvataresParticipantes({required this.quiniela, this.miId});

  final ResumenQuiniela quiniela;
  final String? miId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(posicionesProvider(quiniela.id)).when(
          skipLoadingOnRefresh: true,
          loading: () => const SizedBox(height: 28),
          error: (_, _) => Text(
            '${quiniela.participantes} jugadores',
            style: TdsText.body(12, color: TdsColors.textoSecundario),
          ),
          data: (posiciones) {
            if (posiciones.isEmpty) return const SizedBox.shrink();
            final visibles = posiciones.take(4).toList();
            final yo = posiciones.where((p) => p.usuarioId == miId).firstOrNull;
            final voyGanando = yo != null && yo.lugar == 1;

            return Row(
              children: [
                SizedBox(
                  height: 28,
                  width: 28.0 + (visibles.length - 1) * 18.0,
                  child: Stack(
                    children: [
                      for (var i = 0; i < visibles.length; i++)
                        Positioned(
                          left: i * 18.0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: visibles[i].usuarioId == miId
                                  ? TdsColors.acento
                                  : TdsColors.superficieAlta,
                              border: Border.all(color: TdsColors.superficie, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              visibles[i].nombre.isEmpty ? '?' : visibles[i].nombre[0].toUpperCase(),
                              style: TdsText.label(
                                11,
                                color: visibles[i].usuarioId == miId ? TdsColors.sobreAcento : TdsColors.texto,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${posiciones.length} / ${quiniela.limiteUsuarios} jugadores',
                    style: TdsText.body(12, color: TdsColors.textoSecundario),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (voyGanando)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TdsColors.acento.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: TdsColors.acento.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text('Lideras la tabla', style: TdsText.label(10, color: TdsColors.acento)),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
  }
}


/// Quiénes están unidos a la quiniela (detalle), en orden de posición.
/// Se marca al creador con una corona y a mí con "(tú)".
class ParticipantesQuiniela extends StatelessWidget {
  const ParticipantesQuiniela({
    super.key,
    required this.posiciones,
    required this.creadorId,
    required this.limiteUsuarios,
    this.miId,
  });

  final List<Posicion> posiciones;
  final String creadorId;
  final int limiteUsuarios;
  final String? miId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PARTICIPANTES (${posiciones.length} / $limiteUsuarios)',
          style: TdsText.label(11, color: TdsColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in posiciones)
              _ChipParticipante(
                nombre: p.usuarioId == miId ? '${p.nombre} (tú)' : p.nombre,
                creador: p.usuarioId == creadorId,
                yo: p.usuarioId == miId,
              ),
          ],
        ),
      ],
    );
  }
}

class _ChipParticipante extends StatelessWidget {
  const _ChipParticipante({required this.nombre, required this.creador, required this.yo});

  final String nombre;
  final bool creador;
  final bool yo;

  @override
  Widget build(BuildContext context) {
    final color = yo ? TdsColors.primaryContainer : TdsColors.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(color: TdsColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(nombre.isEmpty ? '?' : nombre[0].toUpperCase(), style: TdsText.label(10, color: color)),
          ),
          const SizedBox(width: 6),
          Text(nombre, style: TdsText.label(12, color: color)),
          if (creador) ...[
            const SizedBox(width: 4),
            const Icon(Icons.workspace_premium, size: 14, color: TdsColors.secondaryContainer),
          ],
        ],
      ),
    );
  }
}

/// "Local 2 - 1 Visitante" con mi marcador; a la derecha la fecha o los puntos si ya se jugó.
class _MarcadorAsignado extends StatelessWidget {
  const _MarcadorAsignado({required this.partido, required this.pronostico});

  final Partido partido;
  final Pronostico pronostico;

  @override
  Widget build(BuildContext context) {
    final finalizado = partido.estado == EstadoPartido.finalizado;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${partido.local.nombre}  '),
                TextSpan(
                  text: '${pronostico.golesLocal} - ${pronostico.golesVisitante}',
                  style: TdsText.label(13, color: TdsColors.primaryContainer),
                ),
                TextSpan(text: '  ${partido.visitante.nombre}'),
              ]),
              style: TdsText.body(13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            finalizado ? '+${pronostico.puntos} pts' : Formatos.diaHora(partido.fecha),
            style: TdsText.label(
              11,
              color: finalizado && pronostico.puntos > 0 ? TdsColors.primaryContainer : TdsColors.onSurfaceVariant,
            ),
          ),
        ],
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
