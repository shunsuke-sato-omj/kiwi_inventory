import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_error_mapper.dart';
import '../../../core/models/lot.dart';
import '../../../core/models/master_data.dart';
import '../../../core/theme/app_theme.dart';
import '../application/dashboard_providers.dart';

/// ホーム画面: 「追熟完了が近いロット」「在庫が少ない品種」を一覧表示する
/// （FR-013, FR-014, SC-006）。
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearingRipenessAsync = ref.watch(nearingRipenessLotsProvider);
    final lowStockAsync = ref.watch(lowStockVarietiesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeLotsProvider);
        ref.invalidate(dashboardVarietiesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(icon: Icons.hourglass_bottom, title: '追熟完了が近いロット'),
          const SizedBox(height: 8),
          nearingRipenessAsync.when(
            data: (lots) => lots.isEmpty
                ? const _EmptyCard(text: '追熟完了が近いロットはありません')
                : Column(
                    children: [for (final lot in lots) _LotCard(lot: lot)],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => _ErrorCard(error: e),
          ),
          const SizedBox(height: 24),
          _SectionHeader(icon: Icons.warning_amber, title: '在庫が少ない品種'),
          const SizedBox(height: 8),
          lowStockAsync.when(
            data: (varieties) => varieties.isEmpty
                ? const _EmptyCard(text: '在庫が少ない品種はありません')
                : Column(
                    children: [
                      for (final variety in varieties)
                        _VarietyCard(variety: variety),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => _ErrorCard(error: e),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.eco, color: lot.status.color),
        title: Text(lot.varietyName ?? lot.lotCode),
        subtitle: Text('${lot.lotCode} / ${lot.status.label}'),
      ),
    );
  }
}

class _VarietyCard extends StatelessWidget {
  const _VarietyCard({required this.variety});

  final Variety variety;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(variety.name),
        subtitle: const Text('在庫が少なくなっています'),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(mapSupabaseErrorToMessage(error)),
    ),
  );
}
