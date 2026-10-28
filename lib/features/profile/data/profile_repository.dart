import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'profile_models.dart';

/// Profile endpoints. Every method throws [ApiException] on failure.
abstract interface class ProfileRepository {
  /// Null when the profile has not been created yet.
  Future<Profile?> getMine();

  Future<Profile> create(ProfileInput input);

  Future<Profile> update(ProfileInput input);

  Future<Profile> uploadPhoto(Uint8List bytes, String filename);

  Future<void> deletePhoto();

  Future<Profile> getById(String userId);

  /// Downloads an authenticated image (photo URLs are relative to the API).
  Future<Uint8List> downloadPhoto(String photoUrl);
}

class DioProfileRepository implements ProfileRepository {
  DioProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<Profile?> getMine() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/profiles/me');
      return Profile.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Profile> create(ProfileInput input) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/profiles/me',
      data: input.toJson(),
    );
    return Profile.fromJson(response.data!);
  });

  @override
  Future<Profile> update(ProfileInput input) => guardApi(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/profiles/me',
      data: input.toJson(),
    );
    return Profile.fromJson(response.data!);
  });

  @override
  Future<Profile> uploadPhoto(Uint8List bytes, String filename) =>
      guardApi(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/profiles/me/photo',
          data: FormData.fromMap({
            'photo': MultipartFile.fromBytes(bytes, filename: filename),
          }),
        );
        return Profile.fromJson(response.data!);
      });

  @override
  Future<void> deletePhoto() =>
      guardApi(() => _dio.delete<void>('/profiles/me/photo'));

  @override
  Future<Profile> getById(String userId) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/profiles/$userId');
    return Profile.fromJson(response.data!);
  });

  @override
  Future<Uint8List> downloadPhoto(String photoUrl) => guardApi(() async {
    final response = await _dio.get<List<int>>(
      photoUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  });
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => DioProfileRepository(ref.watch(dioProvider)),
);
