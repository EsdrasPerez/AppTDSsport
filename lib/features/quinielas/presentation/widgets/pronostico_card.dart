import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../../partidos/domain/partido.dart';
import '../../../partidos/presentation/widgets/detalles_partido.dart';
import '../../../partidos/presentation/widgets/estado_partido_pill.dart';
import '../../domain/quiniela_models.dart';

/// Guarda el pronóstico; lanza excepción si falla.
typedef GuardarPronostico = Future<void> Function(Partido partido, int golesLocal, int golesVisitante);

/// Tarjeta para ingresar pronóstico.
/// Cuenta con auto-avance de campo, auto-guardado con debounce y modo compacto para no duplicar datos.
class PronosticoCard extends StatefulWidget {
  const PronosticoCard({
    super.key,
    required this.partido,
    required this.onGuardar,
    this.pronostico,
    this.compacto = false,
  });

  final Partido partido;
  final Pronostico? pronostico;
  final GuardarPronostico onGuardar;
  final bool compacto;

  @override
  State<PronosticoCard> createState() => _PronosticoCardState();
}

class _PronosticoCardState extends State<PronosticoCard> {
  late final _localController = TextEditingController(text: widget.pronostico?.golesLocal.toString() ?? '');
  late final _visitanteController = TextEditingController(text: widget.pronostico?.golesVisitante.toString() ?? '');
  Timer? _debounceTimer;
  bool _guardando = false;

  bool get _bloqueado => !widget.partido.aceptaPronostico;

  /// Hay cambios sin guardar respecto al pronóstico almacenado.
  bool get _modificado =>
      _localController.text != (widget.pronostico?.golesLocal.toString() ?? '') ||
      _visitanteController.text != (widget.pronostico?.golesVisitante.toString() ?? '');

  bool get _completo => _localController.text.trim().isNotEmpty && _visitanteController.text.trim().isNotEmpty;

