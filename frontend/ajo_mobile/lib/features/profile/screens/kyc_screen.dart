import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../data/profile_http_api.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final TextEditingController _bvnController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  KycRequirements? _requirements;
  BankStatementSummary? _statement;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bvnController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final requirements = await profileHttpApi.getKycRequirements();
      BankStatementSummary? statement;
      try {
        statement = await profileHttpApi.getBankStatement();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _requirements = requirements;
        _statement = statement;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verifyBvn() async {
    if (_bvnController.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BVN must be 11 digits')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await profileHttpApi.verifyBvn(_bvnController.text.trim());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _generateStatement() async {
    setState(() => _submitting = true);
    try {
      final statement = await profileHttpApi.generateBankStatement();
      if (!mounted) return;
      setState(() => _statement = statement);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _provisionWallet() async {
    setState(() => _submitting = true);
    try {
      await profileHttpApi.provisionWallet();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _nextStep => _requirements?.nextStep ?? 'verify_bvn';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: const AjoNavBar(active: AjoTab.account),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: cs.onSurface, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'KYC Verification',
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _requirements?.bannerTitle ??
                                'KYC and Wallet Setup',
                            style: AppTypography.headlineSm(cs.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _requirements?.bannerMessage ??
                                'Verify your BVN and complete wallet setup.',
                            style: AppTypography.bodyMd(cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 28),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(_error!,
                                  style: AppTypography.bodySm(cs.error)),
                            ),
                          if (_nextStep == 'completed') ...[
                            _KycCompletedCard(statement: _statement),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed:
                                  _submitting ? null : _generateStatement,
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Generate bank statement'),
                            ),
                          ] else if (_nextStep == 'provision_wallet' ||
                              _nextStep == 'retry_wallet_provisioning') ...[
                            _SectionHeader(
                              title: 'Wallet',
                              badge: _RequiredBadge(required: true),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded,
                                      color: cs.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _requirements?.bannerMessage ??
                                          'Provision your wallet to finish onboarding.',
                                      style: AppTypography.bodyMd(cs.onSurface),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            AjoGradientButton(
                              label: _nextStep == 'retry_wallet_provisioning'
                                  ? 'Retry wallet provisioning'
                                  : 'Provision wallet',
                              suffixIcon: Icons.account_balance_rounded,
                              isLoading: _submitting,
                              onPressed:
                                  _submitting ? null : _provisionWallet,
                            ),
                          ] else ...[
                            _SectionHeader(
                              title: 'BVN verification',
                              badge: _RequiredBadge(required: true),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _bvnController,
                              keyboardType: TextInputType.number,
                              maxLength: 11,
                              decoration: const InputDecoration(
                                labelText: 'BVN',
                                hintText: 'Enter 11-digit BVN',
                              ),
                            ),
                            const SizedBox(height: 12),
                            AjoGradientButton(
                              label: 'Verify BVN',
                              suffixIcon: Icons.verified_user_rounded,
                              isLoading: _submitting,
                              onPressed: _submitting ? null : _verifyBvn,
                            ),
                            const SizedBox(height: 28),
                            _SectionHeader(
                              title: 'Bank statement',
                              badge: _RequiredBadge(required: false),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Optional: generate a statement for your records.',
                              style: AppTypography.bodySm(cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed:
                                  _submitting ? null : _generateStatement,
                              icon: const Icon(Icons.description_rounded),
                              label: const Text('Generate bank statement'),
                            ),
                          ],
                          if (_statement != null &&
                              _nextStep != 'completed') ...[
                            const SizedBox(height: 20),
                            Text(
                              'Statement summary',
                              style: AppTypography.titleSm(cs.onSurface),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Average balance: ${_statement!.averageBalance.toStringAsFixed(2)}',
                              style: AppTypography.bodyMd(cs.onSurface),
                            ),
                            Text(
                              'Total credit: ${_statement!.totalCredit.toStringAsFixed(2)}',
                              style: AppTypography.bodyMd(cs.onSurface),
                            ),
                            Text(
                              'Total debit: ${_statement!.totalDebit.toStringAsFixed(2)}',
                              style: AppTypography.bodyMd(cs.onSurface),
                            ),
                          ],
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

// ─── Completed state ──────────────────────────────────────────────────────────

class _KycCompletedCard extends StatelessWidget {
  const _KycCompletedCard({this.statement});

  final BankStatementSummary? statement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'KYC complete',
                  style: AppTypography.titleMd(cs.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your BVN is verified and your wallet is active.',
            style: AppTypography.bodyMd(cs.onSurfaceVariant),
          ),
          if (statement != null) ...[
            const SizedBox(height: 16),
            Text(
              'Latest statement',
              style: AppTypography.titleSm(cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Avg. balance: ${statement!.averageBalance.toStringAsFixed(2)}',
              style: AppTypography.bodySm(cs.onSurface),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.badge});
  final String title;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title, style: AppTypography.titleMd(cs.onSurface)),
        const Spacer(),
        badge,
      ],
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({required this.required});
  final bool required;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: required
            ? cs.primary.withValues(alpha: 0.15)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: required
              ? cs.primary.withValues(alpha: 0.40)
              : cs.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        required ? 'Required' : 'OPTIONAL',
        style: AppTypography.labelSm(
          required ? cs.primary : cs.onSurfaceVariant,
        ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

// ─── Dashed drop zone ─────────────────────────────────────────────────────────

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.onTap,
    required this.subtitle,
    required this.hint,
  });
  final VoidCallback onTap;
  final String subtitle;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: cs.primary.withValues(alpha: 0.50),
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.upload_file_rounded,
                    color: cs.primary, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'Click to upload or drag and drop',
                style: AppTypography.titleSm(cs.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(hint,
                  style: AppTypography.labelSm(cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Uploaded file row ────────────────────────────────────────────────────────

class _UploadedFile extends StatelessWidget {
  const _UploadedFile({required this.name, required this.onRemove});
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_rounded,
              color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: AppTypography.bodyMd(cs.onSurface)),
          ),
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Compact upload row ───────────────────────────────────────────────────────

class _CompactUploadRow extends StatelessWidget {
  const _CompactUploadRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSm(cs.onSurface)),
                Text(subtitle,
                    style: AppTypography.labelSm(cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: uploaded
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: uploaded
                      ? cs.primary.withValues(alpha: 0.40)
                      : cs.primary,
                ),
              ),
              child: Text(
                uploaded ? 'Uploaded' : 'Upload',
                style: AppTypography.labelMd(cs.primary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashGap = 5.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashGap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += math.min(len, metric.length - distance);
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
