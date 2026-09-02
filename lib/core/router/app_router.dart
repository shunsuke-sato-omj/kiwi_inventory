import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/harvest/presentation/harvest_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/master_data/presentation/master_data_screen.dart';
import '../../features/shipping/presentation/shipping_screen.dart';
import 'go_router_refresh_stream.dart';
import 'home_shell.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final bool loggedIn = authRepository.currentUser != null;
      final bool onLoginPage = state.matchedLocation == '/login';

      if (!loggedIn && !onLoginPage) return '/login';
      if (loggedIn && onLoginPage) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/harvest',
                builder: (context, state) => const HarvestScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shipping',
                builder: (context, state) => const ShippingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/master-data',
                builder: (context, state) => const MasterDataScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
