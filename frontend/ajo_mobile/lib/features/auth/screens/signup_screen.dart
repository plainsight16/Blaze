import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;

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
                      Icons.arrow_back_rounded,
                      color: cs.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Create Account',
                        style: AppTypography.titleLg(cs.onSurface),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Hero icon
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.group_add_outlined,
                        color: cs.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join Ajo',
                      style: AppTypography.headlineLg(cs.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start your communal savings journey and reach your financial goals together.',
                      style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),

                    _FieldLabel('Full Name'),
                    const SizedBox(height: 8),
                    _InputField(
                      hint: 'John Doe',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 18),

                    _FieldLabel('Email Address'),
                    const SizedBox(height: 8),
                    _InputField(
                      hint: 'john@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),

                    _FieldLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _InputField(
                      hint: '+234 800 000 0000',
                      prefixIcon: Icons.smartphone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),

                    _FieldLabel('Password'),
                    const SizedBox(height: 8),
                    _InputField(
                      hint: '••••••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: cs.onSurfaceVariant,
                          size: 22,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Must be at least 8 characters with one special symbol.',
                        style: AppTypography.labelSm(cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 28),

                    AjoGradientButton(
                      label: 'Create My Account',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OtpScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.bodyMd(cs.onSurfaceVariant),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Text(
                              'Log in',
                              style: AppTypography.labelLg(cs.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: cs.surfaceContainerHighest,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: AppTypography.labelSm(cs.onSurfaceVariant),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: cs.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: Icons.g_mobiledata_rounded,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            icon: Icons.apple_rounded,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTypography.labelMd(cs.onSurfaceVariant)
          .copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.bodyLg(cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: cs.onSurfaceVariant, size: 22),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.onSurface, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLg(cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
