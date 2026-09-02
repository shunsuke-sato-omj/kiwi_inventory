import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  // 未捕捉の例外で真っ白な画面のまま固まるのを避け、必ず何らかの
  // エラー表示を出せるようにする（コードレビューで見つかった、
  // 設定漏れ・Supabase接続失敗時に無反応になる問題への対応）。
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (!Env.isConfigured) {
        runApp(
          const _StartupErrorApp(
            message:
                'SUPABASE_URL / SUPABASE_ANON_KEY が設定されていません。\n'
                '--dart-define で指定して起動し直してください（README参照）。',
          ),
        );
        return;
      }

      try {
        await Supabase.initialize(
          url: Env.supabaseUrl,
          publishableKey: Env.supabaseAnonKey,
        );
      } catch (_) {
        runApp(
          const _StartupErrorApp(
            message: '通信状態が悪いか、サーバーに接続できませんでした。\n電波の良い場所で再度お試しください。',
          ),
        );
        return;
      }

      runApp(const ProviderScope(child: KiwiInventoryApp()));
    },
    (error, stack) {
      // 現状はデバッグ出力のみ。外部ロギングサービスへの送信は将来の課題とする。
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

/// 起動できなかったときに、真っ白な画面ではなく理由を表示するための最小限の画面。
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
