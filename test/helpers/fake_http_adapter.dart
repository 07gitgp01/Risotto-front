import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeResponse {
  const FakeResponse(this.statusCode, [this.body]);

  final int statusCode;
  final Object? body;
}

typedef FakeHandler = Future<FakeResponse> Function(RequestOptions request);

/// In-memory HTTP backend for Dio. Either answers every request with a fixed
/// status and JSON body, throws [error], or delegates to [handler].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({this.statusCode = 200, this.body, this.error, this.handler});

  final int statusCode;
  final Object? body;
  final DioExceptionType? error;
  final FakeHandler? handler;
  final List<RequestOptions> requests = [];

  List<String> get paths => requests.map((r) => r.path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (error != null) {
      throw DioException(requestOptions: options, type: error!);
    }
    final response = handler != null
        ? await handler!(options)
        : FakeResponse(statusCode, body);
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
