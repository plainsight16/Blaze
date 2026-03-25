import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const transactions = [
      _Tx(title: 'Weekly Contribution', date: 'Oct 12, 2023 • 10:45 AM', amount: '-₦5,000', isDebit: true),
      _Tx(title: 'Deposit from Bank', date: 'Oct 10, 2023 • 02:30 PM', amount: '+₦50,000', isDebit: false),
      _Tx(title: 'Payout - Housing Fund', date: 'Oct 08, 2023 • 09:12 AM', amount: '+₦120,000', isDebit: false),
      _Tx(title: 'Withdrawal (Partial)', date: 'Oct 01, 2023 • 08:12 AM', amount: '-₦12,000', isDebit: true),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transactions',
          style: AppTypography.titleMd(cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final tx = transactions[i];
            final color = tx.isDebit ? const Color(0xFFEB5757) : cs.primary;
            final icon = tx.isDebit
                ? Icons.arrow_outward_rounded
                : Icons.arrow_downward_rounded;

            return Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tx.isDebit
                          ? const Color(0xFF3D1A1A)
                          : cs.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: AppTypography.titleSm(cs.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx.date,
                          style: AppTypography.bodySm(cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tx.amount,
                    style: AppTypography.titleSm(color),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tx {
  const _Tx({
    required this.title,
    required this.date,
    required this.amount,
    required this.isDebit,
  });

  final String title;
  final String date;
  final String amount;
  final bool isDebit;
}

