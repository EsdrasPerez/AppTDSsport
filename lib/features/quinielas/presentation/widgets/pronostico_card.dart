import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../domain/quiniela_models.dart';

/// Guarda el pronóstico; lanza excepción si falla.
typedef GuardarPronostico = Future<void> Function(Partido partido, int golesLocal, int golesVisitante);

/// Tab Pendientes: partido con dos campos de goles para ingresar el pronóstico.
/// Regla de bloqueo: solo editable si el partido está en FUTURO y su hora de inicio no ha llegado.
class PronosticoCard extends StatefulWidget {
  const PronosticoCard({super.key, required this.partido, required this.onGuardar, this.pronostico});

  final Partido partido;
  final Pronostico? pronostico;
  final GuardarPronostico onGuardar;

  @override
  State<PronosticoCard> createState() => _PronosticoCardState();
}

class _PronosticoCardState extends State<PronosticoCard> {
  late final _localController = TextEditingController(text: widget.pronostico?.golesLocal.toString() ?? '');
  late final _visitanteController = TextEditingController(text: widget.pronostico?.golesVisitante.toString() ?? '');
  bool _guardando = false;

  bool get _bloqueado => !widget.partido.aceptaPronostico;

  /// Hay cambios sin guardar respecto al pronóstico almacenado.
  bool get _modificado =>
      _localController.text != (widget.pronostico?.golesLocal.toString() ?? '') ||
      _visitanteController.text != (widget.pronostico?.golesVisitante.toString() ?? '');

  bool get _completo => _localController.text.isNotEmpty && _visitanteController.text.isNotEmpty;

  @override
  void didUpdateWidget(PronosticoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el pronóstico guardado cambió en la base, reflejarlo (los modelos se comparan por valor)
    final p = widget.pronostico;
    if (p != null && p != oldWidget.pronostico) {
      _localController.text = p.golesLocal.toString();
      _visitanteController.text = p.golesVisitante.toString();
    }
  }

  @override
  void dispose() {
    _localController.dispose();
    _visitanteController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(
        widget.partido,
        int.parse(_localController.text),
        int.parse(_visitanteController.text),
      );
      if (mounted) Notificacion.exito(context, 'Tu pronóstico quedó guardado.', titulo: 'Pronóstico guardado');
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partido = widget.partido;
    final puedeGuardar = !_bloqueado && !_guardando && _completo && _modificado;

    return TdsCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: TdsColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  Formatos.diaHora(partido.fecha),
                  style: TdsText.label(12, color: TdsColors.onSurfaceVariant, letterSpacing: 0.5),
                ),
              ),
              EstadoPartidoPill(estado: partido.estado),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: EquipoEscudo(nombre: partido.local.nombre, escudoUrl: partido.local.escudoUrl)),
              GolesField(
                controller: _localController,
                enabled: !_bloqueado,
                etiqueta: 'Goles de ${partido.local.nombre}',
                onChanged: () => setState(() {}),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TdsText.stats(24, color: TdsColors.onSurfaceVariant)),
              ),
              GolesField(
                controller: _visitanteController,
                enabled: !_bloqueado,
                etiqueta: 'Goles de ${partido.visitante.nombre}',
                onChanged: () => setState(() {}),
              ),
              Expanded(
                child: EquipoEscudo(nombre: partido.visitante.nombre, escudoUrl: partido.visitante.escudoUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bloqueado)
            AvisoPronostico(icono: Icons.lock_outline, texto: 'Pronósticos cerrados', color: TdsColors.onSurfaceVariant)
          else if (widget.pronostico != null && !_modificado && !_guardando)
            const AvisoPronostico(icono: Icons.check_circle, texto: 'Pronóstico guardado', color: TdsColors.primaryContainer)
          else
            SizedBox(
              width: double.infinity,
              child: TdsPillButton(
                icon: Icons.save_outlined,
                label: widget.pronostico == null ? 'Guardar pronóstico' : 'Actualizar pronóstico',
                primary: true,
                cargando: _guardando,
                onTap: puedeGuardar ? _guardar : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Ícono + texto centrado ("Pronóstico guardado", "Pronósticos cerrados").
class AvisoPronostico extends StatelessWidget {
  const AvisoPronostico({super.key, required this.icono, required this.texto, required this.color});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 6),
        Text(texto, style: TdsText.label(12, color: color)),
      ],
    );
  }
}

/// Cuenta gratis que toca editar un marcador ya guardado: ventanita para suscribirse (beneficio PRO/VIP).
Future<void> mostrarSuscribeteParaEditar(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogo) => AlertDialog(
      backgroundColor: TdsColors.superficie,
      icon: const Icon(Icons.lock_outline, color: TdsColors.acento),
      title: Text('Suscríbete para editar', textAlign: TextAlign.center, style: TdsText.headline(18)),
      content: Text(
        'Cambiar un marcador que ya guardaste es un beneficio PRO.',
        textAlign: TextAlign.center,
        style: TdsText.body(13, color: TdsColors.textoSecundario),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogo).pop(), child: const Text('Ahora no')),
        TdsPillButton(
          icon: Icons.star_border,
          label: 'Suscribirme',
          primary: true,
          onTap: () {
            Navigator.of(dialogo).pop();
            context.push(Rutas.suscripcion);
          },
        ),
      ],
    ),
  );
}

/// Lápiz de editar de un marcador ya guardado en cuenta gratis: abre la ventanita para suscribirse.
class LapizEditarPremium extends StatelessWidget {
  const LapizEditarPremium({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Editar marcador',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.edit_outlined, size: 18, color: TdsColors.textoSecundario),
      onPressed: () => mostrarSuscribeteParaEditar(context),
    );
  }
}

/// Campo de goles (0..99) de un pronóstico.
class GolesField extends StatelessWidget {
  const GolesField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.etiqueta,
    this.autofocus = false,
    this.onTap,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final String etiqueta;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Semantics(
        label: etiqueta,
        child: TextField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus && enabled,
          onTap: onTap,
          onChanged: (_) => onChanged(),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          style: TdsText.stats(22, color: enabled ? TdsColors.onSurface : TdsColors.onSurfaceVariant),
          decoration: InputDecoration(
            hintText: '-',
            hintStyle: TdsText.stats(22, color: TdsColors.outlineVariant),
            fillColor: enabled ? TdsColors.surfaceContainerHighest : TdsColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
