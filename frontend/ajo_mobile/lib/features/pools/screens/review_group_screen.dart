import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../widgets/pool_form_widgets.dart';

class ReviewGroupScreen extends StatelessWidget {
  const ReviewGroupScreen({
    super.key,
    this.trustScore = 750,
    this.description = '',
  });

  final int trustScore;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: const AjoNavBar(active: AjoTab.pools),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Review Group',
                      style: AppTypography.titleLg(cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── GROUP DETAILS ────────────────────────────────
                    const PoolSectionLabel('GROUP DETAILS'),
                    const SizedBox(height: 10),

                    // Group name card
                    ReviewCard(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.group_rounded,
                                  color: cs.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GROUP NAME',
                                  style: AppTypography.labelSm(
                                          cs.onSurfaceVariant)
                                      .copyWith(
                                          fontSize: 9, letterSpacing: 0.8),
                                ),
                                Text(
                                  'Thrift Savings 2024',
                                  style: AppTypography.titleMd(cs.onSurface)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Amount + interval row
                    Row(
                      children: [
                        Expanded(
                          child: ReviewCard(
                            children: [
                              Text(
                                'INDIVIDUAL AMOUNT',
                                style: AppTypography.labelSm(
                                        cs.onSurfaceVariant)
                                    .copyWith(
                                        fontSize: 9, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦50,000',
                                style: AppTypography.titleMd(cs.primary)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ReviewCard(
                            children: [
                              Text(
                                'INTERVAL',
                                style: AppTypography.labelSm(
                                        cs.onSurfaceVariant)
                                    .copyWith(
                                        fontSize: 9, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Weekly',
                                style: AppTypography.titleMd(cs.onSurface)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Visibility
                    ReviewCard(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public_rounded,
                                color: cs.onSurfaceVariant, size: 20),
                            const SizedBox(width: 10),
                            Text('Visibility Status',
                                style: AppTypography.bodyMd(cs.onSurface)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'PUBLIC',
                                style: AppTypography.labelSm(cs.onPrimary)
                                    .copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── REQUIREMENTS ────────────────────────────────
                    const PoolSectionLabel('REQUIREMENTS'),
                    const SizedBox(height: 10),

                    ReviewCard(
                      children: [
                        _ReviewDataRow(
                          label: 'MIN. TRUST SCORE',
                          value: '$trustScore+',
                          icon: Icons.verified_user_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ReviewCard(
                      children: [
                        _ReviewDataRow(
                          label: 'MIN. MONTHLY INCOME',
                          value: '₦200,000',
                          icon: Icons.payments_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── ABOUT ────────────────────────────────────────
                    const PoolSectionLabel('ABOUT THE GROUP'),
                    const SizedBox(height: 10),

                    ReviewCard(
                      children: [
                        Text(
                          'DESCRIPTION & PURPOSE',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)
                              .copyWith(fontSize: 9, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description.isEmpty
                              ? 'This group is designed for professionals '
                                  'looking to build a robust emergency fund '
                                  'through disciplined weekly contributions. '
                                  'The goal is to reach a total pool of '
                                  '₦1,000,000 per cycle.'
                              : description,
                          style: AppTypography.bodyMd(cs.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── CTA ─────────────────────────────────────────
                    AjoGradientButton(
                      label: 'Create Group',
                      suffixIcon: Icons.rocket_launch_rounded,
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review data row ──────────────────────────────────────────────────────────

class _ReviewDataRow extends StatelessWidget {
  const _ReviewDataRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSm(cs.onSurfaceVariant)
                  .copyWith(fontSize: 9, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Spacer(),
        Icon(icon, color: cs.primary, size: 24),
      ],
    );
  }
}
