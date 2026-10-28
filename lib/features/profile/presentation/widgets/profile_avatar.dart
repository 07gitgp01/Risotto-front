import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/my_profile_controller.dart';

/// Round profile photo, falling back to the initials on a basil background.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    required this.initials,
    required this.photoUrl,
    required this.name,
    this.radius = 32,
    super.key,
  });

  final String initials;
  final String? photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final photo = photoUrl == null
        ? null
        : ref.watch(profilePhotoProvider(photoUrl!)).value;

    return Semantics(
      label: 'Photo de $name',
      image: true,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: radius,
          backgroundColor: colors.secondary,
          foregroundColor: colors.onSecondary,
          backgroundImage: photo == null ? null : MemoryImage(photo),
          child: photo == null
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
