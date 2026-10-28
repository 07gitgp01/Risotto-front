import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every request with a fixed status and JSON body, or throws [error].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({this.statusCode = 200, this.body, this.error});

  final int statusCode;
  final Object? body;
  final DioExceptionType? error;
  final List<RequestOptions> requests = [];

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
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
