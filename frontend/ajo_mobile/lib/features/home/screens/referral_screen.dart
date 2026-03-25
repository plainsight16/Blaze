import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const referralCode = 'AJ-1024-AYO';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Referral',
          style: AppTypography.titleMd(cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite a friend and get bonus rewards.',
                style: AppTypography.bodyMd(cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your referral code',
                      style: AppTypography.labelSm(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      referralCode,
                      style: AppTypography.titleMd(cs.onSurface).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AjoGradientButton(
                label: 'Copy Code',
                suffixIcon: Icons.copy_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied (mock).')),
                  );
                },
              ),
              const SizedBox(height: 12),
              AjoGradientButton(
                label: 'Share Invitation',
                suffixIcon: Icons.share_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share sheet (mock).')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

