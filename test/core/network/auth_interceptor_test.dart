import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/auth_interceptor.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_session_storage.dart';

/// Fake API: `/protected` accepts only [validAccess]; `/auth/refresh` rotates once.
class FakeApi {
  FakeApi({this.refreshStatus = 200});

  final int refreshStatus;
  String validAccess = 'access-2';
  int refreshCalls = 0;
  final refreshBodies = <Object?>[];

  Future<FakeResponse> handle(RequestOptions request) async {
    if (request.path == '/auth/refresh') {
      refreshCalls++;
      refreshBodies.add(request.data);
      // Lets concurrent requests pile up behind the first refresh.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (refreshStatus != 200) {
        return FakeResponse(refreshStatus, {'statusCode': refreshStatus});
      }
      return const FakeResponse(200, {
        'accessToken': 'access-2',
        'refreshToken': 'refresh-2',
        'tokenType': 'Bearer',
        'expiresIn': 900,
      });
    }
    final authorized =
        request.headers['Authorization'] == 'Bearer $validAccess';
    return authorized
        ? const FakeResponse(200, {'ok': true})
        : const FakeResponse(401, {'statusCode': 401});
  }
}

void main() {
  late InMemorySessionStorage storage;
  late FakeApi api;
  late FakeHttpAdapter adapter;
  late Dio dio;
  late int expiredCalls;

  void setUpClient({int refreshStatus = 200}) {
    storage = InMemorySessionStorage(testSession());
    api = FakeApi(refreshStatus: refreshStatus);
    adapter = FakeHttpAdapter(handler: api.handle);
    expiredCalls = 0;
    dio = Dio(BaseOptions(baseUrl: 'http://api.test/api'))
      ..httpClientAdapter = adapter;
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://api.test/api'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        dio: dio,
        refreshDio: refreshDio,
        onSessionExpired: () => expiredCalls++,
      ),
    );
  }

  test('adds the bearer token of the stored session', () async {
    setUpClient();
    api.validAccess = 'access-1';
    await dio.get<dynamic>('/protected');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('does not send a token on public requests', () async {
    setUpClient();
    api.validAccess = 'none';
    await expectLater(
      dio.get<dynamic>(
        '/protected',
        options: Options(extra: {skipAuthKey: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.single.headers['Authorization'], isNull);
    expect(api.refreshCalls, 0);
  });

  test(
    'refreshes on 401, stores the new tokens and replays the request',
    () async {
      setUpClient();
      final response = await dio.get<dynamic>('/protected');

      expect(response.statusCode, 200);
      expect(adapter.paths, ['/protected', '/auth/refresh', '/protected']);
      expect(api.refreshBodies.single, {'refreshToken': 'refresh-1'});
      expect(storage.session!.tokens.accessToken, 'access-2');
      expect(storage.session!.tokens.refreshToken, 'refresh-2');
      expect(storage.session!.user, testUser);
    },
  );

  test('concurrent 401s share a single refresh', () async {
    setUpClient();
    final responses = await Future.wait(
      List.generate(3, (_) => dio.get<dynamic>('/protected')),
    );

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(api.refreshCalls, 1);
  });

  test('a rejected refresh clears the session and reports expiry', () async {
    setUpClient(refreshStatus: 401);
    await expectLater(
      dio.get<dynamic>('/protected'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(storage.session, isNull);
    expect(expiredCalls, 1);
  });

  test('a refresh failing for another reason keeps the session', () async {
    setUpClient(refreshStatus: 503);
    await expectLater(
      dio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );
    expect(storage.session, isNotNull);
    expect(expiredCalls, 0);
  });

  test(
    'does not loop when the replayed request is still unauthorized',
    () async {
      setUpClient();
      api.validAccess = 'never-valid';
      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.paths, ['/protected', '/auth/refresh', '/protected']);
    },
  );

  test('without a session, a 401 is passed through untouched', () async {
    setUpClient();
    storage.session = null;
    await expectLater(
      dio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );
    expect(api.refreshCalls, 0);
  });
}
