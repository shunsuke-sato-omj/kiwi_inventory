import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/responsive_scaffold.dart';

/// ダッシュボード／収穫／在庫／出荷／マスタ管理を束ねる共通シェル。
/// go_router の StatefulShellRoute から利用する。
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<NavItem> _items = [
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: _titles[navigationShell.currentIndex],
      items: _items,
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      body: navigationShell,
    );
  }
}
