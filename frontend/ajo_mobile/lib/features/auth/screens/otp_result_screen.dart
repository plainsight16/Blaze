import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../home/screens/home_screen.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

/// Handles both OTP success and failure states.
/// [success] = true  → bottom-sheet overlay with glassmorphism background.
/// [success] = false → centred error card.
class OtpResultScreen extends StatelessWidget {
  const OtpResultScreen({
    super.key,
    required this.success,
    required this.email,
    this.purpose = 'email_verification',
    this.contactMask,
  });

  final bool success;
  final String email;
  final String purpose;
  final String? contactMask;

  @override
  Widget build(BuildContext context) =>
    success
        ? const _SuccessScreen()
        : _FailureScreen(
            email: email,
            purpose: purpose,
            contactMask: contactMask,
          );
}

// --- Success ------------------------------------------------------------------

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Blurred background — simulated dashboard at low opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: const HomeScreen(),
            ),
          ),
          // Glass blur layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: cs.surface.withValues(alpha: 0.50),
              ),
            ),
          ),
          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pulsing success icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.40),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: cs.onPrimary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Verification Successful',
                    style: AppTypography.headlineSm(cs.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your identity has been confirmed. You can now start contributing to communal savings pools.',
                    style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  AjoGradientButton(
                    label: 'Continue',
                    suffixIcon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Failure ------------------------------------------------------------------

class _FailureScreen extends StatelessWidget {
  const _FailureScreen({
    required this.email,
    required this.purpose,
    this.contactMask,
  });

  final String email;
  final String purpose;
  final String? contactMask;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: cs.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Verification',
                        style: AppTypography.titleLg(cs.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.error.withValues(alpha: 0.20),
                      ),
                      boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: cs.error,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Invalid Code',
                          style: AppTypography.headlineSm(cs.onSurface),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The verification code you entered is incorrect. Please check the code in your messages and try again.',
                          style: AppTypography.bodyMd(cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        AjoGradientButton(
                          label: 'Try Again',
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtpScreen(
                                email: email,
                                purpose: purpose,
                                contactMask: contactMask,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () {},
                            child: Text(
                              'Resend Code',
                              style: AppTypography.labelLg(
                                cs.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
