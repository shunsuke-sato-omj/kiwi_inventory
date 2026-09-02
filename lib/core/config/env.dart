/// アプリの環境設定値。
///
/// 値は `--dart-define` 経由で注入します（.env ファイルはWebビルドに含めない方針）。
/// 例:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxxxxxxx
///
/// ローカル開発を楽にしたい場合は、`tool/run_dev.sh` のようなスクリプトを
/// 各自のローカル環境で用意し、そこに値を書いてください（Gitには含めない）。
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// --dart-defineで必要な値が渡されているか。
  ///
  /// `assert()`はrelease/profileビルドで丸ごと消えるため、設定漏れの検知には
  /// 使わず、main.dartでこのgetterを実行時にチェックしてエラー画面を出す。
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
