import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/core/validation/shipment_validation.dart';

void main() {
  group('validateShipmentQuantity (FR-017)', () {
    test('残り在庫を超える数量はエラーになる', () {
      final error = validateShipmentQuantity(requested: 11, remaining: 10);
      expect(error, isNotNull);
    });

    test('残り在庫とちょうど同じ数量は許可される', () {
      final error = validateShipmentQuantity(requested: 10, remaining: 10);
      expect(error, isNull);
    });

    test('残り在庫を下回る数量は許可される', () {
      final error = validateShipmentQuantity(requested: 5, remaining: 10);
      expect(error, isNull);
    });

    test('0以下の数量はエラーになる', () {
      expect(validateShipmentQuantity(requested: 0, remaining: 10), isNotNull);
      expect(
        validateShipmentQuantity(requested: -1, remaining: 10),
        isNotNull,
      );
    });
  });
}
