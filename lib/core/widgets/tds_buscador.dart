import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';

/// Campo de búsqueda en forma de píldora.
class TdsBuscador extends StatelessWidget {
  const TdsBuscador({super.key, required this.onChanged, required this.hint, this.color = TdsColors.superficie});

  final ValueChanged<String> onChanged;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none);
    return TextField(
      onChanged: onChanged,
      style: TdsText.label(13),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TdsText.label(13, color: TdsColors.textoTenue),
        prefixIcon: const Icon(Icons.search, size: 20, color: TdsColors.textoSecundario),
        filled: true,
        fillColor: color,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: borde,
        enabledBorder: borde,
        focusedBorder: borde,
      ),
    );
  }
}
