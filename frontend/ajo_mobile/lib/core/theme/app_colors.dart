import 'package:flutter/material.dart';

/// Semantic color tokens for the Ajo design system.
/// Derived from the "Forest & Fog" palette in DESIGN.md.
abstract class AppColors {
  // --- Light Scheme --------------------------------------------------------
  static const light = AjoColorTokens(
    // Primary – vibrant professional green
    primary: Color(0xFF006A31),
    primaryDim: Color(0xFF005D2A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF9BD6B2),
    onPrimaryContainer: Color(0xFF002110),
    primaryFixed: Color(0xFFA0D4B3),
    primaryFixedDim: Color(0xFF85C49D),

    // Secondary – earthy muted green
    secondary: Color(0xFF4E6356),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD0E8D9),
    onSecondaryContainer: Color(0xFF0A1F14),

    // Tertiary – cool slate teal
    tertiary: Color(0xFF3D6373),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC1E8F9),
    onTertiaryContainer: Color(0xFF001F2A),

    // Error
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Surfaces – the "layered stationery" stack
    background: Color(0xFFF5F6F7),
    onBackground: Color(0xFF2C2F30),
    surface: Color(0xFFF5F6F7),
    onSurface: Color(0xFF2C2F30),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFF1F2),
    surfaceContainer: Color(0xFFE6E8EA),
    surfaceContainerHigh: Color(0xFFDCDEE0),
    surfaceContainerHighest: Color(0xFFD1D3D5),
    onSurfaceVariant: Color(0xFF44474F),
    inverseSurface: Color(0xFF2F3130),
    onInverseSurface: Color(0xFFF0F1EF),
    inversePrimary: Color(0xFF5BC98A),

    // Outline
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFABADAE),

    // Scrim / shadow tint
    scrim: Color(0xFF000000),
    shadow: Color(0xFF2C2F30),
  );

  // --- Dark Scheme ---------------------------------------------------------
  static const dark = AjoColorTokens(
    // Primary – lifted for dark surfaces
    primary: Color(0xFF5BC98A),
    primaryDim: Color(0xFF3DB571),
    onPrimary: Color(0xFF003919),
    primaryContainer: Color(0xFF00522A),
    onPrimaryContainer: Color(0xFF9BD6B2),
    primaryFixed: Color(0xFF9BD6B2),
    primaryFixedDim: Color(0xFF3DB571),

    // Secondary
    secondary: Color(0xFFB5CCBB),
    onSecondary: Color(0xFF203529),
    secondaryContainer: Color(0xFF374B3E),
    onSecondaryContainer: Color(0xFFD0E8D9),

    // Tertiary
    tertiary: Color(0xFFA5CCD9),
    onTertiary: Color(0xFF083544),
    tertiaryContainer: Color(0xFF244C5C),
    onTertiaryContainer: Color(0xFFC1E8F9),

    // Error
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surfaces – deep forest-fog dark stack
    background: Color(0xFF1A1C1B),
    onBackground: Color(0xFFE1E3E1),
    surface: Color(0xFF1A1C1B),
    onSurface: Color(0xFFE1E3E1),
    surfaceContainerLowest: Color(0xFF141716),
    surfaceContainerLow: Color(0xFF1E2120),
    surfaceContainer: Color(0xFF252927),
    surfaceContainerHigh: Color(0xFF2D312F),
    surfaceContainerHighest: Color(0xFF383C3A),
    onSurfaceVariant: Color(0xFFBEC9C0),
    inverseSurface: Color(0xFFE1E3E1),
    onInverseSurface: Color(0xFF2F3130),
    inversePrimary: Color(0xFF006A31),

    // Outline
    outline: Color(0xFF899189),
    outlineVariant: Color(0xFF3F4941),

    // Scrim / shadow tint
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );
}

/// Immutable bag of every semantic color token.
@immutable
class AjoColorTokens {
  const AjoColorTokens({
    required this.primary,
    required this.primaryDim,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.outline,
    required this.outlineVariant,
    required this.scrim,
    required this.shadow,
  });

  final Color primary;
  final Color primaryDim;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurfaceVariant;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  final Color outline;
  final Color outlineVariant;
  final Color scrim;
  final Color shadow;

  /// Builds a Flutter [ColorScheme] from these tokens.
  ColorScheme toColorScheme(Brightness brightness) => ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: onInverseSurface,
        inversePrimary: inversePrimary,
        outline: outline,
        outlineVariant: outlineVariant,
        scrim: scrim,
        shadow: shadow,
      );
}
