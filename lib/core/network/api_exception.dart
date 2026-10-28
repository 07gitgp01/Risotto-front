import 'package:dio/dio.dart';

enum ApiErrorKind {
  network,
  unauthorized,
  conflict,
  invalidInput,
  rateLimited,
  server,
}

/// API failure translated into something the UI can show.
class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status == null) {
      return const ApiException(ApiErrorKind.network);
    }
    final kind = switch (status) {
      401 || 403 => ApiErrorKind.unauthorized,
      409 => ApiErrorKind.conflict,
      400 || 404 || 422 => ApiErrorKind.invalidInput,
      429 => ApiErrorKind.rateLimited,
      _ => ApiErrorKind.server,
    };
    return ApiException(kind, statusCode: status);
  }

  final ApiErrorKind kind;
  final int? statusCode;

  /// Generic French message; screens override it when they know better.
  String get message => switch (kind) {
    ApiErrorKind.network =>
      'Impossible de joindre le serveur. Vérifiez votre connexion.',
    ApiErrorKind.unauthorized => 'Votre session a expiré. Reconnectez-vous.',
    ApiErrorKind.conflict => 'Cette ressource existe déjà.',
    ApiErrorKind.invalidInput => 'Certaines informations sont invalides.',
    ApiErrorKind.rateLimited =>
      'Trop de tentatives. Réessayez dans une minute.',
    ApiErrorKind.server => 'Une erreur est survenue. Réessayez plus tard.',
  };

  @override
  String toString() => 'ApiException($kind, $statusCode)';
}

/// Runs an API call and converts Dio failures into [ApiException].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw ApiException.fromDio(error);
  }
}
