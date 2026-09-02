import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/supabase_error_mapper.dart';
import '../application/master_data_providers.dart';

/// 品種・圃場（区画）・仕入先農家・保管場所を登録・編集する画面（FR-001）。
/// 管理者のみがアクセスできる（役割ガードは home_shell.dart / app_router.dart 側）。
class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const Material(
            color: Colors.transparent,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: '品種'),
                Tab(text: '圃場'),
                Tab(text: '仕入先'),
                Tab(text: '保管場所'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _VarietyTab(),
                _FieldTab(),
                _SupplierTab(),
                _StorageLocationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 一覧＋追加FABの共通レイアウト。
class _MasterDataTabScaffold extends StatelessWidget {
  const _MasterDataTabScaffold({
    required this.child,
    required this.onAddPressed,
    required this.addLabel,
  });

  final Widget child;
  final VoidCallback onAddPressed;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

void _showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(mapSupabaseErrorToMessage(error))));
}

class _VarietyTab extends ConsumerWidget {
  const _VarietyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final varietiesAsync = ref.watch(varietiesProvider);
    return _MasterDataTabScaffold(
      addLabel: '品種を追加',
      onAddPressed: () => _showAddVarietyDialog(context, ref),
      child: varietiesAsync.when(
        data: (varieties) => varieties.isEmpty
            ? const _EmptyHint(text: 'まだ品種が登録されていません')
            : ListView.builder(
                itemCount: varieties.length,
                itemBuilder: (context, index) {
                  final v = varieties[index];
                  final String? days =
                      (v.standardRipeningDaysMin != null &&
                          v.standardRipeningDaysMax != null)
                      ? '追熟目安: ${v.standardRipeningDaysMin}〜${v.standardRipeningDaysMax}日'
                      : null;
                  return ListTile(
                    title: Text(v.name),
                    subtitle: days == null ? null : Text(days),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showAddVarietyDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final minController = TextEditingController();
    final maxController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('品種を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '品種名（例: 香緑）'),
              autofocus: true,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '追熟日数(最小)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '追熟日数(最大)'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref
                    .read(masterDataRepositoryProvider)
                    .createVariety(
                      name: name,
                      standardRipeningDaysMin: int.tryParse(minController.text),
                      standardRipeningDaysMax: int.tryParse(maxController.text),
                    );
                ref.invalidate(varietiesProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) _showErrorSnackBar(context, e);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _FieldTab extends ConsumerWidget {
  const _FieldTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldsProvider);
    return _MasterDataTabScaffold(
      addLabel: '圃場を追加',
      onAddPressed: () => _showAddFieldDialog(context, ref),
      child: fieldsAsync.when(
        data: (fields) => fields.isEmpty
            ? const _EmptyHint(text: 'まだ圃場が登録されていません')
            : ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final f = fields[index];
                  return ListTile(
                    title: Text(f.name),
                    subtitle: f.location == null ? null : Text(f.location!),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showAddFieldDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('圃場を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '圃場名（例: 第1区画）'),
              autofocus: true,
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: '所在地'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref
                    .read(masterDataRepositoryProvider)
                    .createField(
                      name: name,
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                    );
                ref.invalidate(fieldsProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) _showErrorSnackBar(context, e);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SupplierTab extends ConsumerWidget {
  const _SupplierTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final dateFormat = DateFormat('yyyy/MM/dd');
    return _MasterDataTabScaffold(
      addLabel: '仕入先を追加',
      onAddPressed: () => _showAddSupplierDialog(context, ref),
      child: suppliersAsync.when(
        data: (suppliers) => suppliers.isEmpty
            ? const _EmptyHint(text: 'まだ仕入先が登録されていません')
            : ListView.builder(
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final s = suppliers[index];
                  final details = [
                    if (s.location != null) s.location,
                    if (s.contact != null) s.contact,
                    if (s.contractStartedAt != null)
                      '取引開始: ${dateFormat.format(s.contractStartedAt!)}',
                  ].join(' / ');
                  return ListTile(
                    title: Text(s.name),
                    subtitle: details.isEmpty ? null : Text(details),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final contactController = TextEditingController();
    DateTime? contractStartedAt;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('仕入先を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '仕入先名'),
                autofocus: true,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: '住所'),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: '連絡先（電話番号 or メールアドレス）',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contractStartedAt == null
                          ? '取引開始日: 未設定'
                          : '取引開始日: ${DateFormat('yyyy/MM/dd').format(contractStartedAt!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => contractStartedAt = picked);
                      }
                    },
                    child: const Text('選択'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                try {
                  await ref
                      .read(masterDataRepositoryProvider)
                      .createSupplier(
                        name: name,
                        location: locationController.text.trim().isEmpty
                            ? null
                            : locationController.text.trim(),
                        contact: contactController.text.trim().isEmpty
                            ? null
                            : contactController.text.trim(),
                        contractStartedAt: contractStartedAt,
                      );
                  ref.invalidate(suppliersProvider);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (context.mounted) _showErrorSnackBar(context, e);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageLocationTab extends ConsumerWidget {
  const _StorageLocationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageLocationsAsync = ref.watch(storageLocationsProvider);
    return _MasterDataTabScaffold(
      addLabel: '保管場所を追加',
      onAddPressed: () => _showAddStorageLocationDialog(context, ref),
      child: storageLocationsAsync.when(
        data: (locations) => locations.isEmpty
            ? const _EmptyHint(text: 'まだ保管場所が登録されていません')
            : ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(locations[index].name)),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showAddStorageLocationDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保管場所を追加'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '保管場所名（例: 冷蔵庫A）'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref
                    .read(masterDataRepositoryProvider)
                    .createStorageLocation(name: name);
                ref.invalidate(storageLocationsProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) _showErrorSnackBar(context, e);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(text, style: Theme.of(context).textTheme.bodyMedium));
}

class _ErrorHint extends StatelessWidget {
  const _ErrorHint({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(mapSupabaseErrorToMessage(error)));
}
