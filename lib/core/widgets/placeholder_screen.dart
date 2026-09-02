import 'package:flutter/material.dart';

/// 機能実装前の仮画面。
///
/// spec-kit で各機能（F1〜F13）の仕様を確定し次第、この中身を実装に置き換える。
/// [featureId] は要件定義書 7章の機能ID（例: 'F2'）に対応させておくと、
/// 仕様書・実装・要件定義書のトレーサビリティが取りやすくなる。
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.featureId,
    required this.title,
    required this.description,
  });

  final String featureId;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(label: Text(featureId)),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
