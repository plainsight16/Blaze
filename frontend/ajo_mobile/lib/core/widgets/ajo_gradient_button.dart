import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Primary CTA button — gradient from `primary` to `primaryDim` at 45°.
/// Per DESIGN.md "Glass & Gradient" rule.
class AjoGradientButton extends StatelessWidget {
  const AjoGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.suffixIcon,
    this.width = double.infinity,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? suffixIcon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    final enabled = onPressed != null;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [cs.primary, ext.primaryDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLg(
                      enabled ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      suffixIcon,
                      color: enabled ? cs.onPrimary : cs.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
