import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/data/auth_repository.dart';
import '../access/role_access.dart';
import '../widgets/responsive_scaffold.dart';

/// ダッシュボード／収穫／在庫／出荷／マスタ管理を束ねる共通シェル。
/// go_router の StatefulShellRoute から利用する。
///
/// FR-003: マスタ管理は管理者のみが行える。現場スタッフでログインしている
/// 場合は「マスタ管理」ナビ項目自体を非表示にする（ルーティング側のガードは
/// app_router.dart の redirect で別途行う）。
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // 各要素の位置が go_router の StatefulShellRoute branches の並びと対応する。
  static const List<NavItem> _allItems = [
    NavItem(label: 'ホーム', icon: Icons.home_outlined, path: '/'),
    NavItem(label: '収穫記録', icon: Icons.eco_outlined, path: '/harvest'),
    NavItem(
      label: '在庫状況',
      icon: Icons.inventory_2_outlined,
      path: '/inventory',
    ),
    NavItem(
      label: '出荷記録',
      icon: Icons.local_shipping_outlined,
      path: '/shipping',
    ),
    NavItem(
      label: 'マスタ管理',
      icon: Icons.settings_outlined,
      path: '/master-data',
    ),
  ];

  static const List<String> _titles = [
    'ホーム',
    '収穫を記録する',
    '在庫・追熟状況',
    '出荷を記録する',
    'マスタ管理',
  ];

  static const int _masterDataBranchIndex = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 役割取得中・取得失敗時は安全側（非表示）にしておく。
    final UserRole role =
        ref.watch(currentUserRoleProvider).valueOrNull ?? UserRole.fieldStaff;
    final bool showMasterData = canManageMasterData(role);

    // 表示するナビ項目と、その元のbranchインデックスの対応表。
    final List<int> visibleBranchIndexes = [
      for (int i = 0; i < _allItems.length; i++)
        if (i != _masterDataBranchIndex || showMasterData) i,
    ];
    final List<NavItem> visibleItems = [
      for (final i in visibleBranchIndexes) _allItems[i],
    ];

    final int currentDisplayIndex = visibleBranchIndexes.indexOf(
      navigationShell.currentIndex,
    );

    return ResponsiveScaffold(
      title: _titles[navigationShell.currentIndex],
      items: visibleItems,
      currentIndex: currentDisplayIndex < 0 ? 0 : currentDisplayIndex,
      onDestinationSelected: (displayIndex) {
        final int branchIndex = visibleBranchIndexes[displayIndex];
        navigationShell.goBranch(
          branchIndex,
          initialLocation: branchIndex == navigationShell.currentIndex,
        );
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'ログアウト',
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
      body: navigationShell,
    );
  }
}
