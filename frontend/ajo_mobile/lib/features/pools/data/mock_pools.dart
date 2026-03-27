import 'package:flutter/material.dart';

import '../../pools/screens/joined_group_details.dart';

// ─── Pool Model ───────────────────────────────────────────────────────────────

class PoolData {
  const PoolData({
    required this.id,
    required this.title,
    required this.icon,
    required this.progress,
    required this.contributionAmount,
    required this.nextDate,
    required this.nextDateSub,
    required this.state,
    required this.cycleLabel,
    required this.memberCount,
  });

  /// Unique identifier
  final String id;

  /// Display name of the pool
  final String title;

  /// Icon to show on the pool card
  final IconData icon;

  /// Cycle fill fraction 0.0–1.0
  final double progress;

  /// Formatted contribution amount, e.g. "₦50,000"
  final String contributionAmount;

  /// Primary date label shown on the card, e.g. "Dec 15"
  final String nextDate;

  /// Sub-label under the date, e.g. "12 DAYS LEFT"
  final String nextDateSub;

  /// Which detail-screen state to open
  final JoinedGroupState state;

  /// Short cycle label e.g. "Cycle 5 of 12"
  final String cycleLabel;

  /// Member count
  final int memberCount;
}

// ─── Mock Pool List ───────────────────────────────────────────────────────────

const List<PoolData> mockActivePools = [
  // ── State: Active (normal, on-track member) ───────────────────────────────
  PoolData(
    id: 'pool_001',
    title: 'Wealth Builders Ajo',
    icon: Icons.trending_up_rounded,
    progress: 0.42,
    contributionAmount: '₦50,000',
    nextDate: 'Dec 15',
    nextDateSub: '12 DAYS LEFT',
    state: JoinedGroupState.active,
    cycleLabel: 'Cycle 5 of 12',
    memberCount: 12,
  ),

  // ── State: Payout (it's your turn to collect) ─────────────────────────────
  PoolData(
    id: 'pool_002',
    title: 'Christmas 2024 Fund',
    icon: Icons.celebration_outlined,
    progress: 0.83,
    contributionAmount: '₦50,000',
    nextDate: 'Dec 15',
    nextDateSub: 'PAYOUT TODAY',
    state: JoinedGroupState.payout,
    cycleLabel: '10 of 12 Contributions',
    memberCount: 12,
  ),

  // ── State: Defaulting (missed payment) ────────────────────────────────────
  PoolData(
    id: 'pool_003',
    title: 'Housing Fund',
    icon: Icons.home_outlined,
    progress: 0.30,
    contributionAmount: '₦50,000',
    nextDate: 'Jan 15',
    nextDateSub: 'PAYMENT OVERDUE',
    state: JoinedGroupState.defaulting,
    cycleLabel: 'Cycle 4 of 12',
    memberCount: 12,
  ),
];