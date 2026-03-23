import 'package:flutter/material.dart';

/// Custom theme extension that surfaces tokens not covered by Flutter's
/// standard [ColorScheme] — e.g. gradient stops, glass-blur values, and
/// the "primaryDim" / "primaryFixed" slots from DESIGN.md.
@immutable
class AjoThemeExtension extends ThemeExtension<AjoThemeExtension> {
  const AjoThemeExtension({
    required this.primaryDim,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.successBackground,
    required this.glassOpacity,
    required this.glassBlur,
    required this.ghostBorderOpacity,
    required this.ambientShadowColor,
  });

  /// Darker stop for primary CTA gradient (primary → primaryDim, 45°)
  final Color primaryDim;

  /// Subtle tinted surface for "success" states (primary_fixed_dim)
  final Color primaryFixed;

  /// Muted fixed primary used in dark-bg success chips
  final Color primaryFixedDim;

  /// Background for success / positive-state chips
  final Color successBackground;

  /// Opacity for glassmorphism surfaces (0.80 per DESIGN.md)
  final double glassOpacity;

  /// Backdrop blur radius for glass surfaces (20 px per DESIGN.md)
  final double glassBlur;

  /// Opacity for the "Ghost Border" fallback (0.15 per DESIGN.md)
  final double ghostBorderOpacity;

  /// Shadow colour tinted by on-surface (rgba(44,47,48, 0.06) light)
  final Color ambientShadowColor;

  // ─── Light / Dark presets ─────────────────────────────────────────────────

  static const light = AjoThemeExtension(
    primaryDim: Color(0xFF005D2A),
    primaryFixed: Color(0xFFA0D4B3),
    primaryFixedDim: Color(0xFF85C49D),
    successBackground: Color(0xFFA0D4B3),
    glassOpacity: 0.80,
    glassBlur: 20.0,
    ghostBorderOpacity: 0.15,
    ambientShadowColor: Color(0x0F2C2F30), // 6 % of on-surface
  );

  static const dark = AjoThemeExtension(
    primaryDim: Color(0xFF3DB571),
    primaryFixed: Color(0xFF9BD6B2),
    primaryFixedDim: Color(0xFF3DB571),
    successBackground: Color(0xFF00522A),
    glassOpacity: 0.80,
    glassBlur: 20.0,
    ghostBorderOpacity: 0.15,
    ambientShadowColor: Color(0x0F000000), // 6 % black
  );

  // ─── ThemeExtension boilerplate ───────────────────────────────────────────

  @override
  AjoThemeExtension copyWith({
    Color? primaryDim,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? successBackground,
    double? glassOpacity,
    double? glassBlur,
    double? ghostBorderOpacity,
    Color? ambientShadowColor,
  }) =>
      AjoThemeExtension(
        primaryDim: primaryDim ?? this.primaryDim,
        primaryFixed: primaryFixed ?? this.primaryFixed,
        primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
        successBackground: successBackground ?? this.successBackground,
        glassOpacity: glassOpacity ?? this.glassOpacity,
        glassBlur: glassBlur ?? this.glassBlur,
        ghostBorderOpacity: ghostBorderOpacity ?? this.ghostBorderOpacity,
        ambientShadowColor: ambientShadowColor ?? this.ambientShadowColor,
      );

  @override
  AjoThemeExtension lerp(AjoThemeExtension? other, double t) {
    if (other == null) return this;
    return AjoThemeExtension(
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      primaryFixedDim:
          Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      glassOpacity: lerpDouble(glassOpacity, other.glassOpacity, t),
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t),
      ghostBorderOpacity:
          lerpDouble(ghostBorderOpacity, other.ghostBorderOpacity, t),
      ambientShadowColor:
          Color.lerp(ambientShadowColor, other.ambientShadowColor, t)!,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Convenience extension so widgets can write
/// `context.ajoTheme.primaryDim` instead of the verbose lookup.
extension AjoThemeContext on BuildContext {
  AjoThemeExtension get ajoTheme =>
      Theme.of(this).extension<AjoThemeExtension>()!;
}
