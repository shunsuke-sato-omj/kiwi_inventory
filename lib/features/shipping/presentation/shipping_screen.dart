import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class ShippingScreen extends StatelessWidget {
  const ShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      featureId: 'F6',
      title: '出荷記録',
      description: '出荷先・対象ロット・数量・配送方法を記録する画面。',
    );
  }
}
