import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/harvest/presentation/harvest_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/master_data/presentation/master_data_screen.dart';
import '../../features/shipping/presentation/shipping_screen.dart';
import '../access/role_access.dart';
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

      // FR-003: マスタ管理は管理者のみ。現場スタッフが直接URLでアクセスした
      // 場合もホームへ戻す（ナビ項目の非表示はhome_shell.dart側で対応済み）。
      // 役割の取得がまだ完了していない間は「管理者ではない」扱いにする
      // （fail-closed。home_shell.dartのナビ非表示と同じ既定値に揃える）。
      if (loggedIn && state.matchedLocation == '/master-data') {
        final UserRole? role = ref.read(currentUserRoleProvider).valueOrNull;
        final bool isAdmin = role != null && canManageMasterData(role);
        if (!isAdmin) return '/';
      }
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
