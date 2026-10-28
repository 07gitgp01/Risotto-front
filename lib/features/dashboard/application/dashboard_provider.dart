import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/realtime_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../connections/application/connections_providers.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

const _refreshingEvents = {
  'message:new',
  'conversation:read',
  'notification:new',
};

/// Home summary. Reloads on realtime events (debounced) and whenever the network
/// lists change (accept, decline...). On failure the last summary stays visible.
class DashboardController extends AsyncNotifier<Dashboard?> {
  Timer? _debounce;

  @override
  Future<Dashboard?> build() async {
    if (ref.watch(authControllerProvider) is! Authenticated) {
      return null;
    }
    ref
      // A connection action elsewhere changes the pending requests.
      ..listen(networkRevisionProvider, (_, _) => unawaited(refresh()))
      ..listen(realtimeEventsProvider, (_, next) {
        if (_refreshingEvents.contains(next.value?.name)) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), refresh);
        }
      })
      ..onDispose(() => _debounce?.cancel());
    return ref.read(dashboardRepositoryProvider).load();
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).load(),
    );
    if (result.hasValue) {
      state = result;
    }
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardController, Dashboard?>(
      DashboardController.new,
    );
