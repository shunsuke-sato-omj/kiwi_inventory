import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/supabase_error_mapper.dart';
import '../../../core/models/lot.dart';
import '../../../core/models/shipment.dart';
import '../application/shipping_providers.dart';
import '../data/shipping_repository.dart';

/// 出荷記録画面（FR-011, FR-012, FR-017）。
class ShippingScreen extends ConsumerStatefulWidget {
  const ShippingScreen({super.key});

  @override
  ConsumerState<ShippingScreen> createState() => _ShippingScreenState();
}

class _ShippingScreenState extends ConsumerState<ShippingScreen> {
  Lot? _selectedLot;
  ShipmentChannel _channel = ShipmentChannel.ec;
  DeliveryMethod _deliveryMethod = DeliveryMethod.sagawa;
  DateTime _shippedAt = DateTime.now();
  double _quantityKg = 1;
  String? _inlineError;

  Future<void> _submit() async {
    setState(() => _inlineError = null);
    final lot = _selectedLot;
    if (lot == null) {
      setState(() => _inlineError = '出荷するロットを選択してください');
      return;
    }

    final controller = ref.read(shipmentFormControllerProvider.notifier);
    final bool ok = await controller.submit(
      lotId: lot.id,
      channel: _channel,
      quantityKg: _quantityKg,
      deliveryMethod: _deliveryMethod,
      shippedAt: _shippedAt,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('出荷を記録しました')));
      ref.invalidate(shippableLotsProvider);
      setState(() {
        _selectedLot = null;
        _quantityKg = 1;
      });
    } else {
      final error = ref.read(shipmentFormControllerProvider).error;
      setState(() => _inlineError = _describeError(error));
    }
  }

  /// FR-017の在庫超過エラーはそのままユーザーに見せ、それ以外（通信断など）は
  /// [mapSupabaseErrorToMessage] で現場向けの一般的な文言に変換する。
  String _describeError(Object? error) {
    if (error == null) return '保存に失敗しました';
    if (error is ShipmentQuantityExceededException) return error.message;
    return mapSupabaseErrorToMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final lotsAsync = ref.watch(shippableLotsProvider);
    final isSubmitting = ref.watch(
      shipmentFormControllerProvider.select((s) => s.isLoading),
    );
    final remainingAsync = _selectedLot == null
        ? null
        : ref.watch(remainingQuantityProvider(_selectedLot!.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('対象ロット', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          lotsAsync.when(
            data: (lots) => lots.isEmpty
                ? const Text('出荷できる在庫ロットがありません')
                : Wrap(
                    spacing: 8,
                    children: [
                      for (final lot in lots)
                        ChoiceChip(
                          label: Text('${lot.varietyName ?? lot.lotCode} (${lot.lotCode})'),
                          selected: _selectedLot?.id == lot.id,
                          onSelected: (selected) => setState(
                            () => _selectedLot = selected ? lot : null,
                          ),
                        ),
                    ],
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text(mapSupabaseErrorToMessage(e)),
          ),
          if (remainingAsync != null) ...[
            const SizedBox(height: 8),
            remainingAsync.when(
              data: (remaining) => Text('残り在庫: $remaining kg'),
              loading: () => const Text('残り在庫を確認中...'),
              error: (e, st) => Text(mapSupabaseErrorToMessage(e)),
            ),
          ],
          const SizedBox(height: 16),
          Text('出荷先', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ShipmentChannel>(
            segments: [
              for (final channel in ShipmentChannel.values)
                ButtonSegment(value: channel, label: Text(channel.label)),
            ],
            selected: {_channel},
            onSelectionChanged: (selection) =>
                setState(() => _channel = selection.first),
          ),
          if (_channel.requiresDeliveryMethod) ...[
            const SizedBox(height: 16),
            Text('配送方法', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final method in DeliveryMethod.values.where(
                  (m) => m != DeliveryMethod.none,
                ))
                  ChoiceChip(
                    label: Text(method.label),
                    selected: _deliveryMethod == method,
                    onSelected: (_) =>
                        setState(() => _deliveryMethod = method),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('出荷日', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(DateFormat('yyyy/MM/dd').format(_shippedAt)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _shippedAt,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _shippedAt = picked);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '出荷数量 (kg)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantityKg - 0.5 <= 0
                    ? null
                    : () => setState(() => _quantityKg -= 0.5),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  _quantityKg.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantityKg += 0.5),
              ),
            ],
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: 12),
            Text(_inlineError!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('出荷を記録する'),
          ),
        ],
      ),
    );
  }
}
