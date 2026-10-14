import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodigoExitoDialog extends StatelessWidget {
  final String codigo;
  final String nombreQuiniela;
  final String torneoNombre;
  final int limite;
  final VoidCallback? onContinuar;

  const CodigoExitoDialog({
    Key? key,
    required this.codigo,
    required this.nombreQuiniela,
    required this.torneoNombre,
    required this.limite,
    this.onContinuar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de trofeo / éxito
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              '¡Quiniela Creada con Éxito!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Comparte este código con tus amigos para que puedan unirse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta del código generado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.6), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'CÓDIGO DE INVITACIÓN',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        codigo,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Copiar código',
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codigo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.check, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text('¡Código copiado al portapapeles!'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resumen de la quiniela
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetalleFila('Quiniela:', nombreQuiniela),
                  const SizedBox(height: 8),
                  _buildDetalleFila('Torneo:', torneoNombre),
                  const SizedBox(height: 8),
                  _buildDetalleFila('Cupo:', '$limite participantes'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('¡Código copiado al portapapeles!'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onContinuar != null) onContinuar!();
                    },
                    child: const Text(
                      'Listo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleFila(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
