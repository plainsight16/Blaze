import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';

class TransactionPinScreen extends StatefulWidget {
  const TransactionPinScreen({super.key});

  @override
  State<TransactionPinScreen> createState() => _TransactionPinScreenState();
}

class _TransactionPinScreenState extends State<TransactionPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction PIN updated (mock).')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transaction PIN',
          style: AppTypography.titleMd(cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set or change your transaction PIN (4-6 digits).',
                  style: AppTypography.bodyMd(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Text(
                  'New PIN',
                  style: AppTypography.labelMd(cs.onSurfaceVariant)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    final digits = t.replaceAll(RegExp(r'\\D'), '');
                    if (digits.isEmpty) return 'Enter a PIN';
                    if (digits.length < 4 || digits.length > 6) {
                      return 'PIN must be 4 to 6 digits';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. 1234',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 20),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirm PIN',
                  style: AppTypography.labelMd(cs.onSurfaceVariant)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final confirm = v?.trim() ?? '';
                    if (confirm.isEmpty) return 'Confirm your PIN';
                    if (confirm != _pinController.text.trim()) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Re-enter PIN',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 20),
                  ),
                ),
                const Spacer(),
                AjoGradientButton(
                  label: 'Save PIN',
                  suffixIcon: Icons.check_rounded,
                  isLoading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

