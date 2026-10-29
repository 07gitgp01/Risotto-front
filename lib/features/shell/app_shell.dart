import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/risotto_colors.dart';
import '../dashboard/application/dashboard_provider.dart';
import '../messaging/application/messaging_providers.dart';

/// Main tabs with the bottom navigation of the design system:
/// Accueil · Réseau · [Ma carte] · Messages · Profil.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  /// Tab index (shell branch) of each visible destination; the middle slot is the
  /// QR card button, which opens a full-screen page instead of a tab.
  static const _branchOfSlot = [0, 1, null, 2, 3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequests =
        ref.watch(dashboardProvider).value?.pendingRequestsCount ?? 0;
    final unreadMessages = ref.watch(unreadMessagesCountProvider);
    final selectedSlot = _branchOfSlot.indexOf(shell.currentIndex);

    Widget badge(int count, Widget icon) => Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: RisottoColors.tomatoDeep,
      textColor: RisottoColors.white,
      child: icon,
    );

    return Scaffold(
      body: shell,
      floatingActionButton: _CardButton(
        onPressed: () => context.push(AppRoutes.myCard),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: RisottoColors.outline)),
        ),
        child: NavigationBar(
          selectedIndex: selectedSlot,
          onDestinationSelected: (slot) {
            final branch = _branchOfSlot[slot];
            if (branch == null) {
              context.push(AppRoutes.myCard);
              return;
            }
            // Tapping the current tab again goes back to its first page.
            shell.goBranch(
              branch,
              initialLocation: branch == shell.currentIndex,
            );
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: badge(pendingRequests, const Icon(Icons.group_outlined)),
              selectedIcon: badge(pendingRequests, const Icon(Icons.group)),
              label: 'Réseau',
              tooltip: pendingRequests > 0
                  ? 'Réseau, $pendingRequests demandes en attente'
                  : 'Réseau',
            ),
            // Room for the docked card button.
            const NavigationDestination(
              icon: SizedBox.shrink(),
              label: '',
              enabled: false,
            ),
            NavigationDestination(
              icon: badge(
                unreadMessages,
                const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: badge(
                unreadMessages,
                const Icon(Icons.chat_bubble),
              ),
              label: 'Messages',
              tooltip: unreadMessages > 0
                  ? 'Messages, $unreadMessages non lus'
                  : 'Messages',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Saffron round button in the middle of the bar: opens "Ma carte" (QR code).
class _CardButton extends StatelessWidget {
  const _CardButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox.square(
        dimension: 64,
        child: FloatingActionButton(
          heroTag: 'my-card',
          tooltip: 'Ma carte',
          onPressed: onPressed,
          backgroundColor: RisottoColors.saffron,
          foregroundColor: RisottoColors.charcoal,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_2, size: 32),
        ),
      ),
    );
  }
}
