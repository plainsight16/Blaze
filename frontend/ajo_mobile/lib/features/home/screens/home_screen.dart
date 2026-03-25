import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../messages/screens/messages_screen.dart';
import '../../pools/screens/create_group_screen.dart';
import '../../pools/screens/explore_groups_screen.dart';
import 'account_screen.dart';
import '../models/mock_user_profile.dart';
import 'dashboard_details_screen.dart';
import 'deposit_screen.dart';
import '../../profile/screens/kyc_screen.dart';
import 'wallet_screen.dart';

// ─── Main Shell ───────────────────────────────────────────────────────────────
// Wraps the four bottom-nav destinations in a single stateful scaffold so that
// switching tabs preserves each screen's scroll position.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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

    // Only show the FAB on the Dashboard tab
    final showFab = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              ),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
      // PageView enables swipe navigation between top-level tabs.
      // Each tab is wrapped so its subtree is kept alive when offscreen.
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _selectedIndex = i),
        children: const [
          _KeptPage(
            storageKey: PageStorageKey('home_dashboard'),
            child: _HomeContent(),
          ),
          _KeptPage(
            storageKey: PageStorageKey('home_explore'),
            child: ExploreGroupsScreen(),

          ),
          _KeptPage(
            storageKey: PageStorageKey('home_wallet'),
            child: WalletScreen(),
          ),


                    _KeptPage(
            storageKey: PageStorageKey('home_accounts'),
            child: AccountScreen(),
          ),
        ],
      ),
    );
  }
}

// ─── Home Content ─────────────────────────────────────────────────────────────
// Extracted from the old HomeScreen body so it lives cleanly inside the shell.

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fakeFetch();
  }

  Future<void> _fakeFetch() async {
    // Simulate remote requests so shimmer is visible.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _onRefresh() async {
    // Show shimmer again during refresh.
    if (mounted) setState(() => _loading = true);
    await _fakeFetch();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _GlassAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _BalanceCard(loading: _loading),
                  const SizedBox(height: 20),
                  _ProfileCompletionCard(loading: _loading),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Active Pools',
                    action: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExploreGroupsScreen(),
                        ),
                      ),
                      child: Text(
                        'See All',
                        style: AppTypography.labelMd(cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PoolCard(
                    loading: _loading,
                    title: 'Christmas 2024',
                    progress: 0.65,
                    amount: '₦45,000',
                    nextDate: 'Next: Dec 15',
                    icon: Icons.celebration_outlined,
                  ),
                  const SizedBox(height: 10),
                  _PoolCard(
                    loading: _loading,
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
      ),
    );
  }
}

class _KeptPage extends StatefulWidget {
  const _KeptPage({
    required this.storageKey,
    required this.child,
  });

  final Key storageKey;
  final Widget child;

  @override
  State<_KeptPage> createState() => _KeptPageState();
}

class _KeptPageState extends State<_KeptPage>
    with AutomaticKeepAliveClientMixin<_KeptPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyedSubtree(
      key: widget.storageKey,
      child: widget.child,
    );
  }
}

