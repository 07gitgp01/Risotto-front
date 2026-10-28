import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/my_profile_controller.dart';
import 'widgets/profile_details.dart';

/// Another member's profile, as much as their visibility allows.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileByIdProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error is ApiException && error.statusCode == 404
                  ? 'Ce profil n’est pas disponible.'
                  : error is ApiException
                  ? error.message
                  : 'Impossible de charger le profil.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: [ProfileDetails(profile: profile)],
        ),
      ),
    );
  }
}
