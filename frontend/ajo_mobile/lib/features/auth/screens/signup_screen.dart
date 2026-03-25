import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../auth_validators.dart';
import '../data/mock_auth_api.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await mockAuthApi.signup(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final hint = _maskedPhone(_phoneController.text);
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OtpScreen(contactMask: hint),
        ),
      );
    } on MockAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _maskedPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '•••• ••42';
    return '•••• ••${digits.substring(digits.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
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

                      const _FieldLabel('Full Name'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _nameController,
                        hint: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: AuthValidators.fullName,
                      ),
                      const SizedBox(height: 18),

                      const _FieldLabel('Email Address'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _emailController,
                        hint: 'john@example.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: AuthValidators.email,
                      ),
                      const SizedBox(height: 18),

                      const _FieldLabel('Phone Number'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _phoneController,
                        hint: '+234 800 000 0000',
                        prefixIcon: Icons.smartphone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: AuthValidators.phone,
                      ),
                      const SizedBox(height: 18),

                      const _FieldLabel('Password'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _passwordController,
                        hint: '••••••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onCreateAccount(),
                        validator: AuthValidators.passwordSignup,
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
                        isLoading: _submitting,
                        onPressed: _submitting ? null : _onCreateAccount,
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
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: AppTypography.bodyLg(cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: cs.onSurfaceVariant, size: 22),
        suffixIcon: suffixIcon,
        errorMaxLines: 2,
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
