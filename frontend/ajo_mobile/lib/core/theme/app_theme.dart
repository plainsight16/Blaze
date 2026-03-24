import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_theme_extensions.dart';
import 'app_typography.dart';

/// Builds [ThemeData] for the Ajo design system.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
abstract class AppTheme {
  // --- Shape tokens ---------------------------------------------------------
  // Per DESIGN.md: minimum sm (0.25rem ≈ 4dp), standard DEFAULT (0.5rem ≈ 8dp)
  static const _shapeSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
  static const _shapeMedium = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const _shapeLarge = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const _shapeFull = StadiumBorder();

  // --- Ambient shadow -------------------------------------------------------
  // "extra-diffused": offset 0 12, blur 32, 6 % tinted by on-surface
  static List<BoxShadow> ambientShadow(Color shadowColor) => [
        BoxShadow(
          color: shadowColor,
          offset: const Offset(0, 12),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ];

  // --- Light ----------------------------------------------------------------
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  // --- Dark -----------------------------------------------------------------
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  // --- Builder --------------------------------------------------------------
  static ThemeData _build(
    AjoColorTokens tokens,
    Brightness brightness,
  ) {
    final colorScheme = tokens.toColorScheme(brightness);
    final textTheme = AppTypography.buildTextTheme(
      onSurface: colorScheme.onSurface,
      onSurfaceVariant: colorScheme.onSurfaceVariant,
    );
    final ext = brightness == Brightness.light
        ? AjoThemeExtension.light
        : AjoThemeExtension.dark;

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [ext],

      // -- Scaffold / background ------------------------------------------
      scaffoldBackgroundColor: colorScheme.surface,

      // -- AppBar --------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.80),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLg(colorScheme.onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // -- Cards ---------------------------------------------------------
      // surfaceContainerLowest ("pure white lift") on surfaceContainer bg
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: _shapeMedium,
        margin: EdgeInsets.zero,
        shadowColor: ext.ambientShadowColor,
      ),

      // -- Elevated buttons (Primary CTA) --------------------------------
      // Gradient is applied via a custom ButtonStyle in widgets; here we
      // set the fallback flat colour and shape.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: _shapeSmall,
          textStyle: AppTypography.labelLg(colorScheme.onPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // -- Filled buttons (Secondary) ------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 0,
          shape: _shapeSmall,
          textStyle:
              AppTypography.labelLg(colorScheme.onSecondaryContainer),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // -- Text buttons (Tertiary ghost) ---------------------------------
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: _shapeSmall,
          textStyle: AppTypography.labelLg(colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // -- Outlined buttons ----------------------------------------------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: _shapeSmall,
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.50),
            width: 1,
          ),
          textStyle: AppTypography.labelLg(colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // -- Input fields --------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        // Resting: surfaceContainerHigh, no border
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        // Focus: surfaceContainerLowest + ghost border at 20 % primary
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: AppTypography.labelMd(colorScheme.onSurfaceVariant),
        hintStyle: AppTypography.bodyMd(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // -- Bottom navigation ---------------------------------------------
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelSm(colorScheme.primary),
        unselectedLabelStyle:
            AppTypography.labelSm(colorScheme.onSurfaceVariant),
      ),

      // -- Navigation bar (Material 3) -----------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onSecondaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelMd(colorScheme.onSecondaryContainer);
          }
          return AppTypography.labelMd(colorScheme.onSurfaceVariant);
        }),
        elevation: 0,
      ),

      // -- Chips ---------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: AppTypography.labelMd(colorScheme.onSurfaceVariant),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // -- Divider -------------------------------------------------------
      // Per DESIGN.md "No-Line Rule" — use spacing or bg shifts, not lines.
      dividerTheme: DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),

      // -- Dialogs / Sheets ----------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: _shapeLarge,
        titleTextStyle: AppTypography.headlineSm(colorScheme.onSurface),
        contentTextStyle: AppTypography.bodyMd(colorScheme.onSurfaceVariant),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        modalBackgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalElevation: 0,
        dragHandleColor: colorScheme.outlineVariant,
      ),

      // -- List tiles ----------------------------------------------------
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTypography.bodyLg(colorScheme.onSurface),
        subtitleTextStyle:
            AppTypography.bodyMd(colorScheme.onSurfaceVariant),
        iconColor: colorScheme.onSurfaceVariant,
      ),

      // -- Snackbar ------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle:
            AppTypography.bodyMd(colorScheme.onInverseSurface),
        shape: _shapeSmall,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // -- FAB -----------------------------------------------------------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: _shapeFull,
      ),

      // -- Progress indicators -------------------------------------------
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 12, // thick 12px bar per DESIGN.md
        borderRadius: BorderRadius.circular(100),
      ),

      // -- Switch / Checkbox / Radio -------------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),

      // -- Icon theme ----------------------------------------------------
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: 24,
      ),
    );
  }
}
