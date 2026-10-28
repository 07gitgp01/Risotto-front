import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_health_repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  Dio dioWith(FakeHttpAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'http://api.test/api'))
        ..httpClientAdapter = adapter;

  test('is healthy when the API answers status ok', () async {
    final adapter = FakeHttpAdapter(
      body: {'status': 'ok', 'database': 'up', 'redis': 'up'},
    );
    final repository = DioApiHealthRepository(dioWith(adapter));

    expect(await repository.isHealthy(), isTrue);
    expect(
      adapter.requests.single.uri.toString(),
      'http://api.test/api/health',
    );
  });

  test('is unhealthy when the API reports a failing component', () async {
    final adapter = FakeHttpAdapter(
      statusCode: 503,
      body: {'statusCode': 503, 'message': 'down'},
    );
    expect(await DioApiHealthRepository(dioWith(adapter)).isHealthy(), isFalse);
  });

  test('is unhealthy when the API is unreachable', () async {
    final adapter = FakeHttpAdapter(error: DioExceptionType.connectionError);
    expect(await DioApiHealthRepository(dioWith(adapter)).isHealthy(), isFalse);
  });
}