  @override
  void didUpdateWidget(PronosticoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final p = widget.pronostico;
    if (p != null && p != oldWidget.pronostico) {
      _localController.text = p.golesLocal.toString();
      _visitanteController.text = p.golesVisitante.toString();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _localController.dispose();
    _visitanteController.dispose();
    super.dispose();
  }

  void _alCambiar() {
    // Si completó local y visitante está vacío, saltar al visitante automáticamente
    if (_localController.text.trim().isNotEmpty && _visitanteController.text.trim().isEmpty) {
      FocusScope.of(context).nextFocus();
    }
    setState(() {});

    _debounceTimer?.cancel();
    if (_completo && _modificado && !_guardando) {
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _completo && _modificado && !_guardando) {
          _guardar(silencioso: true);
        }
      });
    }
  }

  Future<void> _guardar({bool silencioso = false}) async {
    if (!widget.partido.aceptaPronostico) {
      if (!silencioso) {
        Notificacion.advertencia(context, 'El partido ya comenzó.', titulo: 'Pronósticos cerrados');
      }
      return;
    }
    final lStr = _localController.text.trim();
    final vStr = _visitanteController.text.trim();
    if (lStr.isEmpty || vStr.isEmpty) return;
    final local = int.tryParse(lStr);
    final visitante = int.tryParse(vStr);
    if (local == null || visitante == null) return;

    if (!silencioso) FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(widget.partido, local, visitante);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      if (!silencioso) {
        Notificacion.exito(context, 'Tu pronóstico quedó guardado: $local - $visitante.', titulo: 'Pronóstico guardado');
      }
    } catch (e) {
      if (mounted && !silencioso) {
        Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partido = widget.partido;
    final puedeGuardar = !_bloqueado && !_guardando && _completo && _modificado;

    if (widget.compacto) {
      return TdsCard(
        color: TdsColors.superficie,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _bloqueado ? Icons.lock_outline : Icons.sports_score,
                  size: 16,
                  color: _bloqueado ? TdsColors.textoSecundario : TdsColors.acento,
                ),
                const SizedBox(width: 8),
                Text(
                  'TU MARCADOR',
                  style: TdsText.label(
                    12,
                    color: _bloqueado ? TdsColors.textoSecundario : TdsColors.acento,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (_guardando) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: TdsColors.acento),
                  ),
                  const SizedBox(width: 6),
                  Text('Guardando…', style: TdsText.label(11, color: TdsColors.acento)),
                ] else if (_bloqueado) ...[
                  Text('Pronósticos cerrados', style: TdsText.label(11, color: TdsColors.textoTenue)),
                ] else if (widget.pronostico != null && !_modificado) ...[
                  const Icon(Icons.check_circle, size: 14, color: TdsColors.acento),
                  const SizedBox(width: 4),
                  Text('Guardado', style: TdsText.label(11, color: TdsColors.acento)),
                ] else if (_localController.text.isNotEmpty != _visitanteController.text.isNotEmpty) ...[
                  const Icon(Icons.info_outline, size: 13, color: TdsColors.advertencia),
                  const SizedBox(width: 4),
                  Text(
                    _localController.text.isNotEmpty ? 'Falta visitante' : 'Falta local',
                    style: TdsText.label(11, color: TdsColors.advertencia),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: EquipoEscudo(
                    nombre: partido.local.nombre,
                    escudoUrl: partido.local.escudoUrl,
                    size: 28,
                    disposicion: DisposicionEscudo.horizontal,
                  ),
                ),
                GolesField(
                  controller: _localController,
                  enabled: !_bloqueado,
                  etiqueta: 'Goles de ${partido.local.nombre}',
                  onChanged: _alCambiar,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':', style: TdsText.stats(22, color: TdsColors.textoSecundario)),
                ),
                GolesField(
                  controller: _visitanteController,
                  enabled: !_bloqueado,
                  etiqueta: 'Goles de ${partido.visitante.nombre}',
                  onChanged: _alCambiar,
                ),
                Expanded(
                  child: EquipoEscudo(
                    nombre: partido.visitante.nombre,
                    escudoUrl: partido.visitante.escudoUrl,
                    size: 28,
                    disposicion: DisposicionEscudo.horizontalInvertida,
                  ),
                ),
              ],
            ),
            if (puedeGuardar) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TdsPillButton(
                  icon: Icons.check,
                  label: 'Guardar ahora',
                  primary: true,
                  cargando: _guardando,
                  onTap: () => _guardar(silencioso: false),
                ),
              ),
            ],
          ],
        ),
      );
    }

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
              EstadoPartidoPill(partido: partido, estado: partido.estado),
            ],
          ),
          const SizedBox(height: 8),
          DetallesPartido(partido: partido),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: EquipoEscudo(nombre: partido.local.nombre, escudoUrl: partido.local.escudoUrl)),
              GolesField(
                controller: _localController,
                enabled: !_bloqueado,
                etiqueta: 'Goles de ${partido.local.nombre}',
                onChanged: _alCambiar,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TdsText.stats(24, color: TdsColors.onSurfaceVariant)),
              ),
              GolesField(
                controller: _visitanteController,
                enabled: !_bloqueado,
                etiqueta: 'Goles de ${partido.visitante.nombre}',
                onChanged: _alCambiar,
              ),
              Expanded(
                child: EquipoEscudo(nombre: partido.visitante.nombre, escudoUrl: partido.visitante.escudoUrl),
              ),
            ],
          ),
          if (!_bloqueado) ...[
            const SizedBox(height: 12),
            _MarcadoresRapidos(
              onSeleccionar: (local, visitante) {
                _localController.text = local.toString();
                _visitanteController.text = visitante.toString();
                _alCambiar();
              },
            ),
          ],
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
                onTap: puedeGuardar ? () => _guardar(silencioso: false) : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila de chips de marcadores rápidos y frecuentes en el fútbol.
