import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import 'login_screen.dart';

// --- Entry Point --------------------------------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  bool _submitted = false;
  bool _sending = false;

  Future<void> _sendOtp() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    // Simulate network call
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _sending = false;
      _submitted = true;
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset link resent.')),
    );
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _submitted
        ? _LinkSentPage(onBackToLogin: _backToLogin, onResend: _resend)
        : _EmailEntryPage(
            controller: _controller,
            sending: _sending,
            onSend: _sendOtp,
            onBackToLogin: _backToLogin,
          );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP 1 — Email / Phone Entry
// ══════════════════════════════════════════════════════════════════════════════

class _EmailEntryPage extends StatelessWidget {
  const _EmailEntryPage({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onBackToLogin,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- App Bar ------------------------------------------------
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: cs.onSurface, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Ajo',
                          style: AppTypography.titleLg(cs.primary)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- Heading ------------------------------------------
                    Text('Forgot Password',
                        style: AppTypography.headlineLg(cs.onSurface)
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your registered email or phone number to receive '
                      'a 6-digit verification code.',
                      style: AppTypography.bodyLg(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 40),

                    // -- Input Card ----------------------------------------
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Field label
                          Text(
                            'EMAIL OR PHONE NUMBER',
                            style: AppTypography.labelSm(
                                    cs.onSurfaceVariant)
                                .copyWith(
                                    letterSpacing: 0.8, fontSize: 11),
                          ),
                          const SizedBox(height: 12),

                          // Input row
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  color: cs.onSurfaceVariant, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.emailAddress,
                                  style:
                                      AppTypography.bodyLg(cs.onSurface),
                                  decoration: InputDecoration(
                                    hintText: 'hello@ajo.com',
                                    hintStyle: AppTypography.bodyLg(
                                        cs.onSurface
                                            .withValues(alpha: 0.3)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Send OTP button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: sending ? null : onSend,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                disabledBackgroundColor:
                                    cs.primary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: sending
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: cs.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Send OTP',
                                            style:
                                                AppTypography.labelLg(
                                                    cs.onPrimary)),
                                        const SizedBox(width: 8),
                                        const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back to login
                          Center(
                            child: TextButton.icon(
                              onPressed: onBackToLogin,
                              icon: Icon(Icons.chevron_left_rounded,
                                  color: cs.onSurface, size: 18),
                              label: Text('Back to Login',
                                  style: AppTypography.labelMd(
                                      cs.onSurface)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // -- Footer --------------------------------------------
                    Center(
                      child: Text(
                        'SECURE LEDGER SYSTEM V2.0',
                        style: AppTypography.labelSm(
                                cs.onSurfaceVariant)
                            .copyWith(
                                fontSize: 10, letterSpacing: 1.2),
                      ),
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

// ══════════════════════════════════════════════════════════════════════════════
// STEP 2 — Link Sent Confirmation
// ══════════════════════════════════════════════════════════════════════════════

class _LinkSentPage extends StatelessWidget {
  const _LinkSentPage({
    required this.onBackToLogin,
    required this.onResend,
  });

  final VoidCallback onBackToLogin;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar --------------------------------------------------
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: cs.onSurface, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Security',
                          style: AppTypography.titleLg(cs.onSurface)),
                    ),
                  ),
                  IconButton(
                    onPressed: onBackToLogin,
                    icon: Icon(Icons.close_rounded,
                        color: cs.onSurfaceVariant, size: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    const Spacer(),

                    // -- Success Icon ------------------------------------
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF27AE60),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.black, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // -- Title -------------------------------------------
                    Text('Link Sent',
                        style: AppTypography.headlineLg(cs.onSurface)
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Text(
                      'A password reset link has been sent to your email. '
                      'Please check your inbox and spam folder.',
                      style: AppTypography.bodyLg(cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // -- Back to Login button ----------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onBackToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text('Back to Login',
                            style: AppTypography.labelLg(cs.onPrimary)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // -- Resend ------------------------------------------
                    Column(
                      children: [
                        Text("Didn't receive the email?",
                            style: AppTypography.bodySm(
                                cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onResend,
                          child: Text('Resend link',
                              style: AppTypography.labelMd(cs.primary)
                                  .copyWith(
                                      fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // -- Need Help Card ----------------------------------
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Need help?',
                                    style: AppTypography.titleSm(
                                        cs.onSurface)),
                                const SizedBox(height: 4),
                                Text(
                                  'Our support team is available 24/7 for '
                                  'account security issues.',
                                  style: AppTypography.bodySm(
                                      cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Text('Contact Support',
                                          style: AppTypography.labelMd(
                                              cs.primary)),
                                      const SizedBox(width: 4),
                                      Icon(
                                          Icons.arrow_forward_rounded,
                                          color: cs.primary,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.surfaceContainerHigh,
                            ),
                            child: Icon(Icons.help_outline_rounded,
                                color: cs.onSurfaceVariant, size: 24),
                          ),
                        ],
                      ),
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