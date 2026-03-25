import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../models/group_model.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import '../../profile/screens/notifications_screen.dart';

class ExploreGroupsScreen extends StatefulWidget {
  const ExploreGroupsScreen({super.key});

  @override
  State<ExploreGroupsScreen> createState() => _ExploreGroupsScreenState();
}

class _ExploreGroupsScreenState extends State<ExploreGroupsScreen> {
  int _filterIndex = 0;

  static const _filters = ['All', 'Real Estate', 'Travel', 'Business', 'Family'];

  static final _groups = [
    GroupData(
      name: 'Lagos Real Estate Pool',
      members: 12,
      capacityFraction: 0.80,
      target: '₦5,000,000',
      tag: 'TRENDING',
      tagColor: const Color(0xFF19E619),
      icon: Icons.apartment_rounded,
    ),
    GroupData(
      name: 'December Maldives Trip',
      members: 8,
      capacityFraction: 0.40,
      target: '₦2,500,000',
      tag: 'VACATION',
      tagColor: Colors.blue,
      icon: Icons.beach_access_rounded,
    ),
    GroupData(
      name: 'SME Business Fund',
      members: 25,
      capacityFraction: 0.95,
      target: '₦10,000,000',
      tag: 'BUSINESS',
      tagColor: Colors.orange,
      icon: Icons.business_center_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Explore Groups',
                        style: AppTypography.headlineSm(cs.onSurface),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: cs.onSurface,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search_rounded,
                          color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Search groups by name or interest',
                        style: AppTypography.bodyMd(cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Filter chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: _filters.length,
                  itemBuilder: (context, i) {
                    final active = i == _filterIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _filterIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? cs.primary
                              : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _filters[i],
                          style: AppTypography.labelMd(
                            active ? cs.onPrimary : cs.onSurfaceVariant,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Group cards ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GroupCard(
                      group: _groups[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupDetailScreen(group: _groups[i]),
                        ),
                      ),
                    ),
                  ),
                  childCount: _groups.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Group card (public — reused in home screen "See All") ────────────────────

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});
  final GroupData group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration area
            Stack(
              children: [
                Container(
                  height: 140,
                  color: cs.surfaceContainerHigh,
                  child: Center(
                    child: Icon(
                      group.icon,
                      size: 60,
                      color: cs.primary.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: group.tagColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      group.tag,
                      style: AppTypography.labelSm(
                        group.tagColor.computeLuminance() > 0.4
                            ? Colors.black
                            : Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: AppTypography.titleMd(cs.onSurface)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${group.members} members • '
                        '${(group.capacityFraction * 100).toInt()}% full',
                        style: AppTypography.bodySm(cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${group.target}',
                        style: AppTypography.bodySm(cs.onSurfaceVariant),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Interested',
                            style: AppTypography.labelMd(cs.onPrimary)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
