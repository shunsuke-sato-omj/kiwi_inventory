import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

/// golden_toolkitの共通設定。すべてのテストファイルの実行前に一度だけ呼ばれる。
///
/// フォントを読み込んでからgoldenを撮ることで、開発者ごとの環境差による
/// テキスト崩れ・フレークを減らす（constitution Principle II参照）。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}
