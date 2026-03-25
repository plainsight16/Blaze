/// Simulated auth API — replace with real HTTP calls later.
/// Uses [Future.delayed] so loading states are visible during development.
class MockAuthException implements Exception {
  MockAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MockAuthApi {
  MockAuthApi({this.latency = const Duration(milliseconds: 900)});

  final Duration latency;

  /// Sign in. Fails when password is exactly `fail` (demo).
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final id = identifier.trim();
    if (id.isEmpty) {
      throw MockAuthException('Enter your email or phone');
    }
    if (password == 'fail') {
      throw MockAuthException('Invalid credentials. Try again.');
    }
  }

  /// Register. Fails when email contains `taken` (demo conflict).
  Future<void> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    if (email.toLowerCase().contains('taken')) {
      throw MockAuthException('This email is already registered.');
    }
    if (fullName.trim().length < 2) {
      throw MockAuthException('Enter your full name');
    }
    if (password.length < 8) {
      throw MockAuthException('Password is too short');
    }
  }

  /// Ask server to resend OTP (mock).
  Future<void> requestOtpResend() async {
    await Future<void>.delayed(latency ~/ 2);
  }

  /// Verify OTP. Fails for `111111` (demo invalid code).
  Future<void> verifyOtp(String code) async {
    await Future<void>.delayed(latency);
    final c = code.trim();
    if (c.length != 6) {
      throw MockAuthException('Enter the 6-digit code');
    }
    if (c == '111111') {
      throw MockAuthException('Invalid verification code');
    }
  }

  /// Request a password reset code (mock).
  Future<void> requestPasswordReset({required String identifier}) async {
    await Future<void>.delayed(latency);
    final id = identifier.trim();
    if (id.isEmpty) {
      throw MockAuthException('Enter your email or phone');
    }
  }

  /// Verify password reset OTP. Fails for `111111` (demo).
  Future<void> verifyPasswordResetOtp(String code) async {
    await Future<void>.delayed(latency);
    final c = code.trim();
    if (c.length != 6) {
      throw MockAuthException('Enter the 6-digit code');
    }
    if (c == '111111') {
      throw MockAuthException('Invalid reset code');
    }
  }

  /// Set the new password (mock).
  Future<void> setNewPassword({required String password}) async {
    await Future<void>.delayed(latency);
    if (password.length < 8) {
      throw MockAuthException('Password is too short');
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      throw MockAuthException('Password must include a special character');
    }
  }
}

/// Default mock instance for screens (swap for DI later).
final mockAuthApi = MockAuthApi();
