import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';

/// Escudo circular de un equipo; muestra un ícono si no hay imagen.
class TdsEscudo extends StatelessWidget {
  const TdsEscudo({super.key, required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final interior = size * 0.7;
    final fallback = Icon(Icons.shield_outlined, size: interior * 0.8, color: TdsColors.onSurfaceVariant);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: TdsColors.surfaceContainerHigh, shape: BoxShape.circle),
      child: (url == null || url!.isEmpty)
          ? fallback
          : ClipOval(
              child: Image.network(
                url!,
                width: interior,
                height: interior,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }
}

enum DisposicionEscudo { vertical, horizontal, horizontalInvertida }

/// Escudo + nombre del equipo (y un subtítulo opcional, p. ej. "Local").
/// - vertical: escudo arriba, nombre abajo (cards con marcador).
/// - horizontal: escudo a la izquierda.
/// - horizontalInvertida: escudo a la derecha, texto alineado a la derecha.
class EquipoEscudo extends StatelessWidget {
  const EquipoEscudo({
    super.key,
    required this.nombre,
    required this.escudoUrl,
    this.size = 44,
    this.disposicion = DisposicionEscudo.vertical,
    this.subtitulo,
    this.tamanoNombre = 14,
  });

  final String nombre;
  final String? escudoUrl;
  final double size;
  final DisposicionEscudo disposicion;
  final String? subtitulo;
  final double tamanoNombre;

  @override
  Widget build(BuildContext context) {
    final escudo = TdsEscudo(url: escudoUrl, size: size);
    final estiloNombre = TdsText.headline(tamanoNombre, weight: FontWeight.w700).copyWith(height: 1.15);

    if (disposicion == DisposicionEscudo.vertical) {
      return Column(
        children: [
          escudo,
          const SizedBox(height: 6),
          Text(nombre,
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: estiloNombre),
          if (subtitulo != null) Text(subtitulo!, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
        ],
      );
    }

    final derecha = disposicion == DisposicionEscudo.horizontalInvertida;
    final textos = Expanded(
      child: Column(
        crossAxisAlignment: derecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(nombre, overflow: TextOverflow.ellipsis, style: estiloNombre),
          if (subtitulo != null) Text(subtitulo!, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
        ],
      ),
    );

    return Row(
      children: derecha
          ? [textos, const SizedBox(width: 8), escudo]
          : [escudo, const SizedBox(width: 8), textos],
    );
  }
}
