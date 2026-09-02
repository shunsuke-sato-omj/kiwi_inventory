import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/core/theme/app_theme.dart';

void main() {
  group('LotStatus', () {
    test('日本語ラベルを返す', () {
      expect(LotStatus.cold.label, '冷蔵保管');
      expect(LotStatus.ripening.label, '追熟中');
      expect(LotStatus.ready.label, '追熟済み');
      expect(LotStatus.expired.label, '期限切れ');
    });
  });
}
