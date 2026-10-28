import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/offline/offline_interceptor.dart';
import 'package:risotto/core/offline/response_cache.dart';
import 'package:risotto/features/auth/data/auth_models.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_session_storage.dart';

void main() {
  late MemoryResponseCache cache;
  late InMemorySessionStorage storage;
  late bool online;
  late Dio dio;
  late FakeHttpAdapter adapter;
  var reachable = true;

  setUp(() {
    cache = MemoryResponseCache();
    storage = InMemorySessionStorage(testSession());
    online = true;
    reachable = true;
    adapter = FakeHttpAdapter(
      handler: (request) async {
        if (!reachable) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        }
        return FakeResponse(200, {'path': request.path, 'fresh': true});
      },
    );
    dio = Dio(BaseOptions(baseUrl: 'http://api.test/api'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        OfflineInterceptor(
          cache: cache,
          storage: storage,
          onOffline: () => online = false,
          onOnline: () => online = true,
        ),
      );
  });

  test('serves the last response of a cacheable screen when offline', () async {
    await dio.get<dynamic>('/dashboard');
    reachable = false;

    final response = await dio.get<dynamic>('/dashboard');

    expect(response.data, {'path': '/dashboard', 'fresh': true});
    expect(response.headers.value(offlineCacheHeader), '1');
    expect(online, isFalse);
  });

  test('comes back online with the next successful response', () async {
    reachable = false;
    await expectLater(
      dio.get<dynamic>('/dashboard'),
      throwsA(isA<DioException>()),
    );
    expect(online, isFalse);

    reachable = true;
    await dio.get<dynamic>('/dashboard');
    expect(online, isTrue);
  });

  test('never replays writes or uncached screens', () async {
    reachable = false;
    await expectLater(
      dio.post<dynamic>('/conversations/c1/messages', data: {'body': 'x'}),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      dio.get<dynamic>('/users/search'),
      throwsA(isA<DioException>()),
    );
  });

  test('only keeps the first page of a history', () async {
    await dio.get<dynamic>(
      '/conversations/0f7a/messages',
      queryParameters: {'before': 'm9'},
    );
    reachable = false;
    await expectLater(
      dio.get<dynamic>(
        '/conversations/0f7a/messages',
        queryParameters: {'before': 'm9'},
      ),
      throwsA(isA<DioException>()),
    );
  });

  test('keeps each account’s data apart', () async {
    await dio.get<dynamic>('/dashboard');
    storage.session = testSession(
      user: const AuthUser(id: 'user-2', email: 'bob@example.com'),
    );
    reachable = false;
    await expectLater(
      dio.get<dynamic>('/dashboard'),
      throwsA(isA<DioException>()),
    );
  });

  test('a server error is not "offline"', () async {
    final failing = Dio(BaseOptions(baseUrl: 'http://api.test/api'))
      ..httpClientAdapter = FakeHttpAdapter(statusCode: 500, body: {})
      ..interceptors.add(
        OfflineInterceptor(
          cache: cache,
          storage: storage,
          onOffline: () => online = false,
          onOnline: () => online = true,
        ),
      );
    await expectLater(
      failing.get<dynamic>('/dashboard'),
      throwsA(isA<DioException>()),
    );
    expect(online, isTrue);
  });

  test('cache keys ignore query parameter order', () {
    final a = RequestOptions(path: '/x', queryParameters: {'a': 1, 'b': 2});
    final b = RequestOptions(path: '/x', queryParameters: {'b': 2, 'a': 1});
    expect(OfflineInterceptor.keyOf(a), OfflineInterceptor.keyOf(b));
  });
}
