import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../models/mock_user_profile.dart';

// ─── Entry Point ──────────────────────────────────────────────────────────────

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _enteredAmount = 0;

  // Mock linked accounts
  final List<_BankAccount> _accounts = const [
    _BankAccount(bankName: 'Chase Bank', last4: '8829'),
    _BankAccount(bankName: 'GTBank', last4: '4421'),
    _BankAccount(bankName: 'Access Bank', last4: '3310'),
  ];

  late _BankAccount _selectedAccount;

  @override
  void initState() {
    super.initState();
    _selectedAccount = _accounts.first;
  }

  double get _availableBalance => mockUserProfile.walletBalance;

  void _applyPercentage(double pct) {
    final amt = (_availableBalance * pct).floorToDouble();
    setState(() {
      _enteredAmount = amt;
      _amountController.text = amt.toStringAsFixed(2);
    });
  }

  void _applyMax() => _applyPercentage(1.0);

  bool get _hasValidAmount =>
      _enteredAmount > 0 && _enteredAmount <= _availableBalance;

  void _onAmountChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0;
    setState(() => _enteredAmount = parsed);
  }

  void _confirmWithdrawal() {
    if (!_hasValidAmount) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewWithdrawalScreen(
          amount: _enteredAmount,
          account: _selectedAccount,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final balanceParts = _availableBalance.toStringAsFixed(2).split('.');
    final balanceInt = balanceParts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    final amountParts = _enteredAmount.toStringAsFixed(2).split('.');
    final amountInt = amountParts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    // Simple fee logic: 0.29% capped at ₦500
    final fee =
        (_enteredAmount * 0.0029).clamp(0, 500).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainer,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.menu_rounded, color: cs.onSurface, size: 24),
            const SizedBox(width: 12),
            Text('Ajo', style: AppTypography.titleLg(cs.primary)),
            const Spacer(),
            Icon(Icons.notifications_outlined,
                color: cs.onSurfaceVariant, size: 24),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Withdraw Funds',
                style: AppTypography.displaySm(cs.onSurface)),
            const SizedBox(height: 6),
            Text(
              'Move your savings to your linked bank account instantly.',
              style: AppTypography.bodySm(cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // ── Available Balance Card ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: cs.primary, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVAILABLE BALANCE',
                      style: AppTypography.labelSm(cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₦$balanceInt',
                          style: AppTypography.displayMd(cs.primary),
                        ),
                        TextSpan(
                          text: '.${balanceParts.last}',
                          style: AppTypography.titleLg(cs.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Destination Account ──
            Text('Destination Account',
                style: AppTypography.titleSm(cs.onSurface)),
            const SizedBox(height: 10),
            _AccountSelector(
              accounts: _accounts,
              selected: _selectedAccount,
              onChanged: (a) => setState(() => _selectedAccount = a),
            ),
            const SizedBox(height: 24),

            // ── Amount Input ──
            Text('Amount to Withdraw',
                style: AppTypography.titleSm(cs.onSurface)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Text('₦', style: AppTypography.titleLg(cs.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      onChanged: _onAmountChanged,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      style: AppTypography.displaySm(cs.onSurface),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: AppTypography.displaySm(
                            cs.onSurface.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _PercentageChip(
                    label: '25%', onTap: () => _applyPercentage(0.25)),
                const SizedBox(width: 8),
                _PercentageChip(
                    label: '50%', onTap: () => _applyPercentage(0.50)),
                const SizedBox(width: 8),
                _PercentageChip(label: 'MAX', onTap: _applyMax),
                const Spacer(),
                Text('Fee: ₦$fee',
                    style: AppTypography.bodySm(cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Transfer Details ──
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _TransferDetailRow(
                    label: 'Estimated Arrival',
                    value: 'Instant (Within 30 mins)',
                    valueColor: cs.onSurface,
                  ),
                  const SizedBox(height: 12),
                  _TransferDetailRow(
                    label: 'Transfer Method',
                    value: 'Real-Time Rails',
                    valueColor: cs.onSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Confirm Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _hasValidAmount ? _confirmWithdrawal : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  disabledBackgroundColor:
                      cs.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Confirm Withdrawal',
                    style: AppTypography.labelLg(cs.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _BankAccount {
  const _BankAccount({required this.bankName, required this.last4});
  final String bankName;
  final String last4;

  String get display => '$bankName ••••  $last4';
}

class _AccountSelector extends StatelessWidget {
  const _AccountSelector({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  final List<_BankAccount> accounts;
  final _BankAccount selected;
  final ValueChanged<_BankAccount> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_BankAccount>(
      onSelected: onChanged,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => accounts
          .map(
            (a) => PopupMenuItem<_BankAccount>(
              value: a,
              child: Row(
                children: [
                  Icon(Icons.account_balance_outlined,
                      color: cs.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(a.display,
                      style: AppTypography.bodySm(cs.onSurface)),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.account_balance_outlined,
                color: cs.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(selected.display,
                  style: AppTypography.titleSm(cs.onSurface)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: cs.onSurfaceVariant, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PercentageChip extends StatelessWidget {
  const _PercentageChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppTypography.labelSm(cs.onSurface)),
      ),
    );
  }
}

class _TransferDetailRow extends StatelessWidget {
  const _TransferDetailRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySm(cs.onSurfaceVariant)),
        Text(value, style: AppTypography.titleSm(valueColor)),
      ],
    );
  }
}

// ─── Review Withdrawal Screen ─────────────────────────────────────────────────

class ReviewWithdrawalScreen extends StatefulWidget {
  const ReviewWithdrawalScreen({
    super.key,
    required this.amount,
    required this.account,
  });

  final double amount;
  final _BankAccount account;

  @override
  State<ReviewWithdrawalScreen> createState() =>
      _ReviewWithdrawalScreenState();
}

class _ReviewWithdrawalScreenState extends State<ReviewWithdrawalScreen> {
  bool _acknowledged = false;

  double get _fee => (widget.amount * 0.0029).clamp(0, 500);
  double get _netAmount => widget.amount - _fee;

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final int = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₦$int.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Review Withdrawal',
            style: AppTypography.titleMd(cs.onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('Ajo', style: AppTypography.titleLg(cs.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total to Receive hero card ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2B18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined,
                        color: cs.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text('TOTAL TO RECEIVE',
                      style: AppTypography.labelSm(cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(_fmt(_netAmount),
                      style: AppTypography.displayMd(cs.onSurface)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Withdrawal Amount ──
            _ReviewRow(
              label: 'WITHDRAWAL AMOUNT',
              value: _fmt(widget.amount),
              trailingIcon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),

            // ── Destination Bank ──
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESTINATION BANK',
                            style:
                                AppTypography.labelSm(cs.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Text(widget.account.bankName,
                            style: AppTypography.titleSm(cs.onSurface)),
                        Text(
                          '•••• ${widget.account.last4}',
                          style: AppTypography.bodySm(cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.account_balance_outlined,
                      color: cs.primary, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Transaction Fee ──
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_outlined,
                        color: Color(0xFFEB5757), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRANSACTION FEE',
                            style:
                                AppTypography.labelSm(cs.onSurfaceVariant)),
                        Text('Standard Processing',
                            style: AppTypography.titleSm(cs.onSurface)),
                      ],
                    ),
                  ),
                  Text(
                    '-${_fmt(_fee)}',
                    style: AppTypography.titleSm(const Color(0xFFEB5757)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Final Amount ──
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FINAL AMOUNT TO RECEIVE',
                            style: AppTypography.labelSm(cs.primary)),
                        const SizedBox(height: 4),
                        Text(_fmt(_netAmount),
                            style: AppTypography.titleLg(cs.onSurface)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text('GUARANTEED',
                        style: AppTypography.labelSm(cs.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Acknowledgment ──
            GestureDetector(
              onTap: () =>
                  setState(() => _acknowledged = !_acknowledged),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _acknowledged
                          ? cs.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _acknowledged
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        width: 1.5,
                      ),
                    ),
                    child: _acknowledged
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I acknowledge that funds typically arrive within 1-3 business days. '
                      'By confirming, I authorize Ajo to initiate this transfer to my linked bank account.',
                      style: AppTypography.bodySm(cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Confirm Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _acknowledged
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => WithdrawalInitiatedScreen(
                              amount: widget.amount,
                              netAmount: _netAmount,
                              fee: _fee,
                              account: widget.account,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  disabledBackgroundColor:
                      cs.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Confirm Withdrawal',
                        style: AppTypography.labelLg(cs.onPrimary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'CANCEL REQUEST',
                  style: AppTypography.labelMd(cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.trailingIcon,
  });

  final String label;
  final String value;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelSm(cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.titleMd(cs.onSurface)),
              ],
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: cs.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}

// ─── Withdrawal Initiated Screen ──────────────────────────────────────────────

class WithdrawalInitiatedScreen extends StatelessWidget {
  const WithdrawalInitiatedScreen({
    super.key,
    required this.amount,
    required this.netAmount,
    required this.fee,
    required this.account,
  });

  final double amount;
  final double netAmount;
  final double fee;
  final _BankAccount account;

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₦$intPart.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const refId = '#TXN-9982104';

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainer,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.menu_rounded, color: cs.onSurface, size: 24),
            const SizedBox(width: 12),
            Text('Ajo', style: AppTypography.titleLg(cs.primary)),
            const Spacer(),
            Icon(Icons.notifications_outlined,
                color: cs.onSurfaceVariant, size: 24),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          children: [
            const Spacer(),

            // ── Success Icon ──
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
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
            const SizedBox(height: 28),
            Text('Withdrawal Initiated',
                style: AppTypography.displaySm(cs.onSurface),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Your funds are being processed and will arrive in your account shortly.',
              style: AppTypography.bodySm(cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const Spacer(),

            // ── Details Card ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: cs.primary, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL AMOUNT',
                                style: AppTypography.labelSm(
                                    cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(_fmt(netAmount),
                                style:
                                    AppTypography.titleLg(cs.primary)),
                          ],
                        ),
                      ),
                      Icon(Icons.receipt_long_outlined,
                          color: cs.onSurfaceVariant, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InitiatedDetailRow(
                    label: 'Destination',
                    value:
                        'Bank Account ••••  ${account.last4}',
                  ),
                  const SizedBox(height: 10),
                  _InitiatedDetailRow(
                    label: 'Processing Fee',
                    value: _fmt(fee),
                  ),
                  const SizedBox(height: 10),
                  _InitiatedDetailRow(
                    label: 'Reference ID',
                    value: refId,
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ── Back to Wallet ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Back to Wallet',
                    style: AppTypography.labelLg(cs.onPrimary)),
              ),
            ),
            const SizedBox(height: 16),

            // ── Download Receipt ──
            TextButton(
              onPressed: () {
                // TODO: implement download receipt
              },
              child: Text(
                'DOWNLOAD RECEIPT',
                style: AppTypography.labelMd(cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitiatedDetailRow extends StatelessWidget {
  const _InitiatedDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySm(cs.onSurfaceVariant)),
        Text(value, style: AppTypography.titleSm(cs.onSurface)),
      ],
    );
  }
}