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
import '../providers/quinielas_acciones.dart';

// TODO(decision): D2 — límites de participantes (también se validan en la RPC crear_quiniela).
const limiteMinimo = 2;
const limiteMaximoGratis = 50;
const limiteMaximoPro = 100;

/// Hoja "Crear quiniela" (/quinielas/nueva?torneo=). Las quinielas siempre son de un torneo completo;
/// desde la tarjeta de un partido llega con su torneo ya elegido.
class CrearQuinielaSheet extends ConsumerStatefulWidget {
  const CrearQuinielaSheet({super.key, this.torneoId});

  final String? torneoId;

  @override
  ConsumerState<CrearQuinielaSheet> createState() => _CrearQuinielaSheetState();
}

class _CrearQuinielaSheetState extends ConsumerState<CrearQuinielaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _limiteController = TextEditingController(text: '10');

  late String? _torneoId = widget.torneoId;
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
            torneoId: _torneoId!,
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
        child: _buildFormulario(),
      ),
    );
  }

  Widget _buildFormulario() {
    final torneos = ref.watch(torneosConPartidosProvider);
    final esPro = ref.watch(perfilActualProvider).valueOrNull?.esPro ?? false;
    final maximo = esPro ? limiteMaximoPro : limiteMaximoGratis;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Crear Quiniela', style: TdsText.headline(22)),
          const SizedBox(height: 4),
          Text('Incluye todos los partidos del torneo que elijas.',
              style: TdsText.body(13, color: TdsColors.textoSecundario)),
          const SizedBox(height: 16),
          torneos.when(
            skipLoadingOnRefresh: true,
            loading: () => const Padding(padding: EdgeInsets.all(16), child: CargandoView()),
            error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(torneosConPartidosProvider)),
            data: (lista) => lista.isEmpty
                ? const VacioView(
                    icono: Icons.emoji_events_outlined,
                    texto: 'No hay torneos con partidos',
                    subtitulo: 'Solo se pueden crear quinielas para torneos activos que tienen partidos.',
                    compacto: true,
                  )
                : _selectorTorneo(lista),
          ),
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
      onChanged: (v) => setState(() => _torneoId = v),
      validator: (v) => v == null ? 'Elige un torneo' : null,
    );
  }
}