// ─── Glass App Bar ────────────────────────────────────────────────────────────

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
                        mockUserProfile.fullName,
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
                // Messages button
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MessagesScreen(),
                    ),
                  ),
                  child: Stack(
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

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final base = cs.surfaceContainerHigh;
    final highlight = cs.onSurfaceVariant.withValues(alpha: 0.20);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final begin = Alignment(-1.0 + (2.2 * t), 0.0);
        final end = Alignment(-0.2 + (2.2 * t), 0.0);
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = widget.width == double.infinity
                ? constraints.maxWidth
                : widget.width;
            return Container(
              width: w,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: [base, highlight, base],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    final fixed = mockUserProfile.totalPoolBalance.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts.first;
    final decPart = parts.length > 1 ? parts.last : '00';
    final intFormatted = intPart.replaceAllMapped(
      RegExp(r'\\B(?=(\\d{3})+(?!\\d))'),
      (m) => ',',
    );

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
      child: loading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 170, height: 14, radius: 10),
                const SizedBox(height: 8),
                _ShimmerBox(width: 150, height: 10, radius: 10),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ShimmerBox(width: 18, height: 28, radius: 8),
                    const SizedBox(width: 10),
                    _ShimmerBox(width: 150, height: 44, radius: 12),
                    const SizedBox(width: 12),
                    _ShimmerBox(width: 50, height: 26, radius: 10),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      height: 32,
                      width: 104,
                      child: Stack(
                        children: List.generate(4, (i) {
                          return Positioned(
                            left: i * 22.0,
                            child: const _ShimmerBox(
                              width: 32,
                              height: 32,
                              radius: 100,
                            ),
                          );
                        }),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 140,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: _ShimmerBox(
                          width: 120,
                          height: 18,
                          radius: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
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
                      intFormatted,
                      style: AppTypography.displaySm(Colors.white).copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      '.$decPart',
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
                                border: Border.all(
                                  color: cardSurface,
                                  width: 2,
                                ),
                              ),
                              child: i < 3
                                  ? Icon(
                                      Icons.person,
                                      size: 16,
                                      color:
                                          Colors.white.withValues(alpha: 0.70),
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
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DashboardDetailsScreen(),
                            ),
                          ),
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
                                  style: AppTypography.labelMd(
                                    const Color(0xFF003919),
                                  ).copyWith(fontWeight: FontWeight.w700),
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

// ─── Profile Completion Card ──────────────────────────────────────────────────

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    final progress = mockUserProfile.profileCompletion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: loading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ShimmerBox(width: 190, height: 14, radius: 8),
                          SizedBox(height: 10),
                          _ShimmerBox(width: 220, height: 10, radius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _ShimmerBox(width: 36, height: 36, radius: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _ShimmerBox(width: 120, height: 16, radius: 8),
                    Spacer(),
                    _ShimmerBox(width: 90, height: 14, radius: 8),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 6,
                    child: const _ShimmerBox(
                      width: double.infinity,
                      height: 6,
                      radius: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _ShimmerBox(
                  width: double.infinity,
                  height: 44,
                  radius: 10,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Complete Your Profile',
                              style: AppTypography.titleMd(cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(
                            'Unlock all features by finishing your account setup.',
                            style: AppTypography.bodySm(cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_user_rounded,
                          color: cs.primary, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${(progress * 100).toInt()}% Completed',
                        style: AppTypography.labelMd(cs.primary)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('3/4 Steps',
                        style: AppTypography.labelSm(cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 6,
                    child: Stack(children: [
                      Container(color: cs.surfaceContainerHighest),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: cs.primary),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KycScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary),
                    ),
                    child: Text(
                      'Finish Setup Now',
                      style: AppTypography.labelLg(cs.primary)
                          .copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

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
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────

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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ExploreGroupsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.payments_outlined,
            title: 'Contribute',
            subtitle: 'Add money to your plan',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DepositScreen(),
              ),
            ),
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
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}

// ─── Pool Card ────────────────────────────────────────────────────────────────

class _PoolCard extends StatelessWidget {
  const _PoolCard({
    this.loading = false,
    required this.title,
    required this.progress,
    required this.amount,
    required this.nextDate,
    required this.icon,
  });

  final bool loading;
  final String title;
  final double progress;
  final String amount;
  final String nextDate;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    if (loading) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _ShimmerBox(width: 48, height: 48, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBox(width: 160, height: 14, radius: 8),
                  SizedBox(height: 10),
                  _ShimmerBox(width: 210, height: 12, radius: 8),
                  SizedBox(height: 12),
                  _ShimmerBox(width: double.infinity, height: 14, radius: 8),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 12,
                    child: Stack(
                      children: [
                        Container(color: cs.surfaceContainerHighest),
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

// ─── Bottom Navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

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
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),

            _NavItem(
              icon: Icons.explore_outlined,
              label: 'Explore',
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),

            const Expanded(child: SizedBox()), // FAB space
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),

            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Accounts',
              selected: selectedIndex == 3,
              onTap: () => onTap(3),
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
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
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
