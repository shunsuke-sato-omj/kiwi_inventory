import 'package:flutter/material.dart';

/// キウイの国 在庫管理アプリのカラー・テーマ定義。
///
/// 現場用モック（Claude Designで作成したプロトタイプ）と統一感を持たせるため、
/// キウイの葉をイメージしたグリーンを基調にしています。
abstract final class AppColors {
  static const Color accent = Color(0xFF5E8C3A);
  static const Color accentStrong = Color(0xFF446B27);
  static const Color accentSoft = Color(0xFFE4EFD4);

  static const Color background = Color(0xFFFAF6EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1EDDF);

  static const Color ink = Color(0xFF2B3324);
  static const Color inkSoft = Color(0xFF66705A);
  static const Color line = Color(0xFFE4DFCC);

  // ステータス色（在庫ロットのステータス表示用。7章 F4 参照）
  static const Color statusCold = Color(0xFF4E80B0);
  static const Color statusRipening = Color(0xFFCC8A34);
  static const Color statusReady = Color(0xFF4C8A3E);
  static const Color statusExpired = Color(0xFFB2503A);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}

/// ステータス（冷蔵保管／追熟中／追熟済み／期限切れ）の表示用ヘルパー。
/// DB上の値は英語キー（cold/ripening/ready/expired）を想定（supabase/migrations参照）。
enum LotStatus { cold, ripening, ready, expired }

extension LotStatusX on LotStatus {
  static LotStatus fromDb(String value) => switch (value) {
    'ripening' => LotStatus.ripening,
    'ready' => LotStatus.ready,
    'expired' => LotStatus.expired,
    _ => LotStatus.cold,
  };

  String get dbValue => switch (this) {
    LotStatus.cold => 'cold',
    LotStatus.ripening => 'ripening',
    LotStatus.ready => 'ready',
    LotStatus.expired => 'expired',
  };

  String get label => switch (this) {
    LotStatus.cold => '冷蔵保管',
    LotStatus.ripening => '追熟中',
    LotStatus.ready => '追熟済み',
    LotStatus.expired => '期限切れ',
  };

  Color get color => switch (this) {
    LotStatus.cold => AppColors.statusCold,
    LotStatus.ripening => AppColors.statusRipening,
    LotStatus.ready => AppColors.statusReady,
    LotStatus.expired => AppColors.statusExpired,
  };
}
