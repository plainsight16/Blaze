import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import 'forgot_password_screen.dart';
import '../auth_validators.dart';
import '../data/mock_auth_api.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await mockAuthApi.login(
        identifier: _identifierController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final hint = _maskedIdentifier(_identifierController.text.trim());
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

  String _maskedIdentifier(String raw) {
    if (raw.contains('@')) {
      final parts = raw.split('@');
      if (parts.length != 2 || parts[0].length < 2) return '••••@…';
      final a = parts[0];
      return '${a[0]}•••@${parts[1]}';
    }
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
            const _AppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: cs.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome back',
                        style: AppTypography.headlineLg(cs.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Access your communal savings securely.',
                        style: AppTypography.bodyLg(cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 40),

                      const _FieldLabel('Email or Phone Number'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _identifierController,
                        hint: 'Enter your credentials',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: AuthValidators.emailOrPhone,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(child: _FieldLabel('Password')),
                          TextButton(
                            onPressed: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: AppTypography.labelMd(cs.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _passwordController,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onSignIn(),
                        validator: AuthValidators.passwordLogin,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: cs.onSurfaceVariant,
                            size: 22,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 28),

                      AjoGradientButton(
                        label: 'Sign In',
                        suffixIcon: Icons.login_rounded,
                        isLoading: _submitting,
                        onPressed: _submitting ? null : _onSignIn,
                      ),
                      const SizedBox(height: 40),

                      Center(
                        child: Text(
                          'Or sign in with',
                          style: AppTypography.bodyMd(cs.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            color: cs.onSurface,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTypography.bodyMd(cs.onSurfaceVariant),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignupScreen(),
                                ),
                              ),
                              child: Text(
                                'Sign Up',
                                style: AppTypography.labelLg(cs.primary),
                              ),
                            ),
                          ],
                        ),
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

// --- Shared sub-widgets -------------------------------------------------------

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          ),
          Expanded(
            child: Center(
              child: Text('Login', style: AppTypography.titleLg(cs.onSurface)),
            ),
          ),
          const SizedBox(width: 48),
        ],
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
