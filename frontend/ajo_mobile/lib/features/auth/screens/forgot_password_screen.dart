import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../auth_validators.dart';
import 'reset_password_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final identifier = _identifierController.text.trim();
      if (!identifier.contains('@')) {
        throw ApiException('Only email password reset is supported yet.');
      }

      await authHttpApi.forgotPassword(email: identifier);

      if (!mounted) return;
      final mask = _maskedIdentifier(identifier);
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordOtpScreen(
            identifier: identifier,
            contactMask: mask,
          ),
        ),
      );
    } on ApiException catch (e) {
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
    final digits = raw.replaceAll(RegExp(r'\\D'), '');
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
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: cs.onSurface),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Reset Password',
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
                      const SizedBox(height: 32),
                      Text(
                        'Enter your email or phone number',
                        style: AppTypography.headlineMd(cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We will send a 6-digit reset code.',
                        style: AppTypography.bodyMd(cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      _FieldLabel('Email or Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          hintText: 'Enter your email or phone',
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: AuthValidators.emailOrPhone,
                      ),
                      const SizedBox(height: 28),
                      AjoGradientButton(
                        label: 'Send Reset Code',
                        suffixIcon: Icons.send_rounded,
                        isLoading: _submitting,
                        onPressed: _submitting ? null : _requestReset,
                      ),
                      const SizedBox(height: 20),
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
      style: AppTypography.labelMd(cs.onSurfaceVariant).copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

