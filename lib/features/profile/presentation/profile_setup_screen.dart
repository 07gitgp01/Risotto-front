import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/widgets/auth_form_scaffold.dart';
import '../application/my_profile_controller.dart';
import '../application/profile_validators.dart';
import '../data/profile_models.dart';

/// First step after sign-up: the profile needs at least a name.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _headline = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _headline.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(myProfileProvider.notifier)
          .create(
            ProfileInput(
              firstName: _firstName.text,
              lastName: _lastName.text,
              headline: _headline.text,
            ),
          );
      // The router leaves this screen once the profile exists.
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Votre profil',
      subtitle:
          'Présentez-vous en quelques mots. Vous pourrez tout compléter plus tard.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              textInputAction: TextInputAction.next,
              validator: ProfileValidators.name,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              textInputAction: TextInputAction.next,
              validator: ProfileValidators.name,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _headline,
              textInputAction: TextInputAction.done,
              validator: ProfileValidators.maxLength(120),
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Titre (facultatif)',
                hintText: 'Ex. : Développeuse mobile chez Risotto',
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            SubmitButton(
              label: 'Créer mon profil',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
