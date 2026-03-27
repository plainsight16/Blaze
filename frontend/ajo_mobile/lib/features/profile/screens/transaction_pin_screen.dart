import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';



class TransactionPinScreen extends StatefulWidget {
  const TransactionPinScreen({super.key});

  @override
  State<TransactionPinScreen> createState() => _TransactionPinScreenState();
}

class _TransactionPinScreenState extends State<TransactionPinScreen> {
  String _firstPin = '';

  void _onFirstPinComplete(String pin) {
    setState(() => _firstPin = pin);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConfirmPinScreen(
          firstPin: pin,
          onSuccess: _onPinConfirmed,
        ),
      ),
    );
  }

  void _onPinConfirmed() {
    // PIN successfully set — pop all PIN screens and show snack.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction PIN set successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PinScaffold(
      title: 'Set Transaction PIN',
      subtitle: 'Create a 4-digit PIN to secure your\ntransfers and withdrawals.',
      showShieldIcon: false,
      ctaLabel: 'Continue',
      footerLabel: 'SECURELY ENCRYPTED BY AJO VERIDIAN',
      onComplete: _onFirstPinComplete,
    );
  }
}

// ─── Confirm PIN Screen ───────────────────────────────────────────────────────

class _ConfirmPinScreen extends StatefulWidget {
  const _ConfirmPinScreen({
    required this.firstPin,
    required this.onSuccess,
  });

  final String firstPin;
  final VoidCallback onSuccess;

  @override
  State<_ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<_ConfirmPinScreen> {
  bool _mismatch = false;
  int _rebuildKey = 0; // forces _PinScaffold to reset its internal pin state

  void _onConfirm(String pin) {
    if (pin == widget.firstPin) {
      widget.onSuccess();
    } else {
      setState(() {
        _mismatch = true;
        _rebuildKey++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinScaffold(
      key: ValueKey(_rebuildKey),
      title: 'Confirm PIN',
      subtitle: 'Please re-enter your 4-digit transaction\nPIN to confirm.',
      showShieldIcon: true,
      ctaLabel: 'Secure My Account',
      ctaPrimary: true,
      footerLabel: null,
      onComplete: _onConfirm,
      errorState: _mismatch,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED PIN SCAFFOLD
// ══════════════════════════════════════════════════════════════════════════════

class _PinScaffold extends StatefulWidget {
  const _PinScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.showShieldIcon,
    required this.ctaLabel,
    this.ctaPrimary = false,
    this.footerLabel,
    required this.onComplete,
    this.errorState = false,
  });

  final String title;
  final String subtitle;
  final bool showShieldIcon;
  final String ctaLabel;
  final bool ctaPrimary;
  final String? footerLabel;
  final ValueChanged<String> onComplete;
  final bool errorState;

  @override
  State<_PinScaffold> createState() => _PinScaffoldState();
}

class _PinScaffoldState extends State<_PinScaffold>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(_PinScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorState && !oldWidget.errorState) {
      _pin = '';
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == _pinLength) {
      // Small delay so the last dot animates in before callback
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) widget.onComplete(_pin);
      });
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const bg = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: cs.primary, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Security',
                          style: AppTypography.titleMd(Colors.white)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 22),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1A1A1A)),

            Expanded(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Shield icon (confirm step only) ──────────────────
                  if (widget.showShieldIcon) ...[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withValues(alpha: 0.15),
                      ),
                      child: Icon(Icons.shield_rounded,
                          color: cs.primary, size: 38),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 8),

                  // ── Title + subtitle ──────────────────────────────────
                  Text(
                    widget.title,
                    style: AppTypography.headlineSm(Colors.white)
                        .copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.subtitle,
                    style: AppTypography.bodySm(Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── PIN dots ──────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final shake =
                          (_shakeAnim.value * 8 * (0.5 - _shakeAnim.value))
                              .clamp(-8.0, 8.0);
                      return Transform.translate(
                        offset: Offset(shake * 4, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pinLength, (i) {
                        final filled = i < _pin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 10),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? cs.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: filled
                                  ? cs.primary
                                  : Colors.white30,
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Numpad ────────────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: _Numpad(
                      onKey: _onKey,
                      onDelete: _onDelete,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── CTA button ────────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _pin.length == _pinLength ? () {} : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.ctaPrimary
                              ? cs.primary
                              : const Color(0xFF1E1E1E),
                          foregroundColor: widget.ctaPrimary
                              ? cs.onPrimary
                              : Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF1E1E1E),
                          disabledForegroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(widget.ctaLabel,
                            style: AppTypography.labelLg(
                              _pin.length == _pinLength
                                  ? (widget.ctaPrimary
                                      ? cs.onPrimary
                                      : Colors.white)
                                  : Colors.grey,
                            )),
                      ),
                    ),
                  ),

                  if (widget.footerLabel != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.footerLabel!,
                      style: AppTypography.labelSm(Colors.grey)
                          .copyWith(
                              fontSize: 10, letterSpacing: 1.2),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Numpad ─────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onKey, required this.onDelete});

  final ValueChanged<String> onKey;
  final VoidCallback onDelete;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Row(
          children: row.map((key) {
            if (key.isEmpty) return const Expanded(child: SizedBox());

            if (key == 'del') {
              return Expanded(
                child: _NumKey(
                  child: Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                  onTap: onDelete,
                ),
              );
            }

            return Expanded(
              child: _NumKey(
                child: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => onKey(key),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }
}