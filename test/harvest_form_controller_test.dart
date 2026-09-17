import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/features/harvest/application/harvest_providers.dart';
import 'package:kiwi_inventory/features/harvest/data/harvest_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Repositoryをmocktailでモック化する例（constitution Principle II: unitテスト）。
/// SupabaseClientは一切登場せず、`HarvestRepository`という抽象だけを差し替える。
class MockHarvestRepository extends Mock implements HarvestRepository {}

void main() {
  setUpAll(() {
    // DateTimeは非nullな引数として渡すため、any()用のフォールバック値が必要。
    registerFallbackValue(DateTime(2000));
  });

  late MockHarvestRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockHarvestRepository();
    container = ProviderContainer(
      overrides: [harvestRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() => container.dispose());

  group('HarvestFormController.submitHarvest', () {
    test('保存に成功するとtrueを返し、状態はエラーなしになる', () async {
      when(
        () => mockRepository.recordHarvest(
          varietyId: any(named: 'varietyId'),
          fieldId: any(named: 'fieldId'),
          harvestedAt: any(named: 'harvestedAt'),
          weightKg: any(named: 'weightKg'),
          quantityCount: any(named: 'quantityCount'),
          sizeGrade: any(named: 'sizeGrade'),
          containerCount: any(named: 'containerCount'),
          storageLocationId: any(named: 'storageLocationId'),
        ),
      ).thenAnswer((_) async {});

      final controller = container.read(harvestFormControllerProvider.notifier);
      final result = await controller.submitHarvest(
        varietyId: 'v1',
        fieldId: 'f1',
        harvestedAt: DateTime(2026, 9, 2),
        weightKg: 5,
      );

      expect(result, isTrue);
      expect(container.read(harvestFormControllerProvider).hasError, isFalse);
      verify(
        () => mockRepository.recordHarvest(
          varietyId: 'v1',
          fieldId: 'f1',
          harvestedAt: DateTime(2026, 9, 2),
          weightKg: 5,
          quantityCount: null,
          sizeGrade: null,
          containerCount: null,
          storageLocationId: null,
        ),
      ).called(1);
    });

    test('保存に失敗するとfalseを返し、状態はエラーになる', () async {
      when(
        () => mockRepository.recordHarvest(
          varietyId: any(named: 'varietyId'),
          fieldId: any(named: 'fieldId'),
          harvestedAt: any(named: 'harvestedAt'),
          weightKg: any(named: 'weightKg'),
          quantityCount: any(named: 'quantityCount'),
          sizeGrade: any(named: 'sizeGrade'),
          containerCount: any(named: 'containerCount'),
          storageLocationId: any(named: 'storageLocationId'),
        ),
      ).thenThrow(Exception('network error'));

      final controller = container.read(harvestFormControllerProvider.notifier);
      final result = await controller.submitHarvest(
        varietyId: 'v1',
        fieldId: 'f1',
        harvestedAt: DateTime(2026, 9, 2),
      );

      expect(result, isFalse);
      expect(container.read(harvestFormControllerProvider).hasError, isTrue);
    });
  });
}
