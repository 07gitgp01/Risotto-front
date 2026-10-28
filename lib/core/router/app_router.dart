import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/connections/presentation/blocked_users_screen.dart';
import '../../features/connections/presentation/network_screen.dart';
import '../../features/connections/presentation/search_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/contacts/presentation/contact_detail_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/contacts/presentation/my_card_screen.dart';
import '../../features/contacts/presentation/scan_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/profile/application/my_profile_controller.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/profile/presentation/user_profile_screen.dart';
import 'app_routes.dart';

/// Whether the signed-in user already has a profile. `unknown` while loading or
/// offline: the user is then never forced onto the setup screen.
enum ProfileStatus { unknown, missing, present }

ProfileStatus profileStatusOf(AsyncValue<Object?> profile) => switch (profile) {
  AsyncData(value: null) => ProfileStatus.missing,
  AsyncData() => ProfileStatus.present,
  _ => ProfileStatus.unknown,
};

/// Where to send the user for [location], or null to stay.
String? appRedirect(AuthState auth, ProfileStatus profile, String location) {
  final isPublic = AppRoutes.publicRoutes.contains(location);
  switch (auth) {
    case AuthUnknown():
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case Unauthenticated():
      return isPublic ? null : AppRoutes.login;
    case Authenticated():
      if (profile == ProfileStatus.missing) {
        return location == AppRoutes.profileSetup
            ? null
            : AppRoutes.profileSetup;
      }
      if (isPublic ||
          location == AppRoutes.splash ||
          (location == AppRoutes.profileSetup &&
              profile == ProfileStatus.present)) {
        return AppRoutes.home;
      }
      return null;
  }
}

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect whenever the auth state or the profile status changes.
  final refresh = _RouterRefresh();
  ref.listen(authControllerProvider, (_, _) => refresh.notify());
  ref.listen(
    myProfileProvider.select(profileStatusOf),
    (_, _) => refresh.notify(),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      ref.read(authControllerProvider),
      profileStatusOf(ref.read(myProfileProvider)),
      state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) =>
            ResetPasswordScreen(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.myProfile,
        builder: (context, state) => const MyProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.myCard,
        builder: (context, state) => const MyCardScreen(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.contacts,
        builder: (context, state) => const ContactsScreen(),
        routes: [
          GoRoute(
            path: ':contactId',
            builder: (context, state) => ContactDetailScreen(
              contactId: state.pathParameters['contactId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.network,
        builder: (context, state) => NetworkScreen(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'blocked',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const ConversationsScreen(),
        routes: [
          GoRoute(
            path: ':conversationId',
            builder: (context, state) => ChatScreen(
              conversationId: state.pathParameters['conversationId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.userProfilePattern,
        builder: (context, state) =>
            UserProfileScreen(userId: state.pathParameters['userId']!),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
