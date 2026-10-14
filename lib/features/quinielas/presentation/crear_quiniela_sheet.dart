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
import '../../partidos/providers/partidos_providers.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../domain/quiniela_models.dart';
import '../providers/quinielas_acciones.dart';

// TODO(decision): D2 — límites de participantes (también se validan en la RPC crear_quiniela).
const limiteMinimo = 2;
const limiteMaximoGratis = 50;
const limiteMaximoPro = 100;

/// Hoja "Crear quiniela" (/quinielas/nueva?tipo=&torneo=&partido=).
/// Sin [tipo] empieza eligiendo el tipo; desde la tarjeta de un partido llega ya elegido.
class CrearQuinielaSheet extends ConsumerStatefulWidget {
  const CrearQuinielaSheet({super.key, this.tipo, this.torneoId, this.partidoId});

  final String? tipo;
  final String? torneoId;
  final String? partidoId;

  @override
  ConsumerState<CrearQuinielaSheet> createState() => _CrearQuinielaSheetState();
}

class _CrearQuinielaSheetState extends ConsumerState<CrearQuinielaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _limiteController = TextEditingController(text: '10');

  late TipoQuiniela? _tipo = switch (widget.tipo) {
    'partido' => TipoQuiniela.partido,
    'torneo' => TipoQuiniela.torneo,
    _ => null,
  };
  late String? _torneoId = widget.torneoId;
  late String? _partidoId = widget.partidoId;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _limiteController.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final creada = await ref.read(quinielasAccionesProvider).crear(
            tipo: _tipo!,
            torneoId: _torneoId!,
            partidoId: _tipo == TipoQuiniela.partido ? _partidoId : null,
            nombre: _nombreController.text.trim(),
            limiteUsuarios: int.parse(_limiteController.text),
          );
      if (!mounted) return;
      Notificacion.exito(
        context,
        'Comparte el código ${creada.codigo} para invitar a tus amigos.',
        titulo: 'Quiniela creada',
        accion: SnackBarAction(
          label: 'COPIAR CÓDIGO',
          onPressed: () => Clipboard.setData(ClipboardData(text: creada.codigo)),
        ),
      );
      context.go(Rutas.quiniela(creada.id)); // cierra la hoja y abre la quiniela
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      Notificacion.excepcion(context, e, titulo: 'No se pudo crear la quiniela');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _tipo == null ? _buildElegirTipo() : _buildFormulario(_tipo!),
        ),
      ),
    );
  }

  Widget _buildElegirTipo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Crear Quiniela', style: TdsText.headline(22)),
        const SizedBox(height: 4),
        Text('¿Qué tipo de quiniela quieres crear?', style: TdsText.body(13, color: TdsColors.textoSecundario)),
        const SizedBox(height: 20),
        _TarjetaTipo(
          icono: Icons.emoji_events_outlined,
          titulo: 'Por torneo',
          texto: 'Compite toda la temporada: incluye todos los partidos del torneo.',
          onTap: () => setState(() => _tipo = TipoQuiniela.torneo),
        ),
        const SizedBox(height: 12),
        _TarjetaTipo(
          icono: Icons.sports_soccer,
          titulo: 'Por partido',
          texto: 'Un solo juego: termina cuando acaba el partido.',
          onTap: () => setState(() => _tipo = TipoQuiniela.partido),
        ),
      ],
    );
  }

  Widget _buildFormulario(TipoQuiniela tipo) {
    final torneos = ref.watch(torneosActivosProvider);
    final esPro = ref.watch(perfilActualProvider).valueOrNull?.esPro ?? false;
    final maximo = esPro ? limiteMaximoPro : limiteMaximoGratis;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.tipo == null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Cambiar tipo',
                  onPressed: () => setState(() => _tipo = null),
                ),
              Expanded(
                child: Text(
                  tipo == TipoQuiniela.partido ? 'Quiniela por partido' : 'Quiniela por torneo',
                  style: TdsText.headline(22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          torneos.when(
            skipLoadingOnRefresh: true,
            loading: () => const Padding(padding: EdgeInsets.all(16), child: CargandoView()),
            error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(torneosActivosProvider)),
            data: (lista) => lista.isEmpty
                ? const VacioView(
                    icono: Icons.emoji_events_outlined,
                    texto: 'No hay torneos activos',
                    subtitulo: 'Solo se pueden crear quinielas para torneos activos.',
                    compacto: true,
                  )
                : _selectorTorneo(lista),
          ),
          if (tipo == TipoQuiniela.partido && _torneoId != null) ...[
            const SizedBox(height: 16),
            _SelectorPartido(
              torneoId: _torneoId!,
              valor: _partidoId,
              onChanged: (v) => setState(() => _partidoId = v),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreController,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre de la quiniela',
              prefixIcon: Icon(Icons.emoji_events_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _limiteController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Límite de participantes',
              helperText: 'Entre $limiteMinimo y $maximo${esPro ? '' : ' (hasta $limiteMaximoPro con PRO)'}',
              prefixIcon: const Icon(Icons.groups_outlined),
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < limiteMinimo) return 'Mínimo $limiteMinimo participantes';
              if (n > maximo) return 'Máximo $maximo participantes';
              return null;
            },
          ),
          const SizedBox(height: 24),
          TdsPillButton(
            icon: Icons.add_circle_outline,
            label: 'Crear Quiniela',
            primary: true,
            cargando: _guardando,
            onTap: (torneos.valueOrNull?.isNotEmpty ?? false) ? _crear : null,
          ),
        ],
      ),
    );
  }

  Widget _selectorTorneo(List<Torneo> torneos) {
    // Si el torneo preseleccionado ya no está activo, se descarta
    final valido = torneos.any((t) => t.id == _torneoId) ? _torneoId : null;
    return DropdownButtonFormField<String>(
      initialValue: valido,
      isExpanded: true,
      dropdownColor: TdsColors.superficieAlta,
      decoration: const InputDecoration(labelText: 'Torneo', prefixIcon: Icon(Icons.sports_soccer)),
      items: [
        for (final t in torneos) DropdownMenuItem(value: t.id, child: Text(t.nombre, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) => setState(() {
        _torneoId = v;
        _partidoId = null;
      }),
      validator: (v) => v == null ? 'Elige un torneo' : null,
    );
  }
}

/// Partidos del torneo que todavía aceptan pronóstico (FUTURO y la hora no ha llegado).
class _SelectorPartido extends ConsumerWidget {
  const _SelectorPartido({required this.torneoId, required this.valor, required this.onChanged});

  final String torneoId;
  final String? valor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidos = ref.watch(partidosProvider(torneoId));

    return partidos.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(padding: EdgeInsets.all(16), child: CargandoView()),
      error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(partidosProvider(torneoId))),
      data: (lista) {
        final abiertos = lista.where((p) => p.aceptaPronostico).toList();
        if (abiertos.isEmpty) {
          return const VacioView(
            icono: Icons.event_busy,
            texto: 'Este torneo no tiene partidos por jugar',
            compacto: true,
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: abiertos.any((p) => p.id == valor) ? valor : null,
          isExpanded: true,
          dropdownColor: TdsColors.superficieAlta,
          decoration: const InputDecoration(labelText: 'Partido', prefixIcon: Icon(Icons.scoreboard_outlined)),
          items: [
            for (final p in abiertos)
              DropdownMenuItem(
                value: p.id,
                child: Text('${p.local.nombre} vs ${p.visitante.nombre} · ${Formatos.diaHora(p.fecha)}',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Elige un partido' : null,
        );
      },
    );
  }
}

class _TarjetaTipo extends StatelessWidget {
  const _TarjetaTipo({required this.icono, required this.titulo, required this.texto, required this.onTap});

  final IconData icono;
  final String titulo;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TdsCard(
      color: TdsColors.superficieAlta,
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: TdsColors.acento.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icono, color: TdsColors.acento, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TdsText.headline(20)),
                const SizedBox(height: 2),
                Text(texto, style: TdsText.body(13, color: TdsColors.textoSecundario)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: TdsColors.textoSecundario),
        ],
      ),
    );
  }
}
