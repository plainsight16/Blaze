import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../pools/screens/explore_groups_screen.dart';

/// "View Details" destination from the Home dashboard.
/// For now, it reuses ExploreGroupsScreen (same UX: list of available pools).
class DashboardDetailsScreen extends StatelessWidget {
  const DashboardDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pool Details',
          style: AppTypography.titleMd(cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const ExploreGroupsScreen(),
    );
  }
}

