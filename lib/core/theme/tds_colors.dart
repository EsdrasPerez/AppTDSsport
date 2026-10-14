import 'package:flutter/material.dart';

/// Paleta única de TDS Sport, tomada de la pantalla de login (login_screen.dart / registro_screen.dart).
class TdsColors {
  TdsColors._();

  // ---------------------------------------------------------------------------
  // Tokens del login
  // ---------------------------------------------------------------------------
  /// Caja del login y fondo del registro. Fondo de todas las pantallas.
  static const fondo = Color(0xFF121212);

  /// Paso intermedio entre fondo y superficieAlta. Tarjetas, barra lateral, AppBar.
  static const superficie = Color(0xFF1A1A1A);

  /// Fondo de los campos de texto. Campos, chips, filas internas de tarjetas.
  static const superficieAlta = Color(0xFF2C2C2C);

  /// Divisores y borde del botón Google.
  static const borde = Color(0xFF344054);

  /// Botón ENTRAR y enlace "Regístrate". Botón principal, elemento activo, resaltados.
  static const acento = Color(0xFFC6FF00);

  /// Texto e íconos encima de [acento].
  static const sobreAcento = Color(0xFF000000);

  static const texto = Color(0xFFFFFFFF);

  /// white70: etiquetas, íconos, subtítulos.
  static const textoSecundario = Color(0xB3FFFFFF);

  /// white30: placeholders y textos de ayuda.
  static const textoTenue = Color(0x4DFFFFFF);

  /// Colors.blue[700]: solo enlaces secundarios ("¿Olvidaste tu contraseña?").
  static const enlace = Color(0xFF1976D2);

  /// Colors.green: ganaste, pago aprobado, +puntos.
  static const exito = Color(0xFF4CAF50);

  /// Colors.red: errores, EN VIVO, perdiste.
  static const error = Color(0xFFF44336);

  /// Colors.orange: pendientes, avisos.
  static const advertencia = Color(0xFFFF9800);

  /// Negro al 17 %: sombra de tarjetas (sombra de la caja del login).
  static const sombra = Color(0x2B000000);

  /// Negro al 45 %: capa sobre fondo.jpg, fondos con imagen y modales.
  static const velo = Color(0x73000000);

  // ---------------------------------------------------------------------------
  // Alias temporales (nombres anteriores) → apuntan a los tokens del login.
  // TODO(decision): migrar los usos a los nombres nuevos y borrar estos alias.
  // ---------------------------------------------------------------------------
  static const surface = fondo;
  static const surfaceContainerLowest = fondo;
  static const surfaceContainerLow = superficie;
  static const surfaceContainer = superficie;
  static const surfaceContainerHigh = superficieAlta;
  static const surfaceContainerHighest = superficieAlta;
  static const surfaceBright = superficieAlta;

  static const onSurface = texto;
  static const onSurfaceVariant = textoSecundario;
  static const outlineVariant = borde;

  static const primary = texto;
  static const primaryContainer = acento;
  static const primaryFixedDim = acento;
  static const onPrimary = sobreAcento;
  static const onPrimaryContainer = sobreAcento;

  /// Antes cian: ahora el azul de enlace del login.
  static const secondaryContainer = enlace;
  static const tertiaryFixed = textoSecundario;

  /// Fondo suave de error (error al 20 %).
  static const errorContainer = Color(0x33F44336);
  static const onErrorContainer = error;
}
