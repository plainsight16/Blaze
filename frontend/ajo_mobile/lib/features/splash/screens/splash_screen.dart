import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Logo badge — scale up with elastic bounce
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Wordmark + tagline — fade + slide up after logo lands
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  // Bottom tagline dot row
  late final Animation<double> _dotsOpacity;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    _logoOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
    );

    _textOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
      ),
    );

    _dotsOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward();

    // Navigate once animation settles
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const OnboardingScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = themeModeNotifier.isDark(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Subtle radial glow behind logo
          Positioned(
            top: -60,
            left: -60,
            right: -60,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.75,
                  colors: [
                    cs.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    cs.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo badge
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: _LogoBadge(),
                  ),
                ),
                const SizedBox(height: 28),

                // Wordmark + tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'ajo',
                          style: AppTypography.displaySm(cs.onSurface).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The Digital Ledger, Humanized.',
                          style: AppTypography.bodyMd(cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loading dots
          Positioned(
            bottom: 48 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _dotsOpacity,
              child: _LoadingDots(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Logo badge ---------------------------------------------------------------

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, ext.primaryDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle gloss overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: cs.onPrimary,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Loading dots -------------------------------------------------------------

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final t = Curves.easeInOut.transform(
              (phase * 2).clamp(0.0, 1.0) < 1.0
                  ? (phase * 2).clamp(0.0, 1.0)
                  : 2.0 - (phase * 2).clamp(0.0, 2.0),
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6 + t * 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.30 + t * 0.70),
                borderRadius: BorderRadius.circular(100),
              ),
            );
          },
        );
      }),
    );
  }
}
