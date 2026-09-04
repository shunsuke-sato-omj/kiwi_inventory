import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_error_mapper.dart';
import '../../../core/theme/app_theme.dart';
import '../application/auth_providers.dart';

/// ログイン画面（現場スタッフ・管理者共通）。
///
/// MVPではメール＋パスワードのみ。少人数（現場5名＋管理者2名）なので
/// アカウントは基本的に管理者がSupabase側で発行する運用を想定（要件定義書 5章）。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      setState(() {
        // AuthExceptionのmessageには「メール未確認」「認証情報が誤り」等、
        // 原因の異なる具体的な内容が入っているため、汎用文言で握りつぶさず
        // そのまま見せる（現場・管理者からの問い合わせ対応をしやすくするため）。
        _errorMessage = e is AuthException
            ? _describeAuthError(e)
            : mapSupabaseErrorToMessage(e);
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Supabase Authからのエラーを、原因が分かるように日本語化する。
  /// 未知のケースはmessageをそのまま出す（原因不明のまま握りつぶさない）。
  String _describeAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'メールアドレスまたはパスワードが正しくありません。';
    }
    if (message.contains('email not confirmed')) {
      return 'メールアドレスの確認が完了していません。管理者にご確認ください。';
    }
    if (message.contains('rate limit')) {
      return '試行回数が多すぎます。しばらく時間をおいて再度お試しください。';
    }
    return 'ログインできませんでした（${e.message}）。解決しない場合は管理者にご連絡ください。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco, size: 48, color: AppColors.accent),
                  const SizedBox(height: 12),
                  Text(
                    'キウイの国 在庫アプリ',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'メールアドレスを入力してください' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'パスワード'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'パスワードを入力してください' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ログイン'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
