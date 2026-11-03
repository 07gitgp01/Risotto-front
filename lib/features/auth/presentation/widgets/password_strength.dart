import 'package:flutter/material.dart';

import '../../../../core/theme/risotto_colors.dart';
import '../../../../core/widgets/risotto_ui.dart';
import '../../application/auth_validators.dart';

enum PasswordStrength { none, weak, medium, strong }

/// Rough strength: the policy (length, letter, digit) gives "medium";
/// length 12+ or a symbol on top of it gives "strong".
PasswordStrength passwordStrength(String password) {
  if (password.isEmpty) {
    return PasswordStrength.none;
  }
  final meetsPolicy = AuthValidators.newPassword(password) == null;
  if (!meetsPolicy) {
    return PasswordStrength.weak;
  }
  final symbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  final mixedCase =
      RegExp('[a-z]').hasMatch(password) && RegExp('[A-Z]').hasMatch(password);
  final bonus = [password.length >= 12, symbol, mixedCase].where((b) => b);
  return bonus.length >= 2 ? PasswordStrength.strong : PasswordStrength.medium;
}

/// Three-segment meter under the password field (design: inscription).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = passwordStrength(password);
    final (label, tone, filled, color) = switch (strength) {
      PasswordStrength.none => ('', PillTone.neutral, 0, RisottoColors.outline),
      PasswordStrength.weak => (
        'Faible',
        PillTone.tomato,
        1,
        RisottoColors.tomato,
      ),
      PasswordStrength.medium => (
        'Moyen',
        PillTone.saffron,
        2,
        RisottoColors.saffron,
      ),
      PasswordStrength.strong => (
        'Fort',
        PillTone.basil,
        3,
        RisottoColors.basil,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RisottoColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Force du mot de passe',
                  style: theme.textTheme.labelMedium,
                ),
              ),
              if (strength != PasswordStrength.none)
                Semantics(
                  liveRegion: true,
                  label: 'Force du mot de passe : $label',
                  excludeSemantics: true,
                  child: StatusPill(label, tone: tone),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < filled ? color : RisottoColors.creamDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '8 caractères minimum, avec au moins une lettre et un chiffre. '
            'Astuce : ajoutez un symbole (&, @, !) et des majuscules.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
