import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      featureId: 'F9',
      title: '在庫・出荷ダッシュボード',
      description:
          '「売りたい時にすぐ在庫の有無・販売可否がわかる」ことを目的とした一覧画面。'
          'spec-kit の仕様に沿って実装します。',
    );
  }
}
