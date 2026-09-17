/// アプリの環境設定値。
///
/// 値は `--dart-define`（コンパイル時定数）経由で注入します
/// （.env ファイルを実行時に読み込む方式はWebビルドに含めない方針）。
/// 個別に指定する場合:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxxxxxxx
///
/// ローカル開発では `config/local.json.example` を `config/local.json`
/// にコピーして値を書き込み、`--dart-define-from-file=config/local.json`
/// で一括指定できます（`config/local.json` はGitに含めません）。
/// どちらの方法でも、渡された値はコンパイル時定数として同じように
/// `String.fromEnvironment` に渡されるため、このクラスの実装は変わりません。
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
