import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      illustration: _Illustration.community,
      label: 'COMMUNITY',
      title: 'Your Community,\nYour Savings',
      body:
          'Join or create Ajo groups with friends, family, and colleagues. Pool resources and achieve more together.',
    ),
    _SlideData(
      illustration: _Illustration.goals,
      label: 'GOALS',
      title: 'Set Goals,\nWatch Them Grow',
      body:
          'Create savings targets for anything — a new home, school fees, or that vacation. Track every naira with clarity.',
    ),
    _SlideData(
      illustration: _Illustration.payout,
      label: 'PAYOUTS',
      title: 'Receive Your\nRotation Payout',
      body:
          'When it\'s your turn, your full payout arrives seamlessly. Transparent, timely, and trusted by your community.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // -- Top bar: theme toggle + skip ------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _ThemeToggleButton(),
                  const Spacer(),
                  if (_page < _slides.length - 1)
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        'Skip',
                        style: AppTypography.labelLg(cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),

            // -- Illustration pager ----------------------------------------
            SizedBox(
              height: size.height * 0.50,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) =>
                    _IllustrationPanel(slide: _slides[i]),
              ),
            ),

            // -- Page dots -------------------------------------------------
            const SizedBox(height: 24),
            _PageDots(count: _slides.length, current: _page),

            // -- Text content (animated on page change) --------------------
            const SizedBox(height: 28),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _SlideText(
                    key: ValueKey(_page),
                    slide: _slides[_page],
                  ),
                ),
              ),
            ),

            // -- CTA -------------------------------------------------------
            Padding(
              padding: EdgeInsets.fromLTRB(
                28,
                16,
                28,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: AjoGradientButton(
                label: _page == _slides.length - 1 ? 'Get Started' : 'Next',
                suffixIcon: _page == _slides.length - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.chevron_right_rounded,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Slide data model ---------------------------------------------------------

enum _Illustration { community, goals, payout }

class _SlideData {
  const _SlideData({
    required this.illustration,
    required this.label,
    required this.title,
    required this.body,
  });
  final _Illustration illustration;
  final String label;
  final String title;
  final String body;
}

// --- Illustration panel -------------------------------------------------------

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.slide});
  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: switch (slide.illustration) {
        _Illustration.community => const _CommunityIllustration(),
        _Illustration.goals => const _GoalsIllustration(),
        _Illustration.payout => const _PayoutIllustration(),
      },
    );
  }
}

// -- Illustration 1: Community -------------------------------------------------

class _CommunityIllustration extends StatelessWidget {
  const _CommunityIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background radial glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 0.7,
                  colors: [
                    cs.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Main: three overlapping avatar cards
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top row: 3 overlapping avatars (large)
                SizedBox(
                  height: 90,
                  width: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Left avatar
                      Positioned(
                        left: 10,
                        child: _AvatarCard(
                          icon: Icons.person_rounded,
                          bg: cs.secondaryContainer,
                          fg: cs.onSecondaryContainer,
                          size: 72,
                        ),
                      ),
                      // Centre avatar (elevated)
                      Positioned(
                        child: _AvatarCard(
                          icon: Icons.person_rounded,
                          bg: cs.primary,
                          fg: cs.onPrimary,
                          size: 84,
                          elevated: true,
                        ),
                      ),
                      // Right avatar
                      Positioned(
                        right: 10,
                        child: _AvatarCard(
                          icon: Icons.person_rounded,
                          bg: cs.tertiaryContainer,
                          fg: cs.onTertiaryContainer,
                          size: 72,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Connector lines
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == 1 ? 32 : 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i == 1
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Members chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ext.successBackground.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        '15 active members',
                        style: AppTypography.labelMd(cs.primary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.size,
    this.elevated = false,
  });
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: fg, size: size * 0.50),
    );
  }
}

// -- Illustration 2: Goals -----------------------------------------------------

class _GoalsIllustration extends StatelessWidget {
  const _GoalsIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big balance display — Manrope "Executive" style
          Text(
            '₦ 250,000',
            style: AppTypography.displayMd(cs.onSurface).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ₦ 400,000 goal',
            style: AppTypography.labelMd(cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // Gradient progress bar (12 px, rounded — DESIGN.md spec)
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(color: cs.surfaceContainerHighest),
                  FractionallySizedBox(
                    widthFactor: 0.625,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.secondary],
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('62.5%', style: AppTypography.labelSm(cs.primary)),
              Text('37.5% left', style: AppTypography.labelSm(cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 20),

          // Mini goal cards
          ...[
            ('Christmas 2024', 0.65, Icons.celebration_outlined),
            ('Housing Fund', 0.20, Icons.home_outlined),
          ].map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MiniGoalCard(label: g.$1, progress: g.$2, icon: g.$3),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGoalCard extends StatelessWidget {
  const _MiniGoalCard({
    required this.label,
    required this.progress,
    required this.icon,
  });
  final String label;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        // 4 px left accent bar — DESIGN.md savings card signature
        border: Border(left: BorderSide(color: cs.primary, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelMd(cs.onSurface)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(color: cs.surfaceContainerHighest),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(color: cs.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTypography.labelSm(cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// -- Illustration 3: Payout ----------------------------------------------------

class _PayoutIllustration extends StatelessWidget {
  const _PayoutIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background radial glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.2),
                  radius: 0.65,
                  colors: [
                    cs.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stacked payout cards
                SizedBox(
                  height: 130,
                  width: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back card (offset, rotated)
                      Positioned(
                        top: 0,
                        child: Transform.rotate(
                          angle: -0.06,
                          child: _PayCard(
                            bg: cs.secondaryContainer,
                            amount: '₦120,000',
                            label: 'Housing Fund',
                          ),
                        ),
                      ),
                      // Front card (straight)
                      Positioned(
                        bottom: 0,
                        child: _PayCard(
                          bg: cs.primary,
                          amount: '₦45,000',
                          label: 'Christmas 2024',
                          onPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Growth arrows
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final h = 20.0 + i * 12.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3,
                            height: h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [cs.primary, ext.primaryFixedDim],
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.arrow_drop_up_rounded,
                            color: cs.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // "Payout received" chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ext.successBackground.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Payout received!',
                        style: AppTypography.labelMd(cs.primary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.bg,
    required this.amount,
    required this.label,
    this.onPrimary = false,
  });
  final Color bg;
  final String amount;
  final String label;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textColor = onPrimary ? cs.onPrimary : cs.onSecondaryContainer;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: textColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: AppTypography.titleMd(textColor)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: AppTypography.labelSm(textColor.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Page dots ----------------------------------------------------------------

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? cs.primary
                : cs.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}

// --- Slide text block ---------------------------------------------------------

class _SlideText extends StatelessWidget {
  const _SlideText({super.key, required this.slide});
  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            slide.label,
            style: AppTypography.labelSm(cs.onSecondaryContainer)
                .copyWith(letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 12),
        Text(slide.title, style: AppTypography.headlineMd(cs.onSurface)),
        const SizedBox(height: 10),
        Text(
          slide.body,
          style: AppTypography.bodyMd(cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// --- Theme toggle button ------------------------------------------------------

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, _, _) {
        final isDark = themeModeNotifier.isDark(context);
        return IconButton(
          onPressed: () => themeModeNotifier.toggle(context),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: cs.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
