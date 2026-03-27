class WalletInfo {
  const WalletInfo({
    required this.id,
    required this.status,
    this.accountName,
    this.accountNumber,
    this.bankName,
  });

  final String id;
  final String status;
  final String? accountName;
  final String? accountNumber;
  final String? bankName;

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_started',
      accountName: json['account_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      bankName: json['bank_name']?.toString(),
    );
  }
}

class KycInfo {
  const KycInfo({
    required this.status,
    required this.nextStep,
    required this.bvnVerified,
    required this.walletProvisioned,
  });

  final String status;
  final String nextStep;
  final bool bvnVerified;
  final bool walletProvisioned;

  factory KycInfo.fromJson(Map<String, dynamic> json) {
    return KycInfo(
      status: json['status']?.toString() ?? 'not_started',
      nextStep: json['next_step']?.toString() ?? 'verify_bvn',
      bvnVerified: json['bvn_verified'] == true,
      walletProvisioned: json['wallet_provisioned'] == true,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.kyc,
    this.wallet,
  });

  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final WalletInfo? wallet;
  final KycInfo kyc;

  String get fullName => '$firstName $lastName'.trim();
  String get handle => '@${username.toUpperCase()}';
  double get completion {
    int score = 2;
    if (kyc.bvnVerified) score += 1;
    if (kyc.walletProvisioned) score += 1;
    return score / 4;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final walletJson = json['wallet'];
    final kycJson = json['kyc'] as Map<String, dynamic>? ?? const {};
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      wallet: walletJson is Map<String, dynamic> ? WalletInfo.fromJson(walletJson) : null,
      kyc: KycInfo.fromJson(kycJson),
    );
  }
}
