import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/widgets/notificacion.dart';
import '../../domain/quiniela_models.dart';

/// Color oficial de la marca WhatsApp.
const colorWhatsApp = Color(0xFF25D366);

/// Genera el texto formateado con emojis para compartir la tabla en WhatsApp.
String formatearTablaWhatsApp(DetalleQuiniela d) {
  final buffer = StringBuffer();
  buffer.writeln('🏆 *TABLA DE POSICIONES*');
  buffer.writeln('⚽ Quiniela: *${d.quiniela.nombre}*');
  buffer.writeln('🏅 Torneo: ${d.quiniela.torneoNombre}');
  buffer.writeln('────────────────────────');

  final maxMostrar = d.posiciones.length;
  for (int i = 0; i < maxMostrar; i++) {
    final pos = d.posiciones[i];
    final icono = switch (pos.lugar) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '🔹',
    };
    final esYo = pos.usuarioId == d.miId ? ' 👈 (Tú)' : '';
    buffer.writeln('$icono ${pos.lugar}° *${pos.nombre}*$esYo — ${pos.puntos} pts');
  }

  buffer.writeln('────────────────────────');
  buffer.writeln('🔑 Código de la quiniela: *${d.quiniela.codigoAcceso}*');
  buffer.writeln('📲 ¡Sigue la tabla en vivo en *TDS Sport*!');
  return buffer.toString();
}

/// Genera el texto para invitar amigos a la quiniela por WhatsApp.
String formatearInvitacionWhatsApp(QuinielaDetalle q) {
  final buffer = StringBuffer();
  buffer.writeln('⚽ *¡ÚNETE A MI QUINIELA!*');
  buffer.writeln('🏆 *${q.nombre}*');
  buffer.writeln('🏅 Torneo: ${q.torneoNombre}');
  buffer.writeln('');
  buffer.writeln('Demuestra cuánto sabes de fútbol y compite con nosotros.');
  buffer.writeln('');
  buffer.writeln('🔑 Código de acceso: *${q.codigoAcceso}*');
  buffer.writeln('');
  buffer.writeln('📲 Entra a *TDS Sport*, ingresa el código y ¡empieza a pronosticar!');
  return buffer.toString();
}

/// Abre WhatsApp directamente con el texto prellenado.
Future<bool> lanzarWhatsApp(String texto) async {
  final urlEncoded = Uri.encodeComponent(texto);
  final uri = Uri.parse('https://wa.me/?text=$urlEncoded');
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched;
  } catch (_) {
    return false;
  }
}

/// Muestra la hoja inferior para previsualizar y enviar la tabla a WhatsApp.
Future<void> mostrarCompartirTablaSheet(BuildContext context, DetalleQuiniela detalle) {
  final textoMensaje = formatearTablaWhatsApp(detalle);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TdsColors.superficie,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _CompartirSheet(
      titulo: 'Compartir Tabla de Posiciones',
      subtitulo: 'Envía el ranking actual al grupo de WhatsApp',
      textoMensaje: textoMensaje,
    ),
  );
}

/// Muestra la hoja inferior para enviar la invitación de la quiniela a WhatsApp.
Future<void> mostrarCompartirInvitacionSheet(BuildContext context, QuinielaDetalle quiniela) {
  final textoMensaje = formatearInvitacionWhatsApp(quiniela);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TdsColors.superficie,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _CompartirSheet(
      titulo: 'Invitar Amigos a la Quiniela',
      subtitulo: 'Comparte el código por WhatsApp para que se unan',
      textoMensaje: textoMensaje,
    ),
  );
}

class _CompartirSheet extends StatelessWidget {
  const _CompartirSheet({
    required this.titulo,
    required this.subtitulo,
    required this.textoMensaje,
  });

  final String titulo;
  final String subtitulo;
  final String textoMensaje;

  Future<void> _enviarWhatsApp(BuildContext context) async {
    HapticFeedback.lightImpact();
    final exito = await lanzarWhatsApp(textoMensaje);
    if (!exito && context.mounted) {
      await Clipboard.setData(ClipboardData(text: textoMensaje));
      if (!context.mounted) return;
      Notificacion.info(
        context,
        'No pudimos abrir WhatsApp directamente, pero el mensaje fue copiado a tu portapapeles. ¡Pégalo en tu chat!',
        titulo: 'Mensaje copiado',
      );
    }
  }

  Future<void> _copiarTexto(BuildContext context) async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: textoMensaje));
    if (context.mounted) {
      Navigator.of(context).pop();
      Notificacion.exito(
        context,
        'Pega el resumen en el chat de tu grupo de amigos o familia.',
        titulo: '¡Copiado al portapapeles!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Píldora de arrastre superior
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TdsColors.borde,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorWhatsApp.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: colorWhatsApp, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: TdsText.headline(17)),
                      const SizedBox(height: 2),
                      Text(subtitulo, style: TdsText.body(12, color: TdsColors.textoSecundario)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Burbuja de previsualización simulando WhatsApp
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TdsColors.superficieAlta,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorWhatsApp.withValues(alpha: 0.35)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  textoMensaje,
                  style: TdsText.body(13, color: TdsColors.texto).copyWith(height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón principal: Enviar por WhatsApp
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorWhatsApp,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _enviarWhatsApp(context),
              icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              label: Text(
                'Enviar por WhatsApp',
                style: TdsText.headline(15, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            // Botón secundario: Copiar al portapapeles
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TdsColors.borde),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _copiarTexto(context),
              icon: const Icon(Icons.copy_rounded, size: 18, color: TdsColors.textoSecundario),
              label: Text(
                'Copiar texto completo',
                style: TdsText.label(13, color: TdsColors.textoSecundario),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