class _MarcadoresRapidos extends StatelessWidget {
  const _MarcadoresRapidos({required this.onSeleccionar});

  final void Function(int local, int visitante) onSeleccionar;

  static const _opciones = [
    (1, 0),
    (2, 1),
    (1, 1),
    (0, 0),
    (0, 1),
    (1, 2),
    (2, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, size: 13, color: TdsColors.acento),
            const SizedBox(width: 4),
            Text(
              'RÁPIDO: Toca para elegir un marcador frecuente',
              style: TdsText.label(10, color: TdsColors.textoSecundario, letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final op in _opciones)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: TdsColors.superficieAlta,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onSeleccionar(op.$1, op.$2);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TdsColors.borde.withValues(alpha: 0.7)),
                        ),
                        child: Text(
                          '${op.$1} - ${op.$2}',
                          style: TdsText.stats(12, color: TdsColors.texto),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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

/// Campo de goles con botones accesibles [-] y [+] para pronosticar fácil sin teclado.
class GolesField extends StatelessWidget {
  const GolesField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.etiqueta,
    this.autofocus = false,
    this.onTap,
    this.mostrarBotones = true,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final String etiqueta;
  final bool autofocus;
  final VoidCallback? onTap;
  final bool mostrarBotones;

  void _decrementar() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    final actual = int.tryParse(controller.text.trim()) ?? 0;
    if (actual > 0) {
      controller.text = (actual - 1).toString();
    } else {
      controller.text = '0';
    }
    onChanged();
  }

  void _incrementar() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    final actual = int.tryParse(controller.text.trim()) ?? -1;
    if (actual < 99) {
      controller.text = (actual + 1).toString();
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (!mostrarBotones) {
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
            style: TdsText.stats(20, color: enabled ? TdsColors.onSurface : TdsColors.onSurfaceVariant),
            decoration: InputDecoration(
              hintText: '-',
              hintStyle: TdsText.stats(20, color: TdsColors.outlineVariant),
              fillColor: enabled ? TdsColors.surfaceContainerHighest : TdsColors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: etiqueta,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón grande [-]
          _BotonStepper(
            icono: Icons.remove,
            enabled: enabled,
            onTap: _decrementar,
            tooltip: 'Menos un gol',
          ),
          const SizedBox(width: 3),
          // Caja de texto central con el marcador
          SizedBox(
            width: 34,
            height: 38,
            child: TextField(
              controller: controller,
              enabled: enabled,
              autofocus: autofocus && enabled,
              onTap: onTap,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              style: TdsText.stats(18, color: enabled ? TdsColors.texto : TdsColors.textoSecundario),
              decoration: InputDecoration(
                hintText: '-',
                hintStyle: TdsText.stats(18, color: TdsColors.textoTenue),
                filled: true,
                fillColor: enabled ? TdsColors.superficieAlta : TdsColors.superficie,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: enabled ? TdsColors.borde : Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: TdsColors.borde),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: TdsColors.acento, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          // Botón grande [+]
          _BotonStepper(
            icono: Icons.add,
            esAcento: true,
            enabled: enabled,
            onTap: _incrementar,
            tooltip: 'Más un gol',
          ),
        ],
      ),
    );
  }
}

class _BotonStepper extends StatelessWidget {
  const _BotonStepper({
    required this.icono,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
    this.esAcento = false,
  });

  final IconData icono;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;
  final bool esAcento;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? (esAcento ? TdsColors.acento.withValues(alpha: 0.18) : TdsColors.superficieAlta)
            : TdsColors.superficie.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 26,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? (esAcento ? TdsColors.acento.withValues(alpha: 0.4) : TdsColors.borde)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              icono,
              size: 16,
              color: enabled
                  ? (esAcento ? TdsColors.acento : TdsColors.texto)
                  : TdsColors.textoTenue,
            ),
          ),
        ),
      ),
    );
  }
}
