import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the API is currently unreachable, as seen by the last requests.
class ConnectivityController extends Notifier<bool> {
  @override
  bool build() => false;

  void markOffline() {
    if (!state) {
      state = true;
    }
  }

  void markOnline() {
    if (state) {
      state = false;
    }
  }
}

/// True while offline.
final offlineProvider = NotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);
