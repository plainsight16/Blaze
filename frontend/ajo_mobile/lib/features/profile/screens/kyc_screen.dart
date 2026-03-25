import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _bankUploaded = false;
  bool _employmentUploaded = false;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete your profile',
                      style: AppTypography.headlineSm(cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please upload the following documents to verify your '
                      'identity and increase your transaction limits.',
                      style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),

                    // ── Bank Statements ──────────────────────────────
                    _SectionHeader(
                      title: 'Bank Statements',
                      badge: _RequiredBadge(required: true),
                    ),
                    const SizedBox(height: 12),

                    _bankUploaded
                        ? _UploadedFile(
                            name: 'bank_statement.pdf',
                            onRemove: () =>
                                setState(() => _bankUploaded = false),
                          )
                        : _DropZone(
                            onTap: () =>
                                setState(() => _bankUploaded = true),
                            subtitle: 'PDF, PNG, or JPG (max. 10MB)',
                            hint: 'Provide at least 3 months of recent activity',
                          ),
                    const SizedBox(height: 24),

                    // ── Employment Record ────────────────────────────
                    _SectionHeader(
                      title: 'Employment Record',
                      badge: _RequiredBadge(required: false),
                    ),
                    const SizedBox(height: 12),

                    _CompactUploadRow(
                      icon: Icons.description_outlined,
                      title: 'Proof of employment',
                      subtitle: 'Offer letter or latest payslip',
                      uploaded: _employmentUploaded,
                      onTap: () =>
                          setState(() => _employmentUploaded = !_employmentUploaded),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit CTA ───────────────────────────────────
                    AjoGradientButton(
                      label: 'Submit for Review',
                      suffixIcon: Icons.send_rounded,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'By submitting, you agree to our Terms of Service and '
                      'Privacy Policy regarding data verification.',
                      style: AppTypography.labelSm(cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
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
