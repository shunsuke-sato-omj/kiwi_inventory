import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:kiwi_inventory/features/auth/presentation/login_screen.dart';

/// ログイン画面のgoldenテスト（constitution Principle II: widgetテスト）。
/// `LoginScreen.build()` はSupabaseへ問い合わせないため、`Supabase.initialize()`
/// なしでも安全にレンダリングできる。
///
/// 基準画像（test/goldens/login_screen.png）はCI環境で生成・更新したものを正とする
/// （開発者ごとのOS/フォント差によるフレークを避けるため）。
void main() {
  testGoldens('ログイン画面が期待どおりに表示される', (tester) async {
    await tester.pumpWidgetBuilder(
      const ProviderScope(child: LoginScreen()),
      surfaceSize: const Size(390, 844), // スマートフォン相当のサイズ
    );

    await screenMatchesGolden(tester, 'login_screen');
  });
}
