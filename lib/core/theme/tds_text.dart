import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tds_colors.dart';

/// Estilos de texto de TDS Sport.
class TdsText {
  TdsText._();

  /// Etiquetas y botones (Plus Jakarta Sans, negrita).
  static TextStyle label(double size, {Color color = TdsColors.onSurface, double letterSpacing = 0}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
      );

  /// Texto normal (Plus Jakarta Sans).
  static TextStyle body(double size, {Color color = TdsColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(color: color, fontSize: size, fontWeight: FontWeight.w400);

  /// Números y marcadores (Outfit).
  static TextStyle stats(double size, {Color color = TdsColors.onSurface}) =>
      GoogleFonts.outfit(color: color, fontSize: size, fontWeight: FontWeight.w700, height: 1);

  /// Títulos y nombres de equipos (Outfit).
  static TextStyle headline(double size, {Color color = TdsColors.onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.outfit(color: color, fontSize: size, fontWeight: weight);
}
