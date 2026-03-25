/// Shared validators for auth forms. Keep messages short for mobile.
class AuthValidators {
  AuthValidators._();

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? fullName(String? value) {
    final err = requiredField(value, 'Name');
    if (err != null) return err;
    if (value!.trim().length < 2) {
      return 'Enter your full name';
    }
    return null;
  }

  static String? email(String? value) {
    final err = requiredField(value, 'Email');
    if (err != null) return err;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// Digits only, at least 10 digits (local or international).
  static String? phone(String? value) {
    final err = requiredField(value, 'Phone number');
    if (err != null) return err;
    final digits = _digitsOnly(value!);
    if (digits.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Login field: valid email OR phone.
  static String? emailOrPhone(String? value) {
    final err = requiredField(value, 'Email or phone');
    if (err != null) return err;
    final t = value!.trim();
    if (t.contains('@')) {
      if (!_emailPattern.hasMatch(t)) return 'Enter a valid email';
    } else {
      final digits = _digitsOnly(t);
      if (digits.length < 10) return 'Enter a valid phone number';
    }
    return null;
  }

  static String? passwordLogin(String? value) {
    final err = requiredField(value, 'Password');
    if (err != null) return err;
    if (value!.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Signup rule: 8+ chars and at least one special character.
  static String? passwordSignup(String? value) {
    final err = requiredField(value, 'Password');
    if (err != null) return err;
    if (value!.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'Add a special character (!@#\$…)';
    }
    return null;
  }

  static String? otpCode(String digits, int length) {
    if (digits.length != length) {
      return 'Enter the full code';
    }
    return null;
  }

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String _digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');
}
