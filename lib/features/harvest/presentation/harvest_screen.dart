import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      featureId: 'F2',
      title: '収穫（選果）記録',
      description:
          '圃場・品種・重量・個数・サイズ・コンテナ数を記録する画面。'
          '現場用モック（Claude Design）のフローを踏襲します。',
    );
  }
}
