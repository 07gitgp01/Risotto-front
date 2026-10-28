abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/';
  static const profileSetup = '/profile/setup';
  static const myProfile = '/profile';
  static const editProfile = '/profile/edit';
  static const userProfilePattern = '/users/:userId';
  static const myCard = '/card';
  static const scan = '/scan';
  static const contacts = '/contacts';
  static const network = '/network';
  static const search = '/search';
  static const blockedUsers = '/network/blocked';

  /// Reachable without a session.
  static const publicRoutes = {login, register, forgotPassword, resetPassword};

  static String resetPasswordFor(String email) =>
      Uri(path: resetPassword, queryParameters: {'email': email}).toString();

  static String userProfile(String userId) => '/users/$userId';

  static String contactDetail(String contactId) => '/contacts/$contactId';
}
