import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/tds_buttons.dart';

class CodigoExitoDialog extends StatefulWidget {
  const CodigoExitoDialog({
    super.key,
    required this.codigo,
    required this.nombreQuiniela,
    required this.limite,
    this.torneoNombre,
    this.onContinuar,
  });

  final String codigo;
  final String nombreQuiniela;
  final int limite;
  final String? torneoNombre;
  final VoidCallback? onContinuar;

  @override
  State<CodigoExitoDialog> createState() => _CodigoExitoDialogState();
}

class _CodigoExitoDialogState extends State<CodigoExitoDialog> {
  bool _copiado = false;

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: widget.codigo));
    setState(() => _copiado = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: TdsColors.superficie,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: TdsColors.borde, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: TdsColors.acento.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: TdsColors.acento, width: 2),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: TdsColors.acento,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '¡Quiniela Creada!',
              style: TdsText.headline(24, color: TdsColors.texto),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Comparte este código de acceso con tus amigos para que puedan unirse al torneo.',
              style: TdsText.body(13.5, color: TdsColors.textoSecundario),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: TdsColors.fondo,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: TdsColors.acento.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CÓDIGO DE ACCESO',
                    style: TdsText.label(11, color: TdsColors.textoSecundario)
                        .copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    widget.codigo,
                    style: TdsText.stats(36, color: TdsColors.acento)
                        .copyWith(letterSpacing: 8, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _copiarCodigo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _copiado ? TdsColors.acento : TdsColors.texto,
                      side: BorderSide(
                        color: _copiado ? TdsColors.acento : TdsColors.borde,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    icon: Icon(
                      _copiado ? Icons.check : Icons.copy_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _copiado ? '¡CÓDIGO COPIADO!' : 'COPIAR CÓDIGO',
                      style: TdsText.label(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TdsColors.superficieAlta,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _FilaDetalle(
                    icono: Icons.emoji_events_outlined,
                    etiqueta: 'Quiniela:',
                    valor: widget.nombreQuiniela,
                  ),
                  if (widget.torneoNombre != null && widget.torneoNombre!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _FilaDetalle(
                      icono: Icons.sports_soccer_outlined,
                      etiqueta: 'Torneo:',
                      valor: widget.torneoNombre!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _FilaDetalle(
                    icono: Icons.groups_outlined,
                    etiqueta: 'Límite:',
                    valor: '${widget.limite} participantes',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TdsPillButton(
                icon: Icons.arrow_forward_rounded,
                label: 'Entrar a mi Quiniela',
                primary: true,
                onTap: widget.onContinuar ?? () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  const _FilaDetalle({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: TdsColors.textoSecundario),
        const SizedBox(width: 8),
        Text(etiqueta, style: TdsText.body(13, color: TdsColors.textoSecundario)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            valor,
            style: TdsText.body(13, color: TdsColors.texto).copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
