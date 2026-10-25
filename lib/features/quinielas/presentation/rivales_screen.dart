import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
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
import '../../perfil/domain/perfil.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../../suscripcion/domain/precios.dart';
import '../domain/etiquetas_puntos.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_acciones.dart';
import '../providers/quinielas_providers.dart';
import 'widgets/pronostico_card.dart';

/// Pronósticos de rivales (plan PRO/VIP): lo que pronosticaron los demás participantes de mis quinielas,
/// antes, durante y después de cada partido. La regla de visibilidad está en la RLS (migración 03).
class RivalesScreen extends ConsumerWidget {
  const RivalesScreen({super.key, this.quinielaId, this.partidoId});

  final String? quinielaId;
  final String? partidoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: const TdsAppBar(titulo: 'PRONÓSTICOS DE RIVALES'),
      body: AsyncValueView(
        value: perfil,
        onReintentar: () => ref.invalidate(perfilActualProvider),
        // Gratis: pantalla bloqueada, sin consultar pronósticos ajenos
        data: (p) => (p?.esPro ?? false)
            ? _RivalesPro(quinielaInicial: quinielaId, partidoInicial: partidoId)
            : const _Bloqueada(),
      ),
    );
  }
}

// =============================================================================
// Usuario gratis
// =============================================================================
class _Bloqueada extends StatelessWidget {
  const _Bloqueada();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Vista previa difuminada: solo formas, sin datos
        Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Column(children: [for (var i = 0; i < 4; i++) const _FilaFantasma()]),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: TdsColors.superficie, shape: BoxShape.circle),
              child: const Icon(Icons.lock, color: TdsColors.acento, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Mira lo que pronosticaron tus rivales', textAlign: TextAlign.center, style: TdsText.headline(24)),
        const SizedBox(height: 8),
        Text(
          'Con PRO ves lo que pronosticaron tus rivales antes, durante y después de cada partido, '
          'y puedes ajustar el tuyo antes de que empiece.',
          textAlign: TextAlign.center,
          style: TdsText.body(14, color: TdsColors.textoSecundario),
        ),
        const SizedBox(height: 24),
        Center(
          child: TdsPillButton(
            icon: Icons.bolt,
            label: 'Hazte PRO · ${Formatos.moneda(precioProMensual)} al mes',
            primary: true,
            onTap: () => context.push(Rutas.suscripcion),
          ),
        ),
      ],
    );
  }
}

class _FilaFantasma extends StatelessWidget {
  const _FilaFantasma();

  @override
  Widget build(BuildContext context) {
    Widget barra(double ancho) => Container(
          width: ancho,
          height: 12,
          decoration: BoxDecoration(color: TdsColors.superficieAlta, borderRadius: BorderRadius.circular(6)),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TdsColors.superficie, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: TdsColors.superficieAlta),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [barra(120), const SizedBox(height: 6), barra(70)])),
          barra(40),
        ],
      ),
    );
  }
}

// =============================================================================
// Usuario PRO / VIP
// =============================================================================
class _RivalesPro extends ConsumerStatefulWidget {
  const _RivalesPro({this.quinielaInicial, this.partidoInicial});

  final String? quinielaInicial;
  final String? partidoInicial;

  @override
  ConsumerState<_RivalesPro> createState() => _RivalesProState();
}

class _RivalesProState extends ConsumerState<_RivalesPro> {
  late String? _quinielaId = widget.quinielaInicial;
  late String? _partidoId = widget.partidoInicial;
  Timer? _sondeo;

  @override
  void initState() {
    super.initState();
    // Partidos EN JUEGO: la lista se actualiza sola cada 60 s
    _sondeo = Timer.periodic(const Duration(seconds: 60), (_) {
      final enVivo = ref.read(misQuinielasProvider).valueOrNull?.any((q) => q.enVivo > 0) ?? false;
      if (enVivo && mounted && (ModalRoute.of(context)?.isCurrent ?? false)) _recargar();
    });
  }

  @override
  void dispose() {
    _sondeo?.cancel();
    super.dispose();
  }

  Future<void> _recargar() async {
    ref
      ..invalidate(misQuinielasProvider)
      ..invalidate(posicionesProvider)
      ..invalidate(pronosticosDePartidoProvider);
    await ref.read(misQuinielasProvider.future);
  }

