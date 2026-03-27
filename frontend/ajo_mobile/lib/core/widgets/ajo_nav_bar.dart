import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum AjoTab { home, pools, wallet, messages, account }

/// Shared BottomAppBar used across all main screens.
///
/// Screens that need a FAB must add it to their own Scaffold and set
/// [floatingActionButtonLocation] to [FloatingActionButtonLocation.centerDocked].
/// Pass [showFabNotch] = true on those screens so the bar shows the notch.
///
/// Pass [showMessages] = true for the 5-tab layout (Messages & Support screen).
class AjoNavBar extends StatelessWidget {
  const AjoNavBar({
    super.key,
    required this.active,
    this.showFabNotch = false,
    this.showMessages = false,
  });

  final AjoTab active;
  final bool showFabNotch;
  final bool showMessages;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (showMessages) {
      return _fiveTabBar(context, cs);
    }
    return _fourTabBar(context, cs);
  }

  // -- 4-tab layout (with optional FAB notch) ----------------------------------
  Widget _fourTabBar(BuildContext context, ColorScheme cs) {
    return BottomAppBar(
      color: cs.surfaceContainerLowest,
      elevation: 0,
      notchMargin: showFabNotch ? 8 : 0,
      shape: showFabNotch ? const CircularNotchedRectangle() : null,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _Item(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: active == AjoTab.home,
              onTap: () => _navigate(context, AjoTab.home),
            ),
            _Item(
              icon: Icons.group_outlined,
              label: 'Pools',
              selected: active == AjoTab.pools,
              onTap: () => _navigate(context, AjoTab.pools),
            ),
            if (showFabNotch) const Expanded(child: SizedBox()),
            _Item(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              selected: active == AjoTab.wallet,
              onTap: () {},
            ),
            _Item(
              icon: Icons.person_outline_rounded,
              label: 'Account',
              selected: active == AjoTab.account,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // -- 5-tab layout (Messages screen) ------------------------------------------
  Widget _fiveTabBar(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _Item(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: active == AjoTab.home,
                onTap: () => _navigate(context, AjoTab.home),
              ),
              _Item(
                icon: Icons.group_outlined,
                label: 'Pools',
                selected: active == AjoTab.pools,
                onTap: () => _navigate(context, AjoTab.pools),
              ),
              _Item(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                selected: active == AjoTab.wallet,
                onTap: () {},
              ),
              _Item(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                selected: active == AjoTab.messages,
                onTap: () => _navigate(context, AjoTab.messages),
              ),
              _Item(
                icon: Icons.person_outline_rounded,
                label: 'Account',
                selected: active == AjoTab.account,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, AjoTab tab) {
    if (tab == active) return;
    if (tab == AjoTab.home) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
    // Other tab transitions are wired up per-screen via onTap overrides.
  }
}

// --- Shared nav item ----------------------------------------------------------

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

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
