import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_nav_bar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: cs.onSurface, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Messages & Support',
                      style: AppTypography.titleLg(cs.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search_rounded,
                        color: cs.onSurface, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Tab bar ─────────────────────────────────────────────────
            const SizedBox(height: 16),
            _AjoTabBar(controller: _tabs),

            // ── Tab views ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _MessagesTab(),
                  _SupportTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Compose FAB — bottom right per mockup
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_rounded, size: 24),
      ),

      bottomNavigationBar: AjoNavBar(
        active: AjoTab.messages,
        showMessages: true,
      ),
    );
  }
}

// ─── Custom tab bar ───────────────────────────────────────────────────────────

class _AjoTabBar extends StatelessWidget {
  const _AjoTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.20),
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelStyle: AppTypography.labelLg(cs.primary)
            .copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.labelLg(cs.onSurfaceVariant),
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Messages'),
          Tab(text: 'Support'),
        ],
      ),
    );
  }
}

// ─── Messages tab ─────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  static const _threads = [
    _Thread(
      name: 'Family Savings Pool',
      preview: 'Adebayo: Just made my monthly...',
      time: '10:24 AM',
      unread: true,
      initials: 'FS',
    ),
    _Thread(
      name: 'Work Colleagues Ajo',
      preview: 'You: Who is next on the rotation list?',
      time: 'Yesterday',
      unread: false,
      initials: 'WC',
    ),
    _Thread(
      name: 'Wedding Fund 2024',
      preview: 'Sarah: Almost at our goal guys! Keep it up.',
      time: 'Tue',
      unread: false,
      initials: 'WF',
    ),
    _Thread(
      name: 'Lagos Business Circle',
      preview: "John: Payment reminder for this week's...",
      time: 'Mon',
      unread: false,
      initials: 'LB',
    ),
    _Thread(
      name: 'Study Group Thrift',
      preview: 'Chioma: Textbooks are covered now,...',
      time: 'Sep 12',
      unread: false,
      initials: 'SG',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _threads.length,
      itemBuilder: (context, i) => _ThreadTile(thread: _threads[i]),
    );
  }
}

class _Thread {
  const _Thread({
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.initials,
  });
  final String name;
  final String preview;
  final String time;
  final bool unread;
  final String initials;
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});
  final _Thread thread;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      thread.initials,
                      style: AppTypography.labelMd(cs.onSecondaryContainer)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (thread.unread)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.name,
                          style: AppTypography.titleSm(cs.onSurface).copyWith(
                            fontWeight: thread.unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        thread.time,
                        style: AppTypography.labelSm(
                          thread.unread ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.preview,
                    style: AppTypography.bodySm(
                      thread.unread
                          ? cs.primary.withValues(alpha: 0.85)
                          : cs.onSurfaceVariant,
                    ).copyWith(
                      fontStyle: thread.preview.startsWith('You:')
                          ? FontStyle.normal
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ─── Support tab ──────────────────────────────────────────────────────────────

class _SupportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: cs.onSecondaryContainer,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text('Need Help?', style: AppTypography.titleLg(cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Our support team is available\n24/7 to assist you.',
            style: AppTypography.bodyMd(cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('Start a Chat'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
