import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Last known API responses, per user, for offline use. Stored in the app's private
/// support directory (not backed up, see AndroidManifest) and wiped on sign-out.
abstract interface class ResponseCache {
  Future<Object?> read(String userId, String key);

  Future<void> write(String userId, String key, Object? data);

  /// Removes everything (sign-out).
  Future<void> clear();
}

class MemoryResponseCache implements ResponseCache {
  final Map<String, Object?> _entries = {};

  @override
  Future<Object?> read(String userId, String key) async =>
      _entries['$userId|$key'];

  @override
  Future<void> write(String userId, String key, Object? data) async =>
      _entries['$userId|$key'] = data;

  @override
  Future<void> clear() async => _entries.clear();
}

/// One JSON file per user, loaded lazily and rewritten on each update.
class FileResponseCache implements ResponseCache {
  static const _maxEntries = 100;

  final Map<String, Map<String, Object?>> _loaded = {};
  Directory? _directory;

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    return _directory ??= await Directory(
      '${base.path}/offline-cache',
    ).create(recursive: true);
  }

  Future<File> _file(String userId) async {
    // User ids are UUIDs; anything else is rejected to keep the path safe.
    if (!RegExp(r'^[0-9a-fA-F-]{8,64}$').hasMatch(userId)) {
      throw ArgumentError.value(userId, 'userId');
    }
    return File('${(await _dir()).path}/$userId.json');
  }

  Future<Map<String, Object?>> _entries(String userId) async {
    final cached = _loaded[userId];
    if (cached != null) {
      return cached;
    }
    final file = await _file(userId);
    Map<String, Object?> entries = {};
    if (await file.exists()) {
      try {
        entries = Map<String, Object?>.from(
          jsonDecode(await file.readAsString()) as Map,
        );
      } on Object {
        entries = {};
      }
    }
    return _loaded[userId] = entries;
  }

  @override
  Future<Object?> read(String userId, String key) async =>
      (await _entries(userId))[key];

  @override
  Future<void> write(String userId, String key, Object? data) async {
    final entries = await _entries(userId)
      ..remove(key)
      ..[key] = data;
    // Oldest first: keep the most recent entries only.
    while (entries.length > _maxEntries) {
      entries.remove(entries.keys.first);
    }
    await (await _file(userId)).writeAsString(jsonEncode(entries), flush: true);
  }

  @override
  Future<void> clear() async {
    _loaded.clear();
    final dir = await _dir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _directory = null;
  }
}

final responseCacheProvider = Provider<ResponseCache>(
  (ref) => FileResponseCache(),
);
