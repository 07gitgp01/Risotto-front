import 'package:flutter/material.dart';

import '../../../../core/theme/risotto_colors.dart';
import '../../../profile/data/profile_models.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../data/notifications_models.dart';

/// Small icon telling what happened (request, new connection, message).
IconData notificationIcon(NotificationKind kind) => switch (kind) {
  NotificationKind.connectionRequest => Icons.person_add_alt_1,
  NotificationKind.connectionAccepted => Icons.handshake_outlined,
  NotificationKind.message => Icons.chat_bubble_outline,
  NotificationKind.unknown => Icons.notifications_outlined,
};

/// The actor's avatar with the kind of event as a corner badge.
class ActorAvatar extends StatelessWidget {
  const ActorAvatar({
    required this.actor,
    required this.kind,
    this.radius = 24,
    super.key,
  });

  final Profile actor;
  final NotificationKind kind;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfileAvatar(
          initials: actor.initials,
          photoUrl: actor.photoUrl,
          name: actor.fullName,
          radius: radius,
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: ExcludeSemantics(
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.white,
              child: Icon(
                notificationIcon(kind),
                size: 13,
                color: RisottoColors.basil,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
