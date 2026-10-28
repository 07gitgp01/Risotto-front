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

  /// Reachable without a session.
  static const publicRoutes = {login, register, forgotPassword, resetPassword};

  static String resetPasswordFor(String email) =>
      Uri(path: resetPassword, queryParameters: {'email': email}).toString();

  static String userProfile(String userId) => '/users/$userId';
}
