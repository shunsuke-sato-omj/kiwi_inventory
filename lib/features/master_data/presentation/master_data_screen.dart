import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// 品種・圃場・仕入先・保管場所などのマスタ管理画面（主に管理者が利用）。
class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      featureId: 'F1',
      title: 'マスタ管理',
      description: '品種・圃場（区画）・仕入先農家・保管場所を登録・編集する画面。',
    );
  }
}
