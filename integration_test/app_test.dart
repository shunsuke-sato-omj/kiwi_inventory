// ローカルSupabaseスタック（`supabase start`）＋シードデータに対して実行する
// integrationテスト（constitution Principle II: 3層目）。
//
// 実行方法（要 Docker + Supabase CLI）:
//   supabase start
//   # 事前に以下のテストユーザーを作成しておくこと（README/quickstart.md参照）:
//   #   - 現場スタッフ: INTEGRATION_TEST_FIELD_STAFF_EMAIL / _PASSWORD
//   #   - 管理者:       INTEGRATION_TEST_ADMIN_EMAIL / _PASSWORD
//   flutter test integration_test \
//     --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
//     --dart-define=SUPABASE_ANON_KEY=<supabase start が出力するanon key> \
//     --dart-define=INTEGRATION_TEST_FIELD_STAFF_EMAIL=field@example.com \
//     --dart-define=INTEGRATION_TEST_FIELD_STAFF_PASSWORD=password123 \
//     --dart-define=INTEGRATION_TEST_ADMIN_EMAIL=admin@example.com \
//     --dart-define=INTEGRATION_TEST_ADMIN_PASSWORD=password123
//
// 上記の --dart-define が未設定の場合、テストは（ローカルSupabaseが無い環境で
// 誤って実行されても失敗しないよう）スキップする。CI（.github/workflows/ci.yml）
// では `supabase start` 後にこれらの値を設定して実行する。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiwi_inventory/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const String _fieldStaffEmail = String.fromEnvironment(
  'INTEGRATION_TEST_FIELD_STAFF_EMAIL',
);
const String _fieldStaffPassword = String.fromEnvironment(
  'INTEGRATION_TEST_FIELD_STAFF_PASSWORD',
);
const String _adminEmail = String.fromEnvironment(
  'INTEGRATION_TEST_ADMIN_EMAIL',
);
const String _adminPassword = String.fromEnvironment(
  'INTEGRATION_TEST_ADMIN_PASSWORD',
);

bool get _isConfigured =>
    _supabaseUrl.isNotEmpty &&
    _supabaseAnonKey.isNotEmpty &&
    _fieldStaffEmail.isNotEmpty &&
    _fieldStaffPassword.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!_isConfigured) return;
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
  });

  tearDown(() async {
    if (!_isConfigured) return;
    await Supabase.instance.client.auth.signOut();
  });

  testWidgets('ログインするとホーム画面が表示される（現場スタッフ）', (tester) async {
    if (!_isConfigured) {
      markTestSkipped('ローカルSupabaseスタックの接続情報が未設定のためスキップ（README参照）');
      return;
    }

    await tester.pumpWidget(const ProviderScope(child: KiwiInventoryApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'メールアドレス'),
      _fieldStaffEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'パスワード'),
      _fieldStaffPassword,
    );
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('ホーム'), findsOneWidget);
    // FR-003: 現場スタッフには「マスタ管理」ナビ項目が表示されない。
    expect(find.text('マスタ管理'), findsNothing);
  });

  testWidgets('現場スタッフはRLSによりマスタ（品種）への書き込みを拒否される', (tester) async {
    if (!_isConfigured) {
      markTestSkipped('ローカルSupabaseスタックの接続情報が未設定のためスキップ（README参照）');
      return;
    }

    await Supabase.instance.client.auth.signInWithPassword(
      email: _fieldStaffEmail,
      password: _fieldStaffPassword,
    );

    // FR-003 / RLSポリシー "admin write varieties": 現場スタッフによる
    // 直接INSERTは拒否されなければならない。
    await expectLater(
      Supabase.instance.client.from('varieties').insert({
        'name': 'integration-test-should-be-rejected',
      }),
      throwsA(isA<PostgrestException>()),
    );
  });

  testWidgets('管理者はマスタ（品種）を登録できる', (tester) async {
    if (!_isConfigured || _adminEmail.isEmpty || _adminPassword.isEmpty) {
      markTestSkipped('管理者用テストアカウントの接続情報が未設定のためスキップ（README参照）');
      return;
    }

    await Supabase.instance.client.auth.signInWithPassword(
      email: _adminEmail,
      password: _adminPassword,
    );

    final String uniqueName =
        'integration-test-${DateTime.now().microsecondsSinceEpoch}';
    await Supabase.instance.client.from('varieties').insert({
      'name': uniqueName,
    });

    final rows = await Supabase.instance.client
        .from('varieties')
        .select()
        .eq('name', uniqueName);
    expect(rows, hasLength(1));

    // 後始末（次回以降の実行に影響しないようにする）。
    await Supabase.instance.client
        .from('varieties')
        .delete()
        .eq('name', uniqueName);
  });
}
