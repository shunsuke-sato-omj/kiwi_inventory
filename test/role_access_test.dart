import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/core/access/role_access.dart';
import 'package:kiwi_inventory/features/auth/data/auth_repository.dart';

void main() {
  group('canManageMasterData', () {
    test('管理者はマスタ管理を行える', () {
      expect(canManageMasterData(UserRole.admin), isTrue);
    });

    test('現場スタッフはマスタ管理を行えない', () {
      expect(canManageMasterData(UserRole.fieldStaff), isFalse);
    });
  });
}
