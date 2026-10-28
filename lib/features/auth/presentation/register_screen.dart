import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../application/auth_controller.dart';
import '../application/auth_validators.dart';
import 'widgets/auth_form_scaffold.dart';
import 'widgets/password_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
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
          .read(authControllerProvider.notifier)
          .register(email: _email.text, password: _password.text);
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.kind == ApiErrorKind.conflict
              ? 'Un compte existe déjà avec cet email.'
              : error.message,
        );
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
      title: 'Créer un compte',
      subtitle: 'Quelques secondes pour rejoindre Risotto.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: AuthValidators.email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: 'Mot de passe',
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: AuthValidators.newPassword,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  '8 caractères minimum, avec au moins une lettre et un chiffre.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmation,
                label: 'Confirmer le mot de passe',
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.confirmation(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                FormErrorBanner(_error!),
                const SizedBox(height: 16),
              ],
              SubmitButton(
                label: 'Créer mon compte',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('J’ai déjà un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
