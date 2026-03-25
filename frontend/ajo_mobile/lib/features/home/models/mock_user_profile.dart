/// Mock user profile data used across Home / Wallet / Account UI.
/// Replace with real API + auth later.
class MockUserProfile {
  const MockUserProfile({
    required this.fullName,
    required this.handle,
    required this.avatarInitials,
    required this.profileCompletion,
    required this.walletBalance,
    required this.totalPoolBalance,
    required this.kycStatusLabel,
    required this.kycInProgress,
  });

  final String fullName;
  final String handle;
  final String avatarInitials;

  /// 0.0 - 1.0
  final double profileCompletion;

  final double walletBalance;
  final double totalPoolBalance;

  final String kycStatusLabel;
  final bool kycInProgress;
}

const mockUserProfile = MockUserProfile(
  fullName: 'Ayo Johnson',
  handle: '@AYOJOHNSON',
  avatarInitials: 'AJ',
  profileCompletion: 0.75,
  walletBalance: 250000.00,
  totalPoolBalance: 250000.00,
  kycStatusLabel: 'KYC Verification (In Progress)',
  kycInProgress: true,
);

String mockUserBalanceText(double amount) => '₦${amount.toStringAsFixed(2)}';

