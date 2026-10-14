import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../providers/admin_providers.dart';

/// Formatos de torneo (torneos.formato).
const formatosTorneo = ['Liga', 'Eliminación directa', 'Grupos y eliminatoria'];

class AdminTorneos extends ConsumerWidget {
  const AdminTorneos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final torneos = ref.watch(adminTorneosProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo torneo'),
      ),
      body: AsyncValueView(
        value: torneos,
        onReintentar: () => ref.invalidate(adminTorneosProvider),
        data: (lista) => lista.isEmpty
            ? const VacioView(icono: Icons.emoji_events_outlined, texto: 'Aún no hay torneos')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = lista[i];
                  return TdsCard(
                    onTap: () => _editar(context, ref, t),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.nombre, style: TdsText.label(15)),
                              Text(t.formato ?? '', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Switch(
                          value: t.activo,
                          onChanged: (v) => _guardar(context, ref, t.id, t.nombre, t.formato ?? formatosTorneo.first, v),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _guardar(BuildContext context, WidgetRef ref, String? id, String nombre, String formato, bool activo) async {
    try {
      await ref.read(adminAccionesProvider).guardarTorneo(id: id, nombre: nombre, formato: formato, activo: activo);
      if (context.mounted) Notificacion.exito(context, 'Torneo guardado.');
    } catch (e) {
      if (context.mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
    }
  }

  Future<void> _editar(BuildContext context, WidgetRef ref, Torneo? torneo) async {
    final nombre = TextEditingController(text: torneo?.nombre ?? '');
    var formato = formatosTorneo.contains(torneo?.formato) ? torneo!.formato! : formatosTorneo.first;
    var activo = torneo?.activo ?? true;
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(torneo == null ? 'Nuevo torneo' : 'Editar torneo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombre,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: formato,
                  decoration: const InputDecoration(labelText: 'Formato'),
                  items: [for (final f in formatosTorneo) DropdownMenuItem(value: f, child: Text(f))],
                  onChanged: (v) => formato = v ?? formato,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: activo,
                  onChanged: (v) => setState(() => activo = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      await _guardar(context, ref, torneo?.id, nombre.text.trim(), formato, activo);
    }
    nombre.dispose();
  }
}
