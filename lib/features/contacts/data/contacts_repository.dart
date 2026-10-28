import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'contacts_models.dart';

/// QR code and contacts endpoints. Every method throws [ApiException] on failure.
abstract interface class ContactsRepository {
  Future<QrCode> getQrCode();

  Future<QrCode> rotateQrCode();

  Future<ContactCard> getOwnCard();

  Future<ScanResult> scan(String payload, {bool saveContact = false});

  Future<List<SavedContact>> list();

  Future<void> updateNote(String contactId, String? note);

  Future<void> remove(String contactId);
}

class DioContactsRepository implements ContactsRepository {
  DioContactsRepository(this._dio);

  final Dio _dio;

  @override
  Future<QrCode> getQrCode() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/qr/me');
    return QrCode.fromJson(response.data!);
  });

  @override
  Future<QrCode> rotateQrCode() => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>('/qr/me/rotate');
    return QrCode.fromJson(response.data!);
  });

  @override
  Future<ContactCard> getOwnCard() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/contacts/card/me');
    return ContactCard.fromJson(response.data!);
  });

  @override
  Future<ScanResult> scan(String payload, {bool saveContact = false}) =>
      guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/qr/scan',
          data: {'payload': payload, 'saveContact': saveContact},
        );
        return ScanResult.fromJson(response.data!);
      });

  @override
  Future<List<SavedContact>> list() => guardApi(() async {
    final response = await _dio.get<List<dynamic>>('/contacts');
    return response.data!
        .map((json) => SavedContact.fromJson(json as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<void> updateNote(String contactId, String? note) => guardApi(
    () => _dio.patch<void>('/contacts/$contactId', data: {'note': note ?? ''}),
  );

  @override
  Future<void> remove(String contactId) =>
      guardApi(() => _dio.delete<void>('/contacts/$contactId'));
}

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => DioContactsRepository(ref.watch(dioProvider)),
);
