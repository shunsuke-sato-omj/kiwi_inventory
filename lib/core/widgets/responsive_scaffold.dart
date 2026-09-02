import 'package:flutter/material.dart';

/// ナビゲーション項目の定義。
class NavItem {
  const NavItem({required this.label, required this.icon, required this.path});

  final String label;
  final IconData icon;
  final String path;
}

/// 画面幅に応じて、モバイル幅では下部ナビゲーション、
/// PC幅ではサイドの NavigationRail に切り替わる共通レイアウト。
///
/// 要件定義書 8章（利用環境）: 現場は私物スマートフォン、事務所・管理者はPC。
/// 同一のFlutter Webアプリで両方をカバーするための土台。
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget>? actions;

  static const double _desktopBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isDesktop = width >= _desktopBreakpoint;

    final Widget content = isDesktop
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final item in items)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          )
        : body;

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: content,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
    );
  }
}
