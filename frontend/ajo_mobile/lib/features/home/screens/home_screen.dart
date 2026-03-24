import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(),
      body: CustomScrollView(
        slivers: [
          _GlassAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BalanceCard(),
                const SizedBox(height: 28),
                _SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Active Pools',
                  action: TextButton(
                    onPressed: () {},
                    child: Text(
                      'See All',
                      style: AppTypography.labelMd(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _PoolCard(
                  title: 'Christmas 2024',
                  progress: 0.65,
                  amount: '₦45,000',
                  nextDate: 'Next: Dec 15',
                  icon: Icons.celebration_outlined,
                ),
                const SizedBox(height: 10),
                _PoolCard(
                  title: 'Housing Fund',
                  progress: 0.20,
                  amount: '₦120,000',
                  nextDate: 'Next: Jan 01',
                  icon: Icons.home_outlined,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Glass App Bar -----------------------------------------------------------

class _GlassAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: cs.surface.withValues(alpha: 0.80),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 20,
              right: 20,
              bottom: 12,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondaryContainer,
                  ),
                  child: Icon(
                    Icons.person,
                    color: cs.onSecondaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTypography.labelSm(cs.onSurfaceVariant),
                      ),
                      Text(
                        'Ayo Johnson',
                        style: AppTypography.titleMd(cs.onSurface),
                      ),
                    ],
                  ),
                ),
                // Theme toggle
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, _, _) {
                    final isDark = themeModeNotifier.isDark(context);
                    return GestureDetector(
                      onTap: () => themeModeNotifier.toggle(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                // Notification button
                Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: cs.onSurface,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      toolbarHeight: 72,
    );
  }
}

// --- Balance Card -------------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    // Card always renders with dark forest tones — premium card aesthetic
    const cardBg1 = Color(0xFF0A1F14);
    const cardBg2 = Color(0xFF1A2E1E);
    const cardSurface = Color(0xFF152815);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [cardBg1, cardBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THRIFT SAVINGS',
                      style: AppTypography.labelSm(cs.primary).copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Pool Balance',
                      style: AppTypography.labelSm(
                        Colors.white.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white.withValues(alpha: 0.10),
                size: 56,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦',
                style: AppTypography.displaySm(cs.primary).copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '250,000',
                style: AppTypography.displaySm(Colors.white).copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              Text(
                '.00',
                style: AppTypography.headlineSm(
                  Colors.white.withValues(alpha: 0.60),
                ).copyWith(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Member avatars
              SizedBox(
                height: 32,
                width: 104,
                child: Stack(
                  children: List.generate(4, (i) {
                    return Positioned(
                      left: i * 22.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < 3
                              ? cardSurface
                              : cs.primary.withValues(alpha: 0.25),
                          border: Border.all(color: cardSurface, width: 2),
                        ),
                        child: i < 3
                            ? Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.70),
                              )
                            : Center(
                                child: Text(
                                  '+12',
                                  style: AppTypography.labelSm(cs.primary)
                                      .copyWith(fontSize: 9),
                                ),
                              ),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              // View Details button
              Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style:
                                AppTypography.labelMd(const Color(0xFF003919))
                                    .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Color(0xFF003919),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Section Header -----------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTypography.titleLg(cs.onSurface)),
        ),
        ?action,
      ],
    );
  }
}

// --- Quick Actions Grid -------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.search_rounded,
            title: 'Explore',
            subtitle: 'Join new savings pools',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.payments_outlined,
            title: 'Contribute',
            subtitle: 'Add money to your plan',
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.titleMd(cs.onSurface)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySm(cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// --- Pool Card ----------------------------------------------------------------

class _PoolCard extends StatelessWidget {
  const _PoolCard({
    required this.title,
    required this.progress,
    required this.amount,
    required this.nextDate,
    required this.icon,
  });

  final String title;
  final double progress;
  final String amount;
  final String nextDate;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        // 4px left accent bar for "active" pools per DESIGN.md
        border: Border(
          left: BorderSide(color: cs.primary, width: 4),
        ),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.onSurfaceVariant, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSm(cs.onSurface)),
                const SizedBox(height: 8),
                // Gradient progress bar — 12px per DESIGN.md
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 12,
                    child: Stack(
                      children: [
                        Container(
                          color: cs.surfaceContainerHighest,
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
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
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.labelSm(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTypography.titleSm(cs.onSurface)),
              const SizedBox(height: 4),
              Text(nextDate, style: AppTypography.labelSm(cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Bottom Navigation --------------------------------------------------------

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: cs.surfaceContainerLowest,
      elevation: 0,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
            ),
            _NavItem(
              icon: Icons.group_outlined,
              label: 'Pools',
              selected: false,
            ),
            const Expanded(child: SizedBox()), // FAB space
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              selected: false,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Account',
              selected: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSm(color)),
          ],
        ),
      ),
    );
  }
}
