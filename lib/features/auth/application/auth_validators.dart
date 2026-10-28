/// Form validators mirroring the API rules. They return a French message or null.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'\d');
  static final _code = RegExp(r'^\d{6}$');

  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Saisissez votre email.';
    }
    if (email.length > 254 || !_email.hasMatch(email)) {
      return 'Cet email n’est pas valide.';
    }
    return null;
  }

  /// Login only checks presence: older passwords may predate the policy.
  static String? requiredPassword(String? value) =>
      (value ?? '').isEmpty ? 'Saisissez votre mot de passe.' : null;

  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.length < passwordMinLength) {
      return 'Au moins $passwordMinLength caractères.';
    }
    if (password.length > passwordMaxLength) {
      return 'Au plus $passwordMaxLength caractères.';
    }
    if (!_letter.hasMatch(password) || !_digit.hasMatch(password)) {
      return 'Au moins une lettre et un chiffre.';
    }
    return null;
  }

  static String? Function(String?) confirmation(String Function() password) =>
      (value) => value == password()
      ? null
      : 'Les mots de passe ne correspondent pas.';

  static String? resetCode(String? value) => _code.hasMatch(value?.trim() ?? '')
      ? null
      : 'Le code contient 6 chiffres.';
}
