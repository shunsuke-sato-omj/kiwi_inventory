import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      featureId: 'F4 / F5',
      title: '在庫・追熟状況',
      description:
          'ロットごとの冷蔵保管／追熟中／追熟済み／期限切れを管理する画面。'
          'ステータスは手動で訂正できる形にします。',
    );
  }
}
