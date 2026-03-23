import 'package:flutter/material.dart';

import 'core/theme/theme.dart';
import 'features/splash/screens/splash_screen.dart';

void main() {
  runApp(const AjoApp());
}

class AjoApp extends StatelessWidget {
  const AjoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'Ajo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
