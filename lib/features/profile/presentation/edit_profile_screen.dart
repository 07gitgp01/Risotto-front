import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/widgets/auth_form_scaffold.dart';
import '../application/my_profile_controller.dart';
import '../application/profile_validators.dart';
import '../data/profile_models.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : _EditProfileForm(profile: profile),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.profile.firstName);
  late final _lastName = TextEditingController(text: widget.profile.lastName);
  late final _headline = TextEditingController(text: widget.profile.headline);
  late final _jobTitle = TextEditingController(text: widget.profile.jobTitle);
  late final _company = TextEditingController(text: widget.profile.company);
  late final _bio = TextEditingController(text: widget.profile.bio);
  late final _location = TextEditingController(text: widget.profile.location);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _website = TextEditingController(text: widget.profile.website);
  late ProfileVisibility _visibility =
      widget.profile.visibility ?? ProfileVisibility.connections;
  late bool _shareEmail = widget.profile.shareEmail ?? false;
  late bool _sharePhone = widget.profile.sharePhone ?? false;
  bool _loading = false;
  String? _error;

  List<TextEditingController> get _controllers => [
    _firstName,
    _lastName,
    _headline,
    _jobTitle,
    _company,
    _bio,
    _location,
    _phone,
    _website,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
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
          .save(
            ProfileInput(
              firstName: _firstName.text,
              lastName: _lastName.text,
              headline: _headline.text,
              jobTitle: _jobTitle.text,
              company: _company.text,
              bio: _bio.text,
              location: _location.text,
              phone: _phone.text,
              website: _website.text,
              visibility: _visibility,
              shareEmail: _shareEmail,
              sharePhone: _sharePhone,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil enregistré.')));
        context.pop();
      }
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

  Widget _field(
    TextEditingController controller,
    String label, {
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Iterable<String>? autofillHints,
    TextCapitalization capitalization = TextCapitalization.sentences,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofillHints: autofillHints,
      textCapitalization: capitalization,
      decoration: InputDecoration(labelText: label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _field(
            _firstName,
            'Prénom',
            validator: ProfileValidators.name,
            capitalization: TextCapitalization.words,
          ),
          _field(
            _lastName,
            'Nom',
            validator: ProfileValidators.name,
            capitalization: TextCapitalization.words,
          ),
          _field(
            _headline,
            'Titre',
            validator: ProfileValidators.maxLength(120),
          ),
          _field(
            _jobTitle,
            'Poste',
            validator: ProfileValidators.maxLength(100),
          ),
          _field(
            _company,
            'Entreprise',
            validator: ProfileValidators.maxLength(100),
          ),
          _field(
            _location,
            'Ville',
            validator: ProfileValidators.maxLength(100),
          ),
          _field(
            _bio,
            'À propos',
            validator: ProfileValidators.maxLength(1000),
            maxLines: 5,
          ),
          _field(
            _phone,
            'Téléphone',
            validator: ProfileValidators.phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          _field(
            _website,
            'Site web',
            validator: ProfileValidators.website,
            keyboardType: TextInputType.url,
            autofillHints: const [AutofillHints.url],
            capitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              'Visibilité du profil',
              style: theme.textTheme.titleMedium,
            ),
          ),
          RadioGroup<ProfileVisibility>(
            groupValue: _visibility,
            onChanged: (value) => setState(() => _visibility = value!),
            child: Column(
              children: [
                for (final visibility in ProfileVisibility.values)
                  RadioListTile<ProfileVisibility>(
                    value: visibility,
                    title: Text(visibility.label),
                    subtitle: Text(visibility.description),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          SwitchListTile(
            value: _shareEmail,
            onChanged: (value) => setState(() => _shareEmail = value),
            contentPadding: EdgeInsets.zero,
            title: const Text('Partager mon email'),
            subtitle: Text(
              'Visible par ceux qui voient votre profil complet : '
              '${widget.profile.accountEmail ?? ''}',
            ),
          ),
          SwitchListTile(
            value: _sharePhone,
            onChanged: (value) => setState(() => _sharePhone = value),
            contentPadding: EdgeInsets.zero,
            title: const Text('Partager mon téléphone'),
            subtitle: const Text(
              'Visible par ceux qui voient votre profil complet.',
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            FormErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          SubmitButton(
            label: 'Enregistrer',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
