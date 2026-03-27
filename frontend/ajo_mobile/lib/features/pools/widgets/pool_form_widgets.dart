import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

// --- Field label --------------------------------------------------------------

class PoolFieldLabel extends StatelessWidget {
  const PoolFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text, style: AppTypography.titleSm(cs.onSurface));
  }
}

// --- Info banner --------------------------------------------------------------

class PoolInfoBanner extends StatelessWidget {
  const PoolInfoBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTypography.bodySm(cs.onSurface)),
          ),
        ],
      ),
    );
  }
}

// --- Generic text field -------------------------------------------------------

class PoolTextField extends StatelessWidget {
  const PoolTextField({
    super.key,
    required this.controller,
    required this.hint,
  });
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: TextField(
        controller: controller,
        style: AppTypography.bodyMd(cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMd(cs.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// --- Section divider label ----------------------------------------------------

class PoolSectionLabel extends StatelessWidget {
  const PoolSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTypography.labelSm(cs.primary).copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

// --- Review detail card -------------------------------------------------------

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
