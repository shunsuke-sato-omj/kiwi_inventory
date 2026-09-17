import 'dart:async';

import 'package:flutter/foundation.dart';

/// go_router の `refreshListenable` に Stream を渡すための定番アダプタ。
/// (Supabase の認証状態の変化を検知して、ルートの redirect を再評価させる)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  /// Stream以外の要因（非同期に取得する役割情報の解決など）でも
  /// redirectを再評価させたいときに呼ぶ。
  void ping() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
