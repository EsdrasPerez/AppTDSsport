import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../providers/admin_providers.dart';

class AdminEquipos extends ConsumerWidget {
  const AdminEquipos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipos = ref.watch(adminEquiposProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo equipo'),
      ),
      body: AsyncValueView(
        value: equipos,
        onReintentar: () => ref.invalidate(adminEquiposProvider),
        data: (lista) => lista.isEmpty
            ? const VacioView(icono: Icons.shield_outlined, texto: 'Aún no hay equipos')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => TdsCard(
                  onTap: () => _editar(context, ref, lista[i]),
                  child: EquipoEscudo(
                    nombre: lista[i].nombre,
                    escudoUrl: lista[i].escudoUrl,
                    size: 40,
                    tamanoNombre: 15,
                    disposicion: DisposicionEscudo.horizontal,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _editar(BuildContext context, WidgetRef ref, Equipo? equipo) async {
    final resultado = await showDialog<({String nombre, String? escudoUrl})>(
      context: context,
      builder: (_) => _EquipoDialog(equipo: equipo),
    );
    if (resultado == null || !context.mounted) return;

    try {
      await ref
          .read(adminAccionesProvider)
          .guardarEquipo(id: equipo?.id, nombre: resultado.nombre, escudoUrl: resultado.escudoUrl);
      if (context.mounted) Notificacion.exito(context, 'Equipo guardado.');
    } catch (e) {
      if (context.mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
    }
  }
}

class _EquipoDialog extends ConsumerStatefulWidget {
  const _EquipoDialog({this.equipo});

  final Equipo? equipo;

  @override
  ConsumerState<_EquipoDialog> createState() => _EquipoDialogState();
}

class _EquipoDialogState extends ConsumerState<_EquipoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.equipo?.nombre ?? '');
  late String? _escudoUrl = widget.equipo?.escudoUrl;
  bool _subiendo = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _elegirEscudo() async {
    final archivos = await FilePicker.pickFiles(type: FileType.image);
    final f = archivos.firstOrNull;
    if (f == null) return; // canceló

    setState(() => _subiendo = true);
    try {
      final url = await ref.read(adminAccionesProvider).subirEscudo(await f.readAsBytes(), f.name);
      if (mounted) setState(() => _escudoUrl = url);
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo subir el escudo');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.equipo == null ? 'Nuevo equipo' : 'Editar equipo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TdsEscudo(url: _escudoUrl, size: 72),
            const SizedBox(height: 8),
            TdsPillButton(
              icon: Icons.upload_outlined,
              label: 'Subir escudo',
              cargando: _subiendo,
              onTap: _elegirEscudo,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: _subiendo
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, (nombre: _nombre.text.trim(), escudoUrl: _escudoUrl));
                  }
                },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
