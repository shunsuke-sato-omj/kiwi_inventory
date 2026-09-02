import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/supabase_error_mapper.dart';
import '../../../core/models/lot.dart';
import '../../../core/theme/app_theme.dart';
import '../application/inventory_providers.dart';

/// 在庫ロットの一覧・ステータス絞り込み・状態変更（誤操作の訂正含む）画面
/// （FR-007〜FR-010）。
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(inventoryStatusFilterProvider);
    final lotsAsync = ref.watch(filteredLotsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('すべて'),
                selected: currentFilter == null,
                onSelected: (_) =>
                    ref.read(inventoryStatusFilterProvider.notifier).state =
                        null,
              ),
              for (final status in LotStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: currentFilter == status,
                  onSelected: (_) =>
                      ref.read(inventoryStatusFilterProvider.notifier).state =
                          status,
                ),
            ],
          ),
        ),
        Expanded(
          child: lotsAsync.when(
            data: (lots) => lots.isEmpty
                ? const Center(child: Text('該当する在庫ロットがありません'))
                : ListView.builder(
                    itemCount: lots.length,
                    itemBuilder: (context, index) => _LotTile(lot: lots[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text(mapSupabaseErrorToMessage(e))),
          ),
        ),
      ],
    );
  }
}

/// ロットのポップアップメニュー項目。ステータス変更、または履歴表示のどちらか。
class _LotMenuAction {
  const _LotMenuAction.changeStatus(this.status);

  const _LotMenuAction.viewHistory() : status = null;

  final LotStatus? status;
}

class _LotTile extends ConsumerWidget {
  const _LotTile({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return ListTile(
      title: Text(lot.varietyName ?? lot.lotCode),
      subtitle: Text(
        '${lot.lotCode} / ${dateFormat.format(lot.harvestedOrPurchasedAt)}'
        '${lot.weightKg != null ? ' / ${lot.weightKg}kg' : ''}'
        '${lot.sizeGrade != null ? ' / ${lot.sizeGrade!.label}' : ''}',
      ),
      leading: Chip(
        label: Text(lot.status.label),
        backgroundColor: lot.status.color.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: lot.status.color),
      ),
      trailing: PopupMenuButton<_LotMenuAction>(
        icon: const Icon(Icons.more_vert),
        onSelected: (action) async {
          if (action.status != null) {
            try {
              await ref
                  .read(inventoryRepositoryProvider)
                  .updateStatus(lotId: lot.id, newStatus: action.status!);
              ref.invalidate(filteredLotsProvider);
              // 変更履歴シートを開き直したときに古い履歴が出ないよう、
              // このロットの履歴キャッシュも破棄する（FR-009）。
              ref.invalidate(lotStatusHistoryProvider(lot.id));
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mapSupabaseErrorToMessage(e))),
                );
              }
            }
          } else {
            _showHistorySheet(context, ref, lot.id);
          }
        },
        itemBuilder: (context) => [
          for (final status in LotStatus.values)
            PopupMenuItem(
              value: _LotMenuAction.changeStatus(status),
              child: Text('→ ${status.label}'),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _LotMenuAction.viewHistory(),
            child: Text('変更履歴を見る'),
          ),
        ],
      ),
      onTap: () => _showHistorySheet(context, ref, lot.id),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref, String lotId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _StatusHistorySheet(lotId: lotId),
    );
  }
}

/// ステータス変更履歴の表示（FR-009: 後から遡って確認できる）。
class _StatusHistorySheet extends ConsumerWidget {
  const _StatusHistorySheet({required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(lotStatusHistoryProvider(lotId));
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('変更履歴', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: historyAsync.when(
                data: (history) => history.isEmpty
                    ? const Text('履歴がありません')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          final from = entry.fromStatus?.label ?? '(新規作成)';
                          return ListTile(
                            dense: true,
                            title: Text('$from → ${entry.toStatus.label}'),
                            subtitle: Text(dateFormat.format(entry.changedAt)),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text(mapSupabaseErrorToMessage(e)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
