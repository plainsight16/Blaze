import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import 'otp_result_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  bool get _isFilled =>
      _controllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        'SECURITY',
                        style: AppTypography.labelLg(cs.primary).copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Lock icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_person_outlined,
                        color: cs.primary,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Verification Code',
                      style: AppTypography.headlineMd(cs.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We\'ve sent a 6-digit verification code to your registered mobile number ••••  ••42',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 40),

                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onChanged(v, i),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Expires in 01:54',
                          style: AppTypography.bodyMd(cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Didn\'t receive code? Resend',
                        style: AppTypography.labelLg(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // CTA pinned at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AnimatedBuilder(
                animation: Listenable.merge(_controllers),
                builder: (context, _) => AjoGradientButton(
                  label: 'Verify & Proceed',
                  onPressed: _isFilled
                      ? () => _submit(context)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    // Demo: treat "111111" as failure, anything else as success
    final code = _controllers.map((c) => c.text).join();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpResultScreen(success: code != '111111'),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTypography.headlineSm(cs.onSurface)
            .copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: cs.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.primary.withValues(alpha: 0.50),
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
