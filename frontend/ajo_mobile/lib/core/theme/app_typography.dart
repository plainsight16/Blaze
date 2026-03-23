import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for the Ajo design system.
///
/// Editorial pairing from DESIGN.md:
///  • **Manrope** – Display & Headlines ("Executive" layer)
///  • **Inter**   – Body, Labels & Data ("Assistant" layer)
abstract class AppTypography {
  // ─── Display / Headlines – Manrope ───────────────────────────────────────

  /// Hero balance, e.g. "₦ 1,250,000"
  static TextStyle displayLg(Color color) => GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: color,
      );

  static TextStyle displayMd(Color color) => GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
        color: color,
      );

  static TextStyle displaySm(Color color) => GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
        color: color,
      );

  static TextStyle headlineLg(Color color) => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: color,
      );

  static TextStyle headlineMd(Color color) => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
        color: color,
      );

  static TextStyle headlineSm(Color color) => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: color,
      );

  static TextStyle titleLg(Color color) => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: color,
      );

  static TextStyle titleMd(Color color) => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.50,
        color: color,
      );

  static TextStyle titleSm(Color color) => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      );

  // ─── Body & Labels – Inter ────────────────────────────────────────────────

  static TextStyle bodyLg(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        color: color,
      );

  static TextStyle bodyMd(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: color,
      );

  static TextStyle bodySm(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: color,
      );

  static TextStyle labelLg(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      );

  /// Primary descriptor label – pairs with [displayMd] per DESIGN.md
  static TextStyle labelMd(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: color,
      );

  static TextStyle labelSm(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: color,
      );

  // ─── TextTheme builder ────────────────────────────────────────────────────

  /// Builds a [TextTheme] wired to [onSurface] and [onSurfaceVariant].
  static TextTheme buildTextTheme({
    required Color onSurface,
    required Color onSurfaceVariant,
  }) =>
      TextTheme(
        displayLarge: displayLg(onSurface),
        displayMedium: displayMd(onSurface),
        displaySmall: displaySm(onSurface),
        headlineLarge: headlineLg(onSurface),
        headlineMedium: headlineMd(onSurface),
        headlineSmall: headlineSm(onSurface),
        titleLarge: titleLg(onSurface),
        titleMedium: titleMd(onSurface),
        titleSmall: titleSm(onSurface),
        bodyLarge: bodyLg(onSurface),
        bodyMedium: bodyMd(onSurface),
        bodySmall: bodySm(onSurfaceVariant),
        labelLarge: labelLg(onSurface),
        labelMedium: labelMd(onSurfaceVariant),
        labelSmall: labelSm(onSurfaceVariant),
      );
}
