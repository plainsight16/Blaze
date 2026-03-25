import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer sent (mock).')),
    );
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
          'Transfer',
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
              children: [
                Text(
                  'Send money to another member.',
                  style: AppTypography.bodyMd(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _recipientController,
                  decoration: InputDecoration(
                    hintText: 'Recipient (name or phone)',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if ((v?.trim() ?? '').isEmpty) return 'Enter a recipient';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Amount (e.g. 5000)',
                    prefixIcon: const Icon(Icons.money_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    final digits = t.replaceAll(RegExp(r'\\D'), '');
                    if (digits.isEmpty) return 'Enter an amount';
                    final n = int.tryParse(digits);
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const Spacer(),
                AjoGradientButton(
                  label: 'Send Transfer',
                  isLoading: _busy,
                  suffixIcon: Icons.arrow_forward_rounded,
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

