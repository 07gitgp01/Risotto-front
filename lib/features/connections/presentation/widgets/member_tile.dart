import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../profile/data/profile_models.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';

/// A member in a list: avatar, name, headline; opens the profile on tap.
class MemberTile extends StatelessWidget {
  const MemberTile({
    required this.profile,
    this.subtitle,
    this.trailing,
    this.below,
    super.key,
  });

  final Profile profile;
  final String? subtitle;
  final Widget? trailing;

  /// Extra content under the tile (e.g. request message and buttons).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: ProfileAvatar(
        initials: profile.initials,
        photoUrl: profile.photoUrl,
        name: profile.fullName,
        radius: 22,
      ),
      title: Text(profile.fullName),
      subtitle: Text(
        subtitle ?? profile.headline ?? profile.position ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: () => context.push(AppRoutes.userProfile(profile.userId)),
    );
    if (below == null) {
      return tile;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
          child: below,
        ),
      ],
    );
  }
}
