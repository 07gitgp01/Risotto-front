import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../auth/presentation/widgets/auth_form_scaffold.dart';
import '../application/my_profile_controller.dart';
import '../application/profile_validators.dart';
import '../data/profile_models.dart';
import 'widgets/change_profile_photo.dart';
import 'widgets/profile_avatar.dart';

/// Design: modifier_mon_profil. Sectors and account deactivation from the mockup
/// are not offered: the API has neither.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<_EditProfileFormState>();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        actions: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _form.currentState?.submit(),
                child: const Text('Enregistrer'),
              ),
            ),
        ],
      ),
      body: profile == null
          ? const PageLoading()
          : _EditProfileForm(key: _form, profile: profile),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile, super.key});

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

  Future<void> submit() async {
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
    required IconData icon,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    Iterable<String>? autofillHints,
    TextCapitalization capitalization = TextCapitalization.sentences,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      autofillHints: autofillHints,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon) : null,
        alignLabelWithHint: maxLines > 1,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Kept up to date when the photo changes on this screen.
    final profile = ref.watch(myProfileProvider).value ?? widget.profile;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _PhotoHeader(profile: profile),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.badge_outlined,
            title: 'Informations professionnelles',
            children: [
              _field(
                _firstName,
                'Prénom',
                icon: Icons.person_outline,
                validator: ProfileValidators.name,
                capitalization: TextCapitalization.words,
              ),
              _field(
                _lastName,
                'Nom',
                icon: Icons.person_outline,
                validator: ProfileValidators.name,
                capitalization: TextCapitalization.words,
              ),
              _field(
                _headline,
                'Titre',
                icon: Icons.short_text,
                validator: ProfileValidators.maxLength(120),
              ),
              _field(
                _jobTitle,
                'Poste',
                icon: Icons.work_outline,
                validator: ProfileValidators.maxLength(100),
              ),
              _field(
                _company,
                'Entreprise',
                icon: Icons.apartment_outlined,
                validator: ProfileValidators.maxLength(100),
              ),
              _field(
                _location,
                'Ville',
                icon: Icons.place_outlined,
                validator: ProfileValidators.maxLength(100),
              ),
              _field(
                _bio,
                'À propos',
                icon: Icons.notes,
                validator: ProfileValidators.maxLength(1000),
                maxLines: 5,
                maxLength: 1000,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.hub_outlined,
            title: 'Coordonnées',
            children: [
              _field(
                _phone,
                'Téléphone',
                icon: Icons.phone_outlined,
                validator: ProfileValidators.phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              _field(
                _website,
                'Site web',
                icon: Icons.language,
                validator: ProfileValidators.website,
                keyboardType: TextInputType.url,
                autofillHints: const [AutofillHints.url],
                capitalization: TextCapitalization.none,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.visibility_outlined,
            title: 'Visibilité du profil',
            children: [
              RadioGroup<ProfileVisibility>(
                groupValue: _visibility,
                onChanged: (value) => setState(() => _visibility = value!),
                child: Column(
                  children: [
                    for (final visibility in ProfileVisibility.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _VisibilityOption(
                          visibility: visibility,
                          selected: visibility == _visibility,
                        ),
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
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            FormErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          SubmitButton(
            label: 'Enregistrer les modifications',
            icon: Icons.check_circle_outline,
            loading: _loading,
            onPressed: submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Annuler',
              style: theme.textTheme.labelLarge?.copyWith(
                color: RisottoColors.basil,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoHeader extends ConsumerWidget {
  const _PhotoHeader({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    void change() => changeProfilePhoto(context, ref, profile);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ProfileAvatar(
              initials: profile.initials,
              photoUrl: profile.photoUrl,
              name: profile.fullName,
              radius: 52,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: IconButton.filled(
                tooltip: 'Changer la photo',
                style: IconButton.styleFrom(
                  backgroundColor: RisottoColors.basil,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 3),
                ),
                onPressed: change,
                icon: const Icon(Icons.photo_camera_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: change,
          child: Text(
            'Changer la photo',
            style: theme.textTheme.labelLarge?.copyWith(
              color: RisottoColors.basil,
            ),
          ),
        ),
        Text(
          'JPEG, PNG ou WebP, 5 Mo maximum',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Icon(icon, color: RisottoColors.basil),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Radio card: the selected option is tinted basil, like the mockup.
class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({required this.visibility, required this.selected});

  final ProfileVisibility visibility;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? RisottoColors.basilSoft : RisottoColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? RisottoColors.basil : RisottoColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<ProfileVisibility>(
        value: visibility,
        title: Text(visibility.label),
        subtitle: Text(visibility.description),
      ),
    );
  }
}
