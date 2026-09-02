import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/core/data/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapSupabaseErrorToMessage', () {
    test('P0001（アプリのRPCが明示的にraiseした内容）はそのまま見せる', () {
      final error = PostgrestException(
        message: '出荷数量が残り在庫（3）を超えています。数量を見直してください。',
        code: 'P0001',
      );
      expect(mapSupabaseErrorToMessage(error), error.message);
    });

    test('23505（一意制約違反）は分かりやすい重複メッセージになる', () {
      final error = PostgrestException(message: 'duplicate key', code: '23505');
      expect(mapSupabaseErrorToMessage(error), contains('登録されています'));
    });

    test('42501（権限不足）は権限メッセージになる', () {
      final error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );
      expect(mapSupabaseErrorToMessage(error), contains('権限'));
    });

    test('不明なPostgrestExceptionは汎用メッセージになる', () {
      final error = PostgrestException(message: 'something else');
      expect(mapSupabaseErrorToMessage(error), contains('保存に失敗しました'));
    });

    test('AuthExceptionはログイン確認を促すメッセージになる', () {
      final error = AuthException('invalid token');
      expect(mapSupabaseErrorToMessage(error), contains('ログイン'));
    });
  });
}