  /// Próximo partido abierto; si no hay, el que está en vivo; si no, el último finalizado.
  static Partido? _partidoPorDefecto(List<Partido> partidos) {
    final ahora = DateTime.now();
    final proximos = partidos.where((p) => p.estado == EstadoPartido.futuro).toList()
      ..sort((a, b) => (a.fecha ?? ahora).compareTo(b.fecha ?? ahora));
    final abiertos = proximos.where((p) => p.aceptaPronosticoEn(ahora));
    return abiertos.firstOrNull ??
        partidos.where((p) => p.estaEnJuego).firstOrNull ??
        proximos.firstOrNull ??
        (partidos.where((p) => p.estado == EstadoPartido.finalizado).toList()
              ..sort((a, b) => (b.fecha ?? ahora).compareTo(a.fecha ?? ahora)))
            .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final quinielas = ref.watch(misQuinielasProvider);

    return AsyncValueView(
      value: quinielas,
      onReintentar: _recargar,
      data: (todas) {
        if (todas.isEmpty) {
          return VacioView(
            icono: Icons.groups_outlined,
            texto: 'Aún no participas en ninguna quiniela',
            acciones: [
              TdsPillButton(
                icon: Icons.group_add_outlined,
                label: 'Unirse con código',
                primary: true,
                onTap: () => context.push(Rutas.quinielaUnirse),
              ),
            ],
          );
        }

        // Quiniela: la elegida, o la primera activa
        final orden = [...todas.where((q) => q.activa), ...todas.where((q) => !q.activa)];
        final quiniela = orden.where((q) => q.id == _quinielaId).firstOrNull ?? orden.first;

        // Partidos visibles: nunca los suspendidos
        final partidos = quiniela.partidos.where((p) => p.estado != EstadoPartido.suspendido).toList();
        final partido = partidos.where((p) => p.id == _partidoId).firstOrNull ?? _partidoPorDefecto(partidos);

        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              TdsFilterChipsRow(
                chips: [
                  for (final q in orden)
                    TdsFilterChip(
                      texto: q.nombre,
                      activo: q.id == quiniela.id,
                      onTap: () => setState(() {
                        _quinielaId = q.id;
                        _partidoId = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (partido == null)
                const VacioView(icono: Icons.event_busy, texto: 'Esta quiniela no tiene partidos para mostrar')
              else ...[
                _SelectorPartido(
                  partidos: partidos,
                  seleccionado: partido,
                  onChanged: (p) => setState(() => _partidoId = p.id),
                ),
                const SizedBox(height: 16),
                _DetallePartido(quiniela: quiniela, partido: partido),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Selector de partido agrupado en Próximos / En vivo / Finalizados.
class _SelectorPartido extends StatelessWidget {
  const _SelectorPartido({required this.partidos, required this.seleccionado, required this.onChanged});

  final List<Partido> partidos;
  final Partido seleccionado;
  final ValueChanged<Partido> onChanged;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final proximos = partidos.where((p) => !p.estaEnJuego && p.estado == EstadoPartido.futuro).toList()
      ..sort((a, b) => (a.fecha ?? ahora).compareTo(b.fecha ?? ahora));
    final enVivo = partidos.where((p) => p.estaEnJuego).toList();
    final finalizados = partidos.where((p) => p.estado == EstadoPartido.finalizado).toList()
      ..sort((a, b) => (b.fecha ?? ahora).compareTo(a.fecha ?? ahora));

    DropdownMenuItem<String> seccion(String texto) => DropdownMenuItem<String>(
          enabled: false,
          value: '__$texto',
          child: Text(texto.toUpperCase(), style: TdsText.label(11, color: TdsColors.acento, letterSpacing: 1)),
        );
    DropdownMenuItem<String> item(Partido p) => DropdownMenuItem<String>(
          value: p.id,
          child: Text(
            '${p.local.nombre} vs ${p.visitante.nombre} · ${Formatos.diaHora(p.fecha)}',
            overflow: TextOverflow.ellipsis,
          ),
        );

    return DropdownButtonFormField<String>(
      initialValue: seleccionado.id,
      isExpanded: true,
      dropdownColor: TdsColors.superficieAlta,
      decoration: const InputDecoration(labelText: 'Partido', prefixIcon: Icon(Icons.scoreboard_outlined)),
      items: [
        if (proximos.isNotEmpty) ...[seccion('Próximos'), ...proximos.map(item)],
        if (enVivo.isNotEmpty) ...[seccion('En vivo'), ...enVivo.map(item)],
        if (finalizados.isNotEmpty) ...[seccion('Finalizados'), ...finalizados.map(item)],
      ],
      onChanged: (id) {
        final p = partidos.where((p) => p.id == id).firstOrNull;
        if (p != null) onChanged(p);
      },
    );
  }
}

/// Encabezado del partido, resumen de pronósticos, mi pronóstico editable y la lista de participantes.
class _DetallePartido extends ConsumerWidget {
  const _DetallePartido({required this.quiniela, required this.partido});

  final ResumenQuiniela quiniela;
  final Partido partido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posiciones = ref.watch(posicionesProvider(quiniela.id));
    final pronosticos = ref.watch(pronosticosDePartidoProvider((quinielaId: quiniela.id, partidoId: partido.id)));
    final miId = ref.watch(perfilActualProvider).valueOrNull?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EncabezadoPartido(partido: partido),
        const SizedBox(height: 16),
        AsyncValueView(
          value: pronosticos,
          onReintentar: () =>
              ref.invalidate(pronosticosDePartidoProvider((quinielaId: quiniela.id, partidoId: partido.id))),
          cargando: const Padding(padding: EdgeInsets.all(24), child: CargandoView()),
          data: (mapa) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResumenPronosticos(pronosticos: mapa.values.toList()),
              // Ajustar mi pronóstico después de ver a los rivales (mientras el partido lo acepte)
              if (partido.aceptaPronostico) ...[
                const SizedBox(height: 16),
                PronosticoCard(
                  key: ValueKey('${quiniela.id}-${partido.id}'),
                  partido: partido,
                  compacto: true,
                  pronostico: miId == null ? null : mapa[miId],
                  onGuardar: (p, l, v) => ref.read(quinielasAccionesProvider).guardarPronostico(
                      quinielaId: quiniela.id, partidoId: p.id, golesLocal: l, golesVisitante: v),
                ),
              ],
              const SizedBox(height: 20),
              Text('PARTICIPANTES', style: TdsText.label(12, color: TdsColors.textoSecundario, letterSpacing: 1)),
              const SizedBox(height: 8),
              posiciones.when(
                skipLoadingOnRefresh: true,
                loading: () => const Padding(padding: EdgeInsets.all(24), child: CargandoView()),
                error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(posicionesProvider(quiniela.id))),
                data: (lista) {
                  // Yo primero; luego quien sí pronosticó
                  final orden = [...lista]..sort((a, b) {
                      if (a.usuarioId == miId) return -1;
                      if (b.usuarioId == miId) return 1;
                      return (mapa.containsKey(b.usuarioId) ? 1 : 0) - (mapa.containsKey(a.usuarioId) ? 1 : 0);
                    });
                  return Column(
                    children: [
                      for (final pos in orden)
                        _FilaParticipante(
                          posicion: pos,
                          esYo: pos.usuarioId == miId,
                          partido: partido,
                          pronostico: mapa[pos.usuarioId],
                          onTap: () => context.push(Rutas.participante(quiniela.id, pos.usuarioId)),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EncabezadoPartido extends StatelessWidget {
  const _EncabezadoPartido({required this.partido});

  final Partido partido;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final futuro = p.estado == EstadoPartido.futuro;
    final cuenta = Formatos.cuentaRegresiva(p.fecha);

    return TdsCard(
      glow: p.estado == EstadoPartido.enVivo,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  futuro ? (cuenta ?? Formatos.diaHora(p.fecha)) : Formatos.diaHora(p.fecha),
                  style: TdsText.label(12, color: futuro && cuenta != null ? TdsColors.acento : TdsColors.textoSecundario),
                ),
              ),
              EstadoPartidoPill(estado: p.estado),
            ],
          ),
          const SizedBox(height: 8),
          DetallesPartido(partido: p),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: EquipoEscudo(nombre: p.local.nombre, escudoUrl: p.local.escudoUrl, size: 48)),
              futuro
                  ? Text('VS', style: TdsText.stats(26, color: TdsColors.textoSecundario))
                  : Text('${golesTexto(p.golesLocal)} : ${golesTexto(p.golesVisitante)}', style: TdsText.stats(32)),
              Expanded(child: EquipoEscudo(nombre: p.visitante.nombre, escudoUrl: p.visitante.escudoUrl, size: 48)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cuántos eligieron Local / Empate / Visitante y el marcador más repetido.
class _ResumenPronosticos extends StatelessWidget {
  const _ResumenPronosticos({required this.pronosticos});

  final List<Pronostico> pronosticos;

  @override
  Widget build(BuildContext context) {
    final total = pronosticos.length;
    if (total == 0) {
      return TdsCard(
        child: Text('Nadie ha pronosticado este partido todavía.',
            textAlign: TextAlign.center, style: TdsText.body(14, color: TdsColors.textoSecundario)),
      );
    }

    int contar(String s) => pronosticos.where((p) => signo(p.golesLocal, p.golesVisitante) == s).length;
    final (l, x, v) = (contar('1'), contar('X'), contar('2'));

    final frecuencia = <String, int>{};
    for (final p in pronosticos) {
      final k = '${p.golesLocal}-${p.golesVisitante}';
      frecuencia[k] = (frecuencia[k] ?? 0) + 1;
    }
    final masRepetido = frecuencia.entries.reduce((a, b) => b.value > a.value ? b : a);

    Widget segmento(int n, Color color) =>
        n == 0 ? const SizedBox.shrink() : Expanded(flex: n, child: Container(height: 10, color: color));
    Widget leyenda(String texto, int n, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TdsDot(color: color),
            const SizedBox(width: 4),
            Text('$texto ${(n * 100 / total).round()}%', style: TdsText.label(12)),
          ],
        );

    return TdsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$total ${total == 1 ? 'pronóstico' : 'pronósticos'}',
              style: TdsText.label(12, color: TdsColors.textoSecundario)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(children: [
              segmento(l, TdsColors.acento),
              segmento(x, TdsColors.textoSecundario),
              segmento(v, TdsColors.enlace),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              leyenda('Local', l, TdsColors.acento),
              leyenda('Empate', x, TdsColors.textoSecundario),
              leyenda('Visitante', v, TdsColors.enlace),
            ],
          ),
          const SizedBox(height: 10),
          Text('Marcador más repetido: ${masRepetido.key.replaceAll('-', ' - ')} (${masRepetido.value})',
              style: TdsText.body(13, color: TdsColors.textoSecundario)),
        ],
      ),
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  const _FilaParticipante({
    required this.posicion,
    required this.esYo,
    required this.partido,
    required this.pronostico,
    required this.onTap,
  });

  final Posicion posicion;
  final bool esYo;
  final Partido partido;
  final Pronostico? pronostico;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pr = pronostico;

    // Columna derecha según el estado del partido
    final Widget detalle;
    if (pr == null) {
      detalle = Text('No pronosticó', style: TdsText.label(11, color: TdsColors.textoTenue));
    } else {
      switch (partido.estado) {
        case EstadoPartido.enVivo:
          // Solo comparación visual del signo 1/X/2; NO son puntos
          final acierta = partido.tieneMarcador &&
              signo(pr.golesLocal, pr.golesVisitante) == signo(partido.golesLocal!, partido.golesVisitante!);
          detalle = Text(acierta ? 'Va acertando' : 'En riesgo',
              style: TdsText.label(11, color: acierta ? TdsColors.exito : TdsColors.advertencia));
        case EstadoPartido.finalizado:
          detalle = TdsPill(
            color: pr.puntos > 0 ? TdsColors.exito : TdsColors.superficieAlta,
            child: Text(pr.puntos > 0 ? '+${pr.puntos} pts' : '0 pts',
                style: TdsText.label(11, color: pr.puntos > 0 ? TdsColors.texto : TdsColors.textoSecundario)),
          );
        default:
          detalle = Text(pr.actualizadoEn == null ? '' : Formatos.relativo(pr.actualizadoEn),
              style: TdsText.body(11, color: TdsColors.textoSecundario));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: esYo ? TdsColors.acento.withValues(alpha: 0.12) : TdsColors.superficie,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: TdsColors.superficieAlta,
                  child: Text(posicion.nombre.isNotEmpty ? posicion.nombre[0].toUpperCase() : '?',
                      style: TdsText.label(13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(esYo ? '${posicion.nombre} (Tú)' : posicion.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: TdsText.label(14, color: esYo ? TdsColors.acento : TdsColors.texto)),
                      ),
                      if (posicion.plan != PlanUsuario.gratis) ...[
                        const SizedBox(width: 6),
                        TdsPill(
                          color: TdsColors.acento,
                          child: Text(posicion.plan.etiqueta, style: TdsText.label(9, color: TdsColors.sobreAcento)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pr != null) ...[
                  Text('${pr.golesLocal} : ${pr.golesVisitante}', style: TdsText.stats(16)),
                  const SizedBox(width: 10),
                ],
                detalle,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
