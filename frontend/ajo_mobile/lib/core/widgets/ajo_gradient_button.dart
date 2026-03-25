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
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? suffixIcon;
  final double width;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    final busy = isLoading;
    final enabled = onPressed != null && !busy;

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
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: busy
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary,
                        ),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: AppTypography.labelLg(
                              onPressed != null
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          if (suffixIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              suffixIcon,
                              color: onPressed != null
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
