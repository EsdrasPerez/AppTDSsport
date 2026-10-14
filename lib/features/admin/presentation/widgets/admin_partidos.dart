import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../../partidos/providers/partidos_providers.dart';
import '../../providers/admin_providers.dart';

/// Partidos por torneo: crear, cambiar estado y capturar el marcador.
class AdminPartidos extends ConsumerStatefulWidget {
  const AdminPartidos({super.key});

  @override
  ConsumerState<AdminPartidos> createState() => _AdminPartidosState();
}

class _AdminPartidosState extends ConsumerState<AdminPartidos> {
  String? _torneoId;

  @override
  Widget build(BuildContext context) {
    final torneos = ref.watch(adminTorneosProvider);

    return AsyncValueView(
      value: torneos,
      onReintentar: () => ref.invalidate(adminTorneosProvider),
      data: (lista) {
        if (lista.isEmpty) return const VacioView(icono: Icons.emoji_events_outlined, texto: 'Primero crea un torneo');
        final torneoId = lista.any((t) => t.id == _torneoId) ? _torneoId! : lista.first.id;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _crear(torneoId),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo partido'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  initialValue: torneoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Torneo', prefixIcon: Icon(Icons.emoji_events_outlined)),
                  items: [
                    for (final t in lista)
                      DropdownMenuItem(value: t.id, child: Text('${t.nombre}${t.activo ? '' : ' (inactivo)'}')),
                  ],
                  onChanged: (v) => setState(() => _torneoId = v),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _ListaPartidos(torneoId: torneoId)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _crear(String torneoId) async {
    final datos = await showModalBottomSheet<({String local, String visitante, DateTime fecha})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NuevoPartidoSheet(),
    );
    if (datos == null || !mounted) return;
    try {
      await ref.read(adminAccionesProvider).crearPartido(
            torneoId: torneoId,
            localId: datos.local,
            visitanteId: datos.visitante,
            fecha: datos.fecha,
          );
      if (mounted) Notificacion.exito(context, 'Partido creado.');
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo crear el partido');
    }
  }
}

class _ListaPartidos extends ConsumerWidget {
  const _ListaPartidos({required this.torneoId});

  final String torneoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidos = ref.watch(partidosProvider(torneoId));

