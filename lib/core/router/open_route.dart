import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Opens [location] the right way: tabs are selected, other pages are pushed.
void openRoute(GoRouter router, String location) {
  if (AppRoutes.isTab(location)) {
    router.go(location);
  } else {
    router.push<void>(location).ignore();
  }
}
