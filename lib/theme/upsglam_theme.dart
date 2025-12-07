import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UPSGlamTheme {
  const UPSGlamTheme._();

  static const Color primary = Color(0xFF8A6CFF);
  static const Color accent = Color(0xFF52F5C2);
  static const Color background = Color(0xFF04050C);
  static const Color surface = Color(0xFF12142A);

  static ThemeData build() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
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
        focusedBorder: _outlineBorder(color: accent),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: accent,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        selectedColor: accent.withValues(alpha: 0.3),
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
