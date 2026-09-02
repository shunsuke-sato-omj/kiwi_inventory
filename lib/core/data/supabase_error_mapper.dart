import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase/ネットワーク由来の例外を、現場で分かりやすい日本語メッセージに変換する。
///
/// FR-018: オフライン（通信不可）等で保存に失敗した場合、その旨を分かりやすい
/// エラーとして表示する。オフライン時の保存・自動同期はMVP対象外のため、
/// ここでは「保存できなかったこと」と「再試行を促す」ことに徹する。
String mapSupabaseErrorToMessage(Object error) {
  if (error is SocketException || error is HttpException) {
    return '通信状態が悪く保存できませんでした。電波の良い場所で再度お試しください。';
  }
  if (error is AuthException) {
    return 'ログイン状態が確認できませんでした。再度ログインしてください。';
  }
  if (error is PostgrestException) {
    // 開発時に原因が追えるよう message は残しつつ、現場向けには簡潔な文言にする。
    return '保存に失敗しました。入力内容をご確認のうえ、もう一度お試しください。';
  }
  return '通信状態が悪く保存できませんでした。電波の良い場所で再度お試しください。';
}
