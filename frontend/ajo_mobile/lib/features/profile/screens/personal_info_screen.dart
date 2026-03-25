import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../home/models/mock_user_profile.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Personal Information',
          style: AppTypography.titleMd(cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            _InfoRow(label: 'Name', value: mockUserProfile.fullName),
            const SizedBox(height: 16),
            _InfoRow(label: 'Handle', value: mockUserProfile.handle),
            const SizedBox(height: 16),
            const _InfoRow(label: 'Email', value: 'ayo@example.com'),
            const SizedBox(height: 16),
            const _InfoRow(label: 'Phone', value: '+234 800 000 0000'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSm(cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.titleSm(cs.onSurface)),
        ],
      ),
    );
  }
}

