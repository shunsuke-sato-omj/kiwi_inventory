import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/supabase_error_mapper.dart';
import '../../../core/models/lot.dart';
import '../../master_data/application/master_data_providers.dart';
import '../application/harvest_providers.dart';

enum _RecordMode { harvest, purchase }

/// 数量の記録単位。重量と個数はどちらか一方だけを記録する（両方同時に
/// 記録すると、レビューで見つかった「重量0kgが個数を覆い隠す」バグの
/// 温床になるため、明示的にどちらかを選ばせる）。
enum _QuantityMode { weight, count }

/// 収穫（自社栽培）・仕入れ（select提携先）の記録画面（FR-004, FR-005, FR-006）。
///
/// Principle II（現場での使いやすさ最優先）に沿い、片手操作・チップ選択・
/// ステッパーを中心にしたフォームとする。
class HarvestScreen extends ConsumerStatefulWidget {
  const HarvestScreen({super.key});

  @override
  ConsumerState<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends ConsumerState<HarvestScreen> {
  _RecordMode _mode = _RecordMode.harvest;
  String? _selectedFieldId;
  String? _selectedVarietyId;
  String? _selectedSupplierId;
  String? _selectedStorageLocationId;
  SizeGrade? _selectedSizeGrade;
  DateTime _date = DateTime.now();
  _QuantityMode _quantityMode = _QuantityMode.weight;
  double _weightKg = 5;
  int _quantityCount = 1;
  int _containerCount = 1;

  void _resetForm() {
    setState(() {
      _selectedFieldId = null;
      _selectedVarietyId = null;
      _selectedSupplierId = null;
      _selectedStorageLocationId = null;
      _selectedSizeGrade = null;
      _date = DateTime.now();
      _quantityMode = _QuantityMode.weight;
      _weightKg = 5;
      _quantityCount = 1;
      _containerCount = 1;
    });
  }

  /// 記録単位（重量／個数）に応じて、選ばれなかった方は必ずnullで送る。
  /// 両方に値が入っていると、下流の在庫計算が重量を個数より優先してしまい、
  /// 個数記録のロットが在庫0扱いになるバグの原因になる。
  double? get _weightKgToSend =>
      _quantityMode == _QuantityMode.weight ? _weightKg : null;
  int? get _quantityCountToSend =>
      _quantityMode == _QuantityMode.count ? _quantityCount : null;

  Future<void> _submit() async {
    final controller = ref.read(harvestFormControllerProvider.notifier);
    final bool ok;
    if (_mode == _RecordMode.harvest) {
      if (_selectedFieldId == null || _selectedVarietyId == null) {
        _showSnackBar('圃場と品種を選択してください');
        return;
      }
      ok = await controller.submitHarvest(
        varietyId: _selectedVarietyId!,
        fieldId: _selectedFieldId!,
        harvestedAt: _date,
        weightKg: _weightKgToSend,
        quantityCount: _quantityCountToSend,
        sizeGrade: _selectedSizeGrade,
        containerCount: _containerCount,
        storageLocationId: _selectedStorageLocationId,
      );
    } else {
      if (_selectedSupplierId == null) {
        _showSnackBar('仕入先を選択してください');
        return;
      }
      ok = await controller.submitPurchase(
        supplierId: _selectedSupplierId!,
        purchasedAt: _date,
        weightKg: _weightKgToSend,
        quantityCount: _quantityCountToSend,
        sizeGrade: _selectedSizeGrade,
        containerCount: _containerCount,
        storageLocationId: _selectedStorageLocationId,
      );
    }

    if (!mounted) return;
    if (ok) {
      _showSnackBar('保存しました');
      _resetForm();
    } else {
      final error = ref.read(harvestFormControllerProvider).error;
      _showSnackBar(
        error == null ? '保存に失敗しました' : mapSupabaseErrorToMessage(error),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      harvestFormControllerProvider.select((s) => s.isLoading),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_RecordMode>(
            segments: const [
              ButtonSegment(
                value: _RecordMode.harvest,
                label: Text('収穫'),
                icon: Icon(Icons.eco_outlined),
              ),
              ButtonSegment(
                value: _RecordMode.purchase,
                label: Text('仕入れ'),
                icon: Icon(Icons.local_shipping_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 16),
          if (_mode == _RecordMode.harvest) ...[
            _SectionLabel('圃場'),
            _MasterDataChipSelector(
              provider: fieldsProvider,
              nameOf: (f) => f.name,
              idOf: (f) => f.id,
              selectedId: _selectedFieldId,
              onSelected: (id) => setState(() => _selectedFieldId = id),
            ),
            const SizedBox(height: 16),
            _SectionLabel('品種'),
            _MasterDataChipSelector(
              provider: varietiesProvider,
              nameOf: (v) => v.name,
              idOf: (v) => v.id,
              selectedId: _selectedVarietyId,
              onSelected: (id) => setState(() => _selectedVarietyId = id),
            ),
          ] else ...[
            _SectionLabel('仕入先'),
            _MasterDataChipSelector(
              provider: suppliersProvider,
              nameOf: (s) => s.name,
              idOf: (s) => s.id,
              selectedId: _selectedSupplierId,
              onSelected: (id) => setState(() => _selectedSupplierId = id),
            ),
          ],
          const SizedBox(height: 16),
          _SectionLabel('サイズ'),
          Wrap(
            spacing: 8,
            children: [
              for (final grade in SizeGrade.values)
                ChoiceChip(
                  label: Text(grade.label),
                  selected: _selectedSizeGrade == grade,
                  onSelected: (selected) => setState(
                    () => _selectedSizeGrade = selected ? grade : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel('保管場所'),
          _MasterDataChipSelector(
            provider: storageLocationsProvider,
            nameOf: (s) => s.name,
            idOf: (s) => s.id,
            selectedId: _selectedStorageLocationId,
            onSelected: (id) => setState(() => _selectedStorageLocationId = id),
          ),
          const SizedBox(height: 16),
          _SectionLabel(_mode == _RecordMode.harvest ? '収穫日' : '仕入日'),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(DateFormat('yyyy/MM/dd').format(_date)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 16),
          _SectionLabel('数量の記録方法'),
          SegmentedButton<_QuantityMode>(
            segments: const [
              ButtonSegment(value: _QuantityMode.weight, label: Text('重量で記録')),
              ButtonSegment(value: _QuantityMode.count, label: Text('個数で記録')),
            ],
            selected: {_quantityMode},
            onSelectionChanged: (selection) =>
                setState(() => _quantityMode = selection.first),
          ),
          const SizedBox(height: 12),
          if (_quantityMode == _QuantityMode.weight)
            _StepperField(
              label: '重量 (kg)',
              value: _weightKg,
              step: 0.5,
              min: 0,
              onChanged: (v) => setState(() => _weightKg = v),
            )
          else
            _StepperField(
              label: '個数',
              value: _quantityCount.toDouble(),
              step: 1,
              min: 1,
              onChanged: (v) => setState(() => _quantityCount = v.round()),
            ),
          const SizedBox(height: 12),
          _StepperField(
            label: 'コンテナ数',
            value: _containerCount.toDouble(),
            step: 1,
            min: 0,
            onChanged: (v) => setState(() => _containerCount = v.round()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存する'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}

/// マスタ一覧（品種/圃場/仕入先/保管場所）をチップ選択で表示する共通ウィジェット。
class _MasterDataChipSelector<T> extends ConsumerWidget {
  const _MasterDataChipSelector({
    required this.provider,
    required this.nameOf,
    required this.idOf,
    required this.selectedId,
    required this.onSelected,
  });

  final ProviderListenable<AsyncValue<List<T>>> provider;
  final String Function(T) nameOf;
  final String Function(T) idOf;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(provider);
    return asyncItems.when(
      data: (items) => items.isEmpty
          ? const Text('マスタ未登録です。先にマスタ管理から登録してください。')
          : Wrap(
              spacing: 8,
              children: [
                for (final item in items)
                  ChoiceChip(
                    label: Text(nameOf(item)),
                    selected: selectedId == idOf(item),
                    onSelected: (selected) =>
                        onSelected(selected ? idOf(item) : null),
                  ),
              ],
            ),
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text(mapSupabaseErrorToMessage(e)),
    );
  }
}

/// 「−」「＋」ボタンで増減できるステッパー入力。
class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.step,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final double value;
  final double step;
  final double min;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value - step < min ? null : () => onChanged(value - step),
        ),
        SizedBox(
          width: 56,
          child: Text(
            step >= 1 ? value.round().toString() : value.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(value + step),
        ),
      ],
    );
  }
}
