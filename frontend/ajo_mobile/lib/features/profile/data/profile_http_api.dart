import '../../../core/network/api_client.dart';
import '../../home/models/user_profile.dart';

class KycRequirements {
  const KycRequirements({
    required this.nextStep,
    required this.bannerTitle,
    required this.bannerMessage,
  });

  final String nextStep;
  final String? bannerTitle;
  final String? bannerMessage;

  factory KycRequirements.fromJson(Map<String, dynamic> json) {
    return KycRequirements(
      nextStep: json['next_step']?.toString() ?? 'verify_bvn',
      bannerTitle: json['banner_title']?.toString(),
      bannerMessage: json['banner_message']?.toString(),
    );
  }
}

class BankStatementSummary {
  const BankStatementSummary({
    required this.averageBalance,
    required this.totalCredit,
    required this.totalDebit,
  });

  final double averageBalance;
  final double totalCredit;
  final double totalDebit;

  factory BankStatementSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return BankStatementSummary(
      averageBalance: toDouble(json['average_balance']),
      totalCredit: toDouble(json['total_credit']),
      totalDebit: toDouble(json['total_debit']),
    );
  }
}

class ProfileHttpApi {
  ProfileHttpApi({required this.client});

  final ApiClient client;

  Future<UserProfile> getMe() async {
    final res = await client.getJson('/user/me');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /user/me response', body: res);
    }
    return UserProfile.fromJson(res);
  }

  Future<WalletInfo> provisionWallet() async {
    final res = await client.postJsonNoBody('/wallet/provision');
    return WalletInfo.fromJson(res);
  }

  Future<KycRequirements> getKycRequirements() async {
    final res = await client.getJson('/kyc/requirements');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /kyc/requirements response', body: res);
    }
    return KycRequirements.fromJson(res);
  }

  Future<void> verifyBvn(String bvn) async {
    await client.postJson('/kyc/verify-bvn', body: <String, dynamic>{'bvn': bvn});
  }

  Future<BankStatementSummary> generateBankStatement() async {
    final res = await client.postJsonNoBody('/kyc/bank-statement');
    return BankStatementSummary.fromJson(res);
  }

  Future<BankStatementSummary> getBankStatement() async {
    final res = await client.getJson('/kyc/bank-statement');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /kyc/bank-statement response', body: res);
    }
    return BankStatementSummary.fromJson(res);
  }
}
