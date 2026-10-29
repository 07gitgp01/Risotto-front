abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/';
  static const profileSetup = '/onboarding/profile';
  static const myProfile = '/profile';
  static const editProfile = '/profile/edit';
  static const userProfilePattern = '/users/:userId';
  static const myCard = '/card';
  static const scan = '/scan';
  static const contacts = '/contacts';
  static const network = '/network';
  static const search = '/search';
  static const blockedUsers = '/network/blocked';
  static const messages = '/messages';
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const admin = '/admin';

  /// Reachable without a session.
  static const publicRoutes = {
    welcome,
    login,
    register,
    forgotPassword,
    resetPassword,
  };

  static String resetPasswordFor(String email) =>
      Uri(path: resetPassword, queryParameters: {'email': email}).toString();

  static String userProfile(String userId) => '/users/$userId';

  static String contactDetail(String contactId) => '/contacts/$contactId';

  static String chat(String conversationId) => '/messages/$conversationId';

  /// Main tabs (bottom navigation): reached with `go`, never pushed on top of the
  /// tabs (a tab page cannot appear twice in the stack).
  static bool isTab(String location) {
    final path = Uri.parse(location).path;
    return path == home ||
        path == network ||
        path == messages ||
        path == myProfile;
  }
}
