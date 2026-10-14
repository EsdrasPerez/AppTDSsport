import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tds_colors.dart';
import 'tds_text.dart';

/// Aplica el tema TDS a una pantalla. El MaterialApp conserva el tema original del proyecto
/// (dashboard y perfil), y las pantallas nuevas se envuelven con esto.
Widget conTemaTds(Widget child) => Theme(data: TdsTheme.oscuro, child: child);

/// ThemeData de TDS Sport (oscuro + lima). Todo color/estilo sale de aquí,
/// de [TdsColors] o de [TdsText].
class TdsTheme {
  TdsTheme._();

  static const radioCampo = 20.0; // campos del login
  static const radioTarjeta = 24.0;
  static const radioBoton = 25.0; // botón ENTRAR

  static ThemeData get oscuro {
    const esquema = ColorScheme.dark(
      primary: TdsColors.primaryContainer,
      onPrimary: TdsColors.onPrimary,
      primaryContainer: TdsColors.primaryContainer,
      onPrimaryContainer: TdsColors.onPrimaryContainer,
      secondary: TdsColors.secondaryContainer,
      onSecondary: TdsColors.surface,
      error: TdsColors.error,
      errorContainer: TdsColors.errorContainer,
      onErrorContainer: TdsColors.onErrorContainer,
      surface: TdsColors.surface,
      onSurface: TdsColors.onSurface,
      onSurfaceVariant: TdsColors.onSurfaceVariant,
      surfaceContainerLowest: TdsColors.surfaceContainerLowest,
      surfaceContainerLow: TdsColors.surfaceContainerLow,
      surfaceContainer: TdsColors.surfaceContainer,
      surfaceContainerHigh: TdsColors.surfaceContainerHigh,
      surfaceContainerHighest: TdsColors.surfaceContainerHighest,
      outlineVariant: TdsColors.outlineVariant,
    );

    OutlineInputBorder borde(Color color, [double ancho = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioCampo),
          borderSide: color == Colors.transparent ? BorderSide.none : BorderSide(color: color, width: ancho),
        );

    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: esquema);

    return base.copyWith(
      scaffoldBackgroundColor: TdsColors.surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: TdsColors.onSurface,
        displayColor: TdsColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: TdsColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: TdsColors.onSurfaceVariant),
        titleTextStyle: TdsText.headline(22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TdsColors.superficieAlta,
        labelStyle: TdsText.body(14, color: TdsColors.onSurfaceVariant),
        hintStyle: TdsText.body(14, color: TdsColors.textoTenue),
        prefixIconColor: TdsColors.onSurfaceVariant,
        suffixIconColor: TdsColors.onSurfaceVariant,
        counterStyle: TdsText.body(11, color: TdsColors.onSurfaceVariant),
        errorStyle: TdsText.body(12, color: TdsColors.error),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: borde(Colors.transparent),
        enabledBorder: borde(Colors.transparent),
        disabledBorder: borde(Colors.transparent),
        focusedBorder: borde(TdsColors.texto), // borde blanco al enfocar, como el login
        errorBorder: borde(TdsColors.error),
        focusedErrorBorder: borde(TdsColors.error, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TdsColors.primaryContainer,
          foregroundColor: TdsColors.onPrimary,
          disabledBackgroundColor: TdsColors.surfaceContainerHighest,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioBoton)),
          elevation: 0,
          textStyle: TdsText.label(15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TdsColors.primaryContainer,
          textStyle: TdsText.label(14),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: TdsColors.primaryContainer),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TdsColors.surfaceContainerHigh,
        contentTextStyle: TdsText.body(14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TdsColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TdsText.headline(20),
        contentTextStyle: TdsText.body(14, color: TdsColors.onSurfaceVariant),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TdsColors.surfaceContainer,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: TdsColors.surfaceContainerHigh,
        headerBackgroundColor: TdsColors.surfaceContainer,
        headerForegroundColor: TdsColors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TdsColors.surfaceContainerLowest,
        indicatorColor: TdsColors.primaryContainer.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TdsText.label(11,
              color: s.contains(WidgetState.selected) ? TdsColors.primaryContainer : TdsColors.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? TdsColors.primaryContainer : TdsColors.onSurfaceVariant),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: TdsColors.surfaceContainerLowest,
        indicatorColor: TdsColors.primaryContainer.withValues(alpha: 0.15),
        selectedIconTheme: const IconThemeData(color: TdsColors.primaryContainer),
        unselectedIconTheme: const IconThemeData(color: TdsColors.onSurfaceVariant),
        selectedLabelTextStyle: TdsText.label(12, color: TdsColors.primaryContainer),
        unselectedLabelTextStyle: TdsText.label(12, color: TdsColors.onSurfaceVariant),
      ),
      dividerTheme: const DividerThemeData(color: TdsColors.borde, thickness: 1),
      tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
    );
  }
}
