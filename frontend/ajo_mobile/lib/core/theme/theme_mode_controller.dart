import 'package:flutter/material.dart';

/// Global notifier for manual theme-mode override.
/// Widgets read and mutate this to switch themes at runtime.
///
/// Usage:
///   Read:   themeModeNotifier.value
///   Toggle: themeModeNotifier.toggle()
final themeModeNotifier = _ThemeModeNotifier(ThemeMode.system);

class _ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  _ThemeModeNotifier(super.value);

  void toggle(BuildContext context) {
    final currentlyDark =
        value == ThemeMode.dark ||
        (value == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    value = currentlyDark ? ThemeMode.light : ThemeMode.dark;
  }

  bool isDark(BuildContext context) {
    if (value == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return value == ThemeMode.dark;
  }
}
