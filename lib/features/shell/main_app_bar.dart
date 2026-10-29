import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/risotto_colors.dart';
import '../../core/widgets/risotto_ui.dart';
import '../notifications/application/notifications_providers.dart';
import '../profile/application/my_profile_controller.dart';
import '../profile/presentation/widgets/profile_avatar.dart';

/// App bar of the main tabs: logo, title, notifications bell, my avatar.
class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const MainAppBar({required this.title, this.actions = const [], super.key});

  final String title;

  /// Extra actions, shown before the bell.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final profile = ref.watch(myProfileProvider).value;
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        children: [
          const RisottoLogo(size: 32),
          const SizedBox(width: 12),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        ...actions,
        IconButton(
          tooltip: unread > 0
              ? 'Notifications, $unread non lues'
              : 'Notifications',
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            backgroundColor: RisottoColors.tomatoDeep,
            textColor: RisottoColors.white,
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        if (profile != null)
          IconButton(
            tooltip: 'Mon profil',
            onPressed: () => context.go(AppRoutes.myProfile),
            icon: ProfileAvatar(
              initials: profile.initials,
              photoUrl: profile.photoUrl,
              name: profile.fullName,
              radius: 18,
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
