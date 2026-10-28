/// Mirrors the API rules for profile fields. Returns a French message or null.
abstract final class ProfileValidators {
  static final _phone = RegExp(r'^\+?[0-9][0-9 .()-]{5,19}$');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    return text.length > 50 ? 'Au plus 50 caractères.' : null;
  }

  static String? Function(String?) maxLength(int max) =>
      (value) =>
          (value?.trim().length ?? 0) > max ? 'Au plus $max caractères.' : null;

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return _phone.hasMatch(text) ? null : 'Numéro de téléphone invalide.';
  }

  static String? website(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(text);
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.');
    if (!valid) {
      return 'Adresse web invalide (commencez par https://).';
    }
    return text.length > 200 ? 'Au plus 200 caractères.' : null;
  }
}