    return AsyncValueView(
      value: partidos,
      onReintentar: () => ref.invalidate(partidosProvider(torneoId)),
      data: (lista) => lista.isEmpty
          ? const VacioView(icono: Icons.sports_soccer_outlined, texto: 'Este torneo no tiene partidos')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = lista[i];
                return TdsCard(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _EditarPartidoSheet(partido: p),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.local.nombre} vs ${p.visitante.nombre}', style: TdsText.label(14)),
                            Text(Formatos.diaHora(p.fecha), style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text('${golesTexto(p.golesLocal)} - ${golesTexto(p.golesVisitante)}', style: TdsText.stats(18)),
                      const SizedBox(width: 12),
                      EstadoPartidoPill(estado: p.estado),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EditarPartidoSheet extends ConsumerStatefulWidget {
  const _EditarPartidoSheet({required this.partido});

  final Partido partido;

  @override
  ConsumerState<_EditarPartidoSheet> createState() => _EditarPartidoSheetState();
}

class _EditarPartidoSheetState extends ConsumerState<_EditarPartidoSheet> {
  late EstadoPartido _estado = widget.partido.estado;
  late final _local = TextEditingController(text: widget.partido.golesLocal?.toString() ?? '');
  late final _visitante = TextEditingController(text: widget.partido.golesVisitante?.toString() ?? '');
  bool _guardando = false;

  @override
  void dispose() {
    _local.dispose();
    _visitante.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final gl = int.tryParse(_local.text);
    final gv = int.tryParse(_visitante.text);

    if (_estado == EstadoPartido.finalizado) {
      final yaFinalizado = widget.partido.estado == EstadoPartido.finalizado;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(yaFinalizado ? 'Corregir resultado' : 'Finalizar partido'),
          content: Text(
            'Marcador final: ${widget.partido.local.nombre} ${gl ?? '?'} - ${gv ?? '?'} ${widget.partido.visitante.nombre}.\n\n'
            'Se calcularán los puntos de todos los pronósticos de este partido.'
            '${yaFinalizado ? '\n\nEl partido ya estaba finalizado: confirma con el equipo que la función de puntos recalcula al corregir.' : ''}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(adminAccionesProvider).actualizarPartido(
            partidoId: widget.partido.id,
            estado: _estado,
            golesLocal: gl,
            golesVisitante: gv,
          );
      if (!mounted) return;
      Notificacion.exito(context, 'Partido actualizado.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      Notificacion.excepcion(context, e, titulo: 'No se pudo actualizar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partido;
    final conGoles = _estado == EstadoPartido.enVivo || _estado == EstadoPartido.finalizado;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${p.local.nombre} vs ${p.visitante.nombre}', style: TdsText.headline(20)),
          Text(Formatos.diaHora(p.fecha), style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          DropdownButtonFormField<EstadoPartido>(
            initialValue: _estado,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: EstadoPartido.futuro, child: Text('FUTURO')),
              DropdownMenuItem(value: EstadoPartido.enVivo, child: Text('EN JUEGO')),
              DropdownMenuItem(value: EstadoPartido.finalizado, child: Text('FINALIZADO')),
              DropdownMenuItem(value: EstadoPartido.suspendido, child: Text('SUSPENDIDO')),
            ],
            onChanged: (v) => setState(() => _estado = v ?? _estado),
          ),
          if (conGoles) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _goles(_local, 'Goles ${p.local.nombre}')),
                const SizedBox(width: 12),
                Expanded(child: _goles(_visitante, 'Goles ${p.visitante.nombre}')),
              ],
            ),
          ],
          const SizedBox(height: 24),
          TdsPillButton(icon: Icons.save_outlined, label: 'Guardar', primary: true, cargando: _guardando, onTap: _guardar),
        ],
      ),
    );
  }

  Widget _goles(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
        decoration: InputDecoration(labelText: label),
      );
}

class _NuevoPartidoSheet extends ConsumerStatefulWidget {
  const _NuevoPartidoSheet();

  @override
  ConsumerState<_NuevoPartidoSheet> createState() => _NuevoPartidoSheetState();
}

class _NuevoPartidoSheetState extends ConsumerState<_NuevoPartidoSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _local;
  String? _visitante;
  DateTime? _fecha;

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: ahora.add(const Duration(days: 1)),
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (hora == null) return;
    setState(() => _fecha = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute));
  }

  @override
  Widget build(BuildContext context) {
    final equipos = ref.watch(adminEquiposProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: AsyncValueView(
        value: equipos,
        onReintentar: () => ref.invalidate(adminEquiposProvider),
        data: (lista) => Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nuevo partido', style: TdsText.headline(20)),
              const SizedBox(height: 16),
              _selector('Local', lista, _local, (v) => setState(() => _local = v)),
              const SizedBox(height: 12),
              _selector('Visitante', lista, _visitante, (v) => setState(() => _visitante = v)),
              const SizedBox(height: 12),
              FormField<DateTime>(
                validator: (_) => _fecha == null
                    ? 'Elige fecha y hora'
                    : (_fecha!.isAfter(DateTime.now()) ? null : 'La fecha debe ser futura'),
                builder: (estado) => InkWell(
                  onTap: _elegirFecha,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha y hora',
                      prefixIcon: const Icon(Icons.event),
                      errorText: estado.errorText,
                    ),
                    child: Text(_fecha == null ? 'Seleccionar' : '${Formatos.fecha(_fecha)} ${Formatos.hora(_fecha)}'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TdsPillButton(
                icon: Icons.add,
                label: 'Crear partido',
                primary: true,
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, (local: _local!, visitante: _visitante!, fecha: _fecha!));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selector(String label, List<Equipo> equipos, String? valor, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.shield_outlined)),
      items: [for (final e in equipos) DropdownMenuItem(value: e.id, child: Text(e.nombre))],
      onChanged: onChanged,
      validator: (v) {
        if (v == null) return 'Elige un equipo';
        if (_local != null && _local == _visitante) return 'Local y visitante deben ser distintos';
        return null;
      },
    );
  }
}
