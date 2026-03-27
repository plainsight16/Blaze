import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../models/group_model.dart';
import '../data/groups_http_api.dart';
import 'explore_groups_controller.dart';
import 'create_group_screen.dart';
import 'group_admin_screen.dart';
import 'group_detail_screen.dart';
import 'group_user_screen.dart';
import '../../profile/screens/notifications_screen.dart';

class ExploreGroupsScreen extends StatefulWidget {
  const ExploreGroupsScreen({super.key});

  @override
  State<ExploreGroupsScreen> createState() => _ExploreGroupsScreenState();
}

class _ExploreGroupsScreenState extends State<ExploreGroupsScreen> {
  late final ExploreGroupsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExploreGroupsController(
      api: GroupsHttpApi(client: apiClient), // use your app's ApiClient instance
    );
    _controller.fetchGroups();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Helpers to map API model → UI model ──────────────────────────────────

  GroupData _mapSummaryToUi(GroupSummary summary) {
    final type = summary.type.toLowerCase();
    return GroupData(
      id: summary.id,
      name: summary.name,
      description: summary.description,
      type: summary.type,
      members: 0,
      capacityFraction: 0.5,
      target: '₦${_formatMonthlyCon(summary.monthlyCon)}',
      tag: type.isNotEmpty ? summary.type.toUpperCase() : 'GROUP',
      tagColor: _tagColorForType(type),
      icon: _iconForType(type),
    );
  }

  String _formatMonthlyCon(int amount) {
    if (amount == 0) return '0';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toString();
  }

  IconData _iconForType(String type) {
    if (type.contains('real')) return Icons.apartment_rounded;
    if (type.contains('travel')) return Icons.beach_access_rounded;
    if (type.contains('business')) return Icons.business_center_rounded;
    if (type.contains('family')) return Icons.family_restroom_rounded;
    return Icons.groups_rounded;
  }

  Color _tagColorForType(String type) {
    if (type.contains('real')) return const Color(0xFF19E619);
    if (type.contains('travel')) return Colors.blue;
    if (type.contains('business')) return Colors.orange;
    if (type.contains('family')) return Colors.purple;
    return Colors.teal;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<GroupsState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final groups = state.groups.map(_mapSummaryToUi).toList();

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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          body: SafeArea(
            child: RefreshIndicator(
              color: cs.primary,
              onRefresh: _controller.fetchGroups,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── App bar ───────────────────────────────────────────────
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

                  // ── Search bar ────────────────────────────────────────────
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

                  // ── Filter chips ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        itemCount: ExploreGroupsController.filters.length,
                        itemBuilder: (context, i) {
                          final active = i == _controller.filterIndex;
                          return GestureDetector(
                            onTap: () => _controller.setFilter(i),
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
                                ExploreGroupsController.filters[i],
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

                  // ── Pending invites ───────────────────────────────────────
                  if (state.invites.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _InviteCard(
                          invite: state.invites.first,
                          onAccept: () =>
                              _controller.acceptInvite(state.invites.first.id),
                          onDecline: () =>
                              _controller.declineInvite(state.invites.first.id),
                        ),
                      ),
                    ),

                  // ── My Groups section ─────────────────────────────────────
                  if (state.myGroups.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Groups',
                              style: AppTypography.titleMd(cs.onSurface),
                            ),
                            const SizedBox(height: 8),
                            ...state.myGroups.take(3).map(
                                  (g) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(g.name),
                                    subtitle: Text(g.role.toUpperCase()),
                                    trailing:
                                        const Icon(Icons.chevron_right_rounded),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => g.role == 'admin'
                                            ? GroupAdminScreen(
                                                groupId: g.groupId,
                                                groupName: g.name)
                                            : GroupUserScreen(
                                                groupId: g.groupId,
                                                groupName: g.name),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),

                  // ── Loading / Error / Data states ─────────────────────────
                  if (state.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 32, 20, 100),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        child: Column(
                          children: [
                            Text(
                              state.error!,
                              style: AppTypography.bodyMd(cs.error),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _controller.fetchGroups,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (groups.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
                        child: Center(
                          child: Text(
                            'No groups found.',
                            style: AppTypography.bodyMd(cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GroupCard(
                              group: groups[i],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GroupDetailScreen(group: groups[i]),
                                ),
                              ),
                              onInterested: () async {
                                final id = groups[i].id;
                                if (id == null || id.isEmpty) return;

                                final isMine = state.myGroups
                                    .any((g) => g.groupId == id);
                                if (isMine) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You cannot join a group you created.'),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await _controller.requestToJoin(id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Join request sent.')),
                                  );
                                } on ApiException catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                }
                              },
                            ),
                          ),
                          childCount: groups.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Invite card ───────────────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupInvite invite;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite: ${invite.groupName}',
              style: AppTypography.titleSm(cs.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: onDecline, child: const Text('Decline')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onAccept, child: const Text('Accept')),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onInterested,
  });

  final GroupData group;
  final VoidCallback onTap;
  final VoidCallback onInterested;

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
                  Text(group.name, style: AppTypography.titleMd(cs.onSurface)),
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
                        'Monthly: ${group.target}',
                        style: AppTypography.bodySm(cs.onSurfaceVariant),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onInterested,
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