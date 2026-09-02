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

  /// 開発中に環境変数の設定漏れへ早めに気づけるようにするための検証。
  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'SUPABASE_URL / SUPABASE_ANON_KEY が設定されていません。'
      '--dart-define で指定してください（README参照）。',
    );
  }
}
