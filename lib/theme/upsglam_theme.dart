import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum UPSGlamPalette { glam, ups }

class UPSGlamTheme {
  const UPSGlamTheme._();

  static final ValueNotifier<UPSGlamPalette> paletteNotifier =
      ValueNotifier<UPSGlamPalette>(UPSGlamPalette.glam);

  static UPSGlamPalette get currentPalette => paletteNotifier.value;

  static final Map<UPSGlamPalette, _PaletteColors> _palettes = {
    UPSGlamPalette.glam: const _PaletteColors(
      label: 'Neón GPU',
      primary: Color(0xFF8A6CFF),
      accent: Color(0xFF52F5C2),
      background: Color(0xFF04050C),
      surface: Color(0xFF12142A),
      backgroundGradient: [
        Color(0xFF05050D),
        Color(0xFF0C1024),
        Color(0xFF1E0F3F),
      ],
    ),
    UPSGlamPalette.ups: const _PaletteColors(
      label: 'UPS Institucional',
      primary: Color(0xFF0B3A75),
      accent: Color(0xFFF2C54B),
      background: Color(0xFF020A1A),
      surface: Color(0xFF0F1B38),
      backgroundGradient: [
        Color(0xFF010915),
        Color(0xFF07224A),
        Color(0xFF0B3A75),
      ],
    ),
  };

  static Color get primary => _palettes[currentPalette]!.primary;
  static Color get accent => _palettes[currentPalette]!.accent;
  static Color get background => _palettes[currentPalette]!.background;
  static Color get surface => _palettes[currentPalette]!.surface;
  static List<Color> get backgroundGradient => _palettes[currentPalette]!.backgroundGradient;

  static void setPalette(UPSGlamPalette palette) {
    if (paletteNotifier.value == palette) return;
    paletteNotifier.value = palette;
  }

  static String paletteLabel(UPSGlamPalette palette) => _palettes[palette]!.label;

  static ThemeData build({UPSGlamPalette? palette}) {
    final activePalette = _palettes[palette ?? currentPalette]!;
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: activePalette.primary,
      brightness: Brightness.dark,
      surface: activePalette.surface,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: activePalette.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: _outlineBorder(),
        enabledBorder: _outlineBorder(),
        focusedBorder: _outlineBorder(color: activePalette.accent),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: activePalette.accent,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: activePalette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: activePalette.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        selectedColor: activePalette.accent.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.white.withValues(alpha: 0.04),
        textColor: Colors.white,
        iconColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }

  static OutlineInputBorder _outlineBorder({Color? color}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: color ?? Colors.white.withValues(alpha: 0.1),
          width: 1.4,
        ),
      );
}

class _PaletteColors {
  const _PaletteColors({
    required this.label,
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.backgroundGradient,
  });

  final String label;
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final List<Color> backgroundGradient;
}
