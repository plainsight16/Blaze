import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../data/profile_http_api.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point – drives the 3-step KYC wizard
// ─────────────────────────────────────────────────────────────────────────────

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  /// 0 = BVN  |  1 = Bank Statement  |  2 = Trust Score
  int _step = 0;

  // Shared state passed forward between steps
  BankStatementSummary? _statement;
  int? _trustScore;

  void _goToStep(int step) => setState(() => _step = step);

  void _onBvnVerified() => _goToStep(1);

  void _onStatementAnalysed(BankStatementSummary statement) {
    setState(() {
      _statement = statement;
      _step = 2;
    });
  }

  void _onDone() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      0 => _BvnStep(onVerified: _onBvnVerified),
      1 => _BankStatementStep(onAnalysed: _onStatementAnalysed),
      _ => _TrustScoreStep(statement: _statement, onDone: _onDone),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared scaffold wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _KycScaffold extends StatelessWidget {
  const _KycScaffold({
    required this.child,
    this.showNavBar = false,
    this.activeTab = AjoTab.account,
    this.floatingButton,
    this.bottomContent,
  });

  final Widget child;
  final bool showNavBar;
  final AjoTab activeTab;
  final Widget? floatingButton;
  final Widget? bottomContent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: showNavBar ? AjoNavBar(active: activeTab) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            if (floatingButton != null || bottomContent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bottomContent != null) bottomContent!,
                    if (floatingButton != null) ...[
                      const SizedBox(height: 12),
                      floatingButton!,
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared app bar
// ─────────────────────────────────────────────────────────────────────────────

class _KycAppBar extends StatelessWidget {
  const _KycAppBar({required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: cs.onSurface, size: 20),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLg(cs.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
          // Shield badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.security_rounded, color: cs.primary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 – BVN Verification
// ─────────────────────────────────────────────────────────────────────────────

class _BvnStep extends StatefulWidget {
  const _BvnStep({required this.onVerified});
  final VoidCallback onVerified;

  @override
  State<_BvnStep> createState() => _BvnStepState();
}

class _BvnStepState extends State<_BvnStep> {
  final TextEditingController _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_ctrl.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BVN must be 11 digits')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await profileHttpApi.verifyBvn(_ctrl.text.trim());
      widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _KycScaffold(
      floatingButton: AjoGradientButton(
        label: 'Verify BVN',
        suffixIcon: Icons.arrow_forward_rounded,
        isLoading: _submitting,
        onPressed: _submitting ? null : _verify,
      ),
      bottomContent: _SecurityFooter(cs: cs),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _KycAppBar(title: 'Trust & Identity'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label
                  Text(
                    'STEP 2 OF 3',
                    style: AppTypography.labelSm(cs.primary).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Secure Your\nCollective Identity.',
                    style: AppTypography.headlineLg(cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajo requires your Bank Verification Number to ensure every '
                    'member of the savings pool is verified and trusted.',
                    style: AppTypography.bodyMd(cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),

                  // Encrypted Data card
                  _InfoCard(
                    icon: Icons.lock_rounded,
                    title: 'Encrypted Data',
                    body: 'Your BVN is never stored on our servers in plain text.',
                    accentColor: cs.primary,
                  ),
                  const SizedBox(height: 14),

                  // Identity Check card
                  _InfoCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Identity Check',
                    body: 'We only use this to confirm your legal name and DOB.',
                    accentColor: Colors.lightBlueAccent,
                  ),
                  const SizedBox(height: 28),

                  // BVN input section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENTER 11-DIGIT BVN',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ctrl,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          style: AppTypography.titleLg(cs.onSurface),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor:
                                cs.surfaceContainerHigh.withValues(alpha: 0.6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Icon(Icons.dialpad_rounded,
                                color: cs.onSurfaceVariant),
                            hintText: '• • • • • • • • • • •',
                            hintStyle:
                                AppTypography.titleMd(cs.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Tip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_rounded,
                                  color: cs.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTypography.bodySm(
                                        cs.onSurfaceVariant),
                                    children: [
                                      const TextSpan(text: 'Dial '),
                                      TextSpan(
                                        text: '*565*0#',
                                        style: AppTypography.bodySm(cs.primary)
                                            .copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const TextSpan(
                                        text:
                                            ' on your registered mobile number '
                                            "if you've forgotten your BVN.",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 – Bank Statement Analysis
// ─────────────────────────────────────────────────────────────────────────────

class _BankStatementStep extends StatefulWidget {
  const _BankStatementStep({required this.onAnalysed});
  final ValueChanged<BankStatementSummary> onAnalysed;

  @override
  State<_BankStatementStep> createState() => _BankStatementStepState();
}

class _BankStatementStepState extends State<_BankStatementStep> {
  bool _submitting = false;
  bool _analysing = false;
  double _incomeProgress = 0.0;

  // Simulated uploaded files list (replace with real file-picker logic)
  final List<String> _uploadedFiles = ['OCT_23.PDF', 'NOV_23.PDF'];

  Future<void> _analyseStatement() async {
    setState(() {
      _submitting = true;
      _analysing = true;
      _incomeProgress = 0.0;
    });

    // Animate progress bar while waiting
    final ticker = Stream.periodic(const Duration(milliseconds: 60), (i) => i)
        .take(20);
    await for (final _ in ticker) {
      if (!mounted) return;
      setState(() => _incomeProgress = (_incomeProgress + 0.05).clamp(0, 0.85));
    }

    try {
      final statement = await profileHttpApi.generateBankStatement();
      if (!mounted) return;
      setState(() => _incomeProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 400));
      widget.onAnalysed(statement);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _KycScaffold(
      showNavBar: true,
      activeTab: AjoTab.account,
      floatingButton: AjoGradientButton(
        label: 'Analyze Statement',
        suffixIcon: Icons.bar_chart_rounded,
        isLoading: _submitting,
        onPressed: _submitting ? null : _analyseStatement,
      ),
      bottomContent: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.labelSm(cs.onSurfaceVariant),
            children: [
              const TextSpan(text: 'By clicking Analyze, you agree to our '),
              TextSpan(
                text: 'Financial Privacy Policy',
                style: AppTypography.labelSm(cs.primary),
              ),
              const TextSpan(
                  text: '. Data is encrypted and deleted after analysis.'),
            ],
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _KycAppBar(title: 'Trust & Identity'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label
                  Text(
                    'VERIFICATION STEP 2 OF 3',
                    style: AppTypography.labelSm(cs.primary).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Bank Statement\n',
                          style: AppTypography.headlineLg(cs.onSurface),
                        ),
                        TextSpan(
                          text: 'Analysis',
                          style: AppTypography.headlineLg(cs.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To secure your placement in high-yield Ajo pools, we need '
                    'to verify your financial consistency over the last 6 months.',
                    style: AppTypography.bodyMd(cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),

                  // Link Bank Account (recommended)
                  _LinkBankCard(cs: cs),
                  const SizedBox(height: 20),

                  // Divider with label
                  Row(
                    children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR UPLOAD MANUALLY',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)
                              .copyWith(letterSpacing: 1.1),
                        ),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Upload PDF card
                  _UploadPdfCard(
                    cs: cs,
                    uploadedFiles: _uploadedFiles,
                    onAddMore: () {
                      // TODO: launch file picker and add to _uploadedFiles
                    },
                  ),
                  const SizedBox(height: 24),

                  // Analysis status
                  _AnalysisStatusCard(
                    cs: cs,
                    incomeProgress: _incomeProgress,
                    analysing: _analysing,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 – Trust Score result
// ─────────────────────────────────────────────────────────────────────────────

class _TrustScoreStep extends StatelessWidget {
  const _TrustScoreStep({required this.statement, required this.onDone});
  final BankStatementSummary? statement;
  final VoidCallback onDone;

  // Derive a mock trust score from the statement; replace with real API data.
  int get _score {
    if (statement == null) return 780;
    final ratio =
        (statement!.totalCredit / (statement!.totalDebit + 1)).clamp(0, 2);
    return (600 + (ratio * 180)).round().clamp(300, 1000);
  }

  String get _label {
    if (_score >= 750) return 'EXCELLENT';
    if (_score >= 600) return 'GOOD';
    return 'FAIR';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scoreRatio = _score / 1000.0;

    return _KycScaffold(
      showNavBar: true,
      activeTab: AjoTab.account,
      floatingButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AjoGradientButton(
            label: 'Continue to Dashboard',
            suffixIcon: Icons.arrow_forward_rounded,
            onPressed: onDone,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              // TODO: share achievement
            },
            child: Text(
              'Share My Achievement',
              style: AppTypography.titleSm(cs.primary),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _KycAppBar(title: 'Trust & Identity'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  // Confetti button (top right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.celebration_rounded,
                          color: Colors.amberAccent, size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Radial score gauge
                  _TrustScoreGauge(score: _score, ratio: scoreRatio, cs: cs),
                  const SizedBox(height: 24),

                  Text(
                    'Level Up! 🚀',
                    style: AppTypography.headlineMd(cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your financial integrity is outstanding. You\'re now eligible '
                    'for premium savings pools with lower entry barriers.',
                    style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Score breakdown label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: cs.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'SCORE BREAKDOWN',
                            style:
                                AppTypography.labelSm(cs.onSurfaceVariant)
                                    .copyWith(letterSpacing: 1.2),
                          ),
                        ),
                        Expanded(child: Divider(color: cs.outlineVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BVN card
                  _BreakdownCard(
                    icon: Icons.fingerprint_rounded,
                    title: 'BVN verification',
                    body: 'Identity confirmed through official government databases.',
                    badge: 'MATCHED',
                    badgeColor: cs.primary,
                    progress: 1.0,
                    showBar: true,
                    cs: cs,
                  ),
                  const SizedBox(height: 12),

                  // Income stability card
                  _BreakdownCard(
                    icon: Icons.account_balance_rounded,
                    title: 'Income stability',
                    body: 'Analysis of monthly cash flow patterns over 6 months.',
                    badge: 'CONSISTENT',
                    badgeColor: cs.primary,
                    progress: 0.82,
                    showBar: true,
                    cs: cs,
                  ),
                  const SizedBox(height: 12),

                  // Savings history card
                  _SavingsHistoryCard(cs: cs),
                  const SizedBox(height: 16),

                  // Boost card
                  _BoostCard(cs: cs),
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

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

// Info card (Encrypted / Identity Check)
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.titleSm(cs.onSurface)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.bodySm(cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// "Link Bank Account" card
class _LinkBankCard extends StatelessWidget {
  const _LinkBankCard({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded,
                  color: cs.onSurface, size: 28),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: AppTypography.labelSm(cs.primary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Link Bank Account',
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Instant verification via secure Open Banking. No passwords stored.',
              style: AppTypography.bodySm(cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              // TODO: launch Interswitch / Open Banking flow
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Connect via Interswitch',
                      style: AppTypography.titleSm(cs.onSurface)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded,
                      color: cs.onSurface, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Upload PDF card
class _UploadPdfCard extends StatelessWidget {
  const _UploadPdfCard({
    required this.cs,
    required this.uploadedFiles,
    required this.onAddMore,
  });
  final ColorScheme cs;
  final List<String> uploadedFiles;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.upload_file_rounded, color: cs.onSurface, size: 26),
          ),
          const SizedBox(height: 12),
          Text('Upload PDF Statements',
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Drag and drop your last 6 months of statements here. Max 10MB per file.',
            style: AppTypography.bodySm(cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // File chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in uploadedFiles)
                _FileChip(name: f, cs: cs),
              GestureDetector(
                onTap: onAddMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.50)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: cs.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('ADD MORE',
                          style: AppTypography.labelSm(cs.primary).copyWith(
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.cs});
  final String name;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: cs.primary, size: 14),
          const SizedBox(width: 6),
          Text(name,
              style: AppTypography.labelSm(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Analysis status card
class _AnalysisStatusCard extends StatelessWidget {
  const _AnalysisStatusCard({
    required this.cs,
    required this.incomeProgress,
    required this.analysing,
  });
  final ColorScheme cs;
  final double incomeProgress;
  final bool analysing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Analysis Status',
                  style: AppTypography.titleSm(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(
                analysing ? 'RUNNING AI MODELS' : 'READY',
                style: AppTypography.labelSm(cs.primary).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressRow(
            label: 'INCOME CONSISTENCY',
            progress: incomeProgress,
            trailing: incomeProgress > 0
                ? '${(incomeProgress * 100).round()}% COMPLETE'
                : null,
            cs: cs,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'SPENDING HABIT MAPPING',
            progress: 0,
            trailing: incomeProgress > 0 ? 'WAITING...' : null,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.progress,
    required this.cs,
    this.trailing,
  });
  final String label;
  final double progress;
  final ColorScheme cs;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.labelSm(cs.onSurfaceVariant).copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            if (trailing != null)
              Text(trailing!,
                  style: AppTypography.labelSm(cs.primary)
                      .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHigh,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

// ─── Trust Score Gauge ────────────────────────────────────────────────────────

class _TrustScoreGauge extends StatelessWidget {
  const _TrustScoreGauge({
    required this.score,
    required this.ratio,
    required this.cs,
  });
  final int score;
  final double ratio;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _GaugePainter(
              ratio: ratio,
              trackColor: cs.surfaceContainerHigh,
              fillColor: cs.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('YOUR TRUST SCORE',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(letterSpacing: 1.0)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$score',
                      style: AppTypography.headlineLg(cs.onSurface).copyWith(
                          fontSize: 52, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: '/1000',
                      style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: cs.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('EXCELLENT',
                      style: AppTypography.labelSm(cs.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          // +12 pts badge
          Positioned(
            left: 0,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: cs.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('+12 pts',
                      style: AppTypography.labelSm(cs.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.ratio,
    required this.trackColor,
    required this.fillColor,
  });
  final double ratio;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = math.pi * 0.75;
    const sweepMax = math.pi * 1.5;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = fillColor
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepMax, false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepMax * ratio, false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.ratio != ratio;
}

// ─── Score Breakdown cards ────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    required this.badgeColor,
    required this.progress,
    required this.showBar,
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String body;
  final String badge;
  final Color badgeColor;
  final double progress;
  final bool showBar;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge,
                    style: AppTypography.labelSm(badgeColor)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: AppTypography.titleSm(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: AppTypography.bodySm(cs.onSurfaceVariant)),
          if (showBar) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHigh,
                color: cs.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavingsHistoryCard extends StatelessWidget {
  const _SavingsHistoryCard({required this.cs});
  final ColorScheme cs;

  static const List<double> _bars = [0.5, 0.65, 0.72, 0.80, 0.88, 0.94];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Savings history',
                  style: AppTypography.titleSm(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('94%',
                      style: AppTypography.titleMd(cs.primary)
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text('RELIABILITY\nRATE',
                      style: AppTypography.labelSm(cs.onSurfaceVariant)
                          .copyWith(fontSize: 9, height: 1.2),
                      textAlign: TextAlign.right),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Participation and reliability in communal pools.',
              style: AppTypography.bodySm(cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          // Mini bar chart
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _bars
                  .map(
                    (h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          heightFactor: h,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostCard extends StatelessWidget {
  const _BoostCard({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lightbulb_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Boost your score further',
                    style: AppTypography.titleSm(cs.onSurface)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Completing a 30-day savings cycle without missing a contribution '
                  'will add approximately 45 points to your score.',
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Security footer
class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, color: cs.onSurfaceVariant, size: 14),
        const SizedBox(width: 6),
        Text(
          'Your financial data is protected by bank-grade security standards (AES-256).',
          style: AppTypography.labelSm(cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy sub-widgets kept for reference (used nowhere now – safe to delete)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.badge});
  final String title;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title, style: AppTypography.titleMd(cs.onSurface)),
        const Spacer(),
        badge,
      ],
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({required this.required});
  final bool required;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: required
            ? cs.primary.withValues(alpha: 0.15)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: required
              ? cs.primary.withValues(alpha: 0.40)
              : cs.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        required ? 'Required' : 'OPTIONAL',
        style: AppTypography.labelSm(
          required ? cs.primary : cs.onSurfaceVariant,
        ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.onTap,
    required this.subtitle,
    required this.hint,
  });
  final VoidCallback onTap;
  final String subtitle;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: cs.primary.withValues(alpha: 0.50),
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.upload_file_rounded,
                    color: cs.primary, size: 26),
              ),
              const SizedBox(height: 14),
              Text('Click to upload or drag and drop',
                  style: AppTypography.titleSm(cs.onSurface),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(hint,
                  style: AppTypography.labelSm(cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadedFile extends StatelessWidget {
  const _UploadedFile({required this.name, required this.onRemove});
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTypography.bodyMd(cs.onSurface))),
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CompactUploadRow extends StatelessWidget {
  const _CompactUploadRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSm(cs.onSurface)),
                Text(subtitle, style: AppTypography.labelSm(cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: uploaded
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: uploaded
                      ? cs.primary.withValues(alpha: 0.40)
                      : cs.primary,
                ),
              ),
              child: Text(
                uploaded ? 'Uploaded' : 'Upload',
                style: AppTypography.labelMd(cs.primary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashGap = 5.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashGap;
        if (draw) {
          canvas.drawPath(
              metric.extractPath(distance, distance + len), paint);
        }
        distance += math.min(len, metric.length - distance);
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}