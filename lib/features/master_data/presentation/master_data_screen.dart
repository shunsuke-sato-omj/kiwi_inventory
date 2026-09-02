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

/// 追加・編集フォームの1項目の定義。4つのマスタタブ共通で使う。
enum _FieldType { text, int, date }

class _FieldSpec {
  const _FieldSpec({
    required this.key,
    required this.label,
    this.type = _FieldType.text,
    this.required = false,
  });

  final String key;
  final String label;
  final _FieldType type;
  final bool required;
}

/// 品種／圃場／仕入先／保管場所、共通の追加・編集ダイアログ。
///
/// [initialValues] を渡せば編集（既存値をプリフィル）、渡さなければ新規追加になる。
/// キャンセル時は`null`、保存時は入力値のMapを返す。
Future<Map<String, dynamic>?> _showMasterDataFormDialog({
  required BuildContext context,
  required String title,
  required List<_FieldSpec> fields,
  Map<String, dynamic>? initialValues,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => _MasterDataFormDialog(
      title: title,
      fields: fields,
      initialValues: initialValues,
    ),
  );
}

/// [_showMasterDataFormDialog]の中身。StatefulWidgetにすることで
/// TextEditingControllerを確実にdisposeする（ダイアログを閉じるたびに
/// コントローラーが残り続けるリークを防ぐ）。
class _MasterDataFormDialog extends StatefulWidget {
  const _MasterDataFormDialog({
    required this.title,
    required this.fields,
    this.initialValues,
  });

  final String title;
  final List<_FieldSpec> fields;
  final Map<String, dynamic>? initialValues;

  @override
  State<_MasterDataFormDialog> createState() => _MasterDataFormDialogState();
}

class _MasterDataFormDialogState extends State<_MasterDataFormDialog> {
  final _controllers = <String, TextEditingController>{};
  final _dateValues = <String, DateTime?>{};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.type == _FieldType.date) {
        _dateValues[field.key] = widget.initialValues?[field.key] as DateTime?;
      } else {
        _controllers[field.key] = TextEditingController(
          text: widget.initialValues?[field.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final values = <String, dynamic>{};
    for (final field in widget.fields) {
      if (field.type == _FieldType.date) {
        values[field.key] = _dateValues[field.key];
        continue;
      }
      final text = _controllers[field.key]!.text.trim();
      if (field.required && text.isEmpty) return; // 必須未入力は保存しない
      values[field.key] = switch (field.type) {
        _FieldType.int => text.isEmpty ? null : int.tryParse(text),
        _ => text.isEmpty ? null : text,
      };
    }
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in widget.fields)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: field.type == _FieldType.date
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dateValues[field.key] == null
                                  ? '${field.label}: 未設定'
                                  : '${field.label}: '
                                        '${DateFormat('yyyy/MM/dd').format(_dateValues[field.key]!)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _dateValues[field.key] ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _dateValues[field.key] = picked);
                              }
                            },
                            child: const Text('選択'),
                          ),
                        ],
                      )
                    : TextField(
                        controller: _controllers[field.key],
                        autofocus: field == widget.fields.first,
                        keyboardType: field.type == _FieldType.int
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: InputDecoration(label: Text(field.label)),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

class _VarietyTab extends ConsumerWidget {
  const _VarietyTab();

  static const _fields = [
    _FieldSpec(key: 'name', label: '品種名（例: 香緑）', required: true),
    _FieldSpec(
      key: 'standard_ripening_days_min',
      label: '追熟日数(最小)',
      type: _FieldType.int,
    ),
    _FieldSpec(
      key: 'standard_ripening_days_max',
      label: '追熟日数(最大)',
      type: _FieldType.int,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final varietiesAsync = ref.watch(varietiesProvider);
    return _MasterDataTabScaffold(
      addLabel: '品種を追加',
      onAddPressed: () => _showDialog(context, ref),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '編集',
                      onPressed: () => _showDialog(
                        context,
                        ref,
                        id: v.id,
                        initialValues: {
                          'name': v.name,
                          'standard_ripening_days_min':
                              v.standardRipeningDaysMin,
                          'standard_ripening_days_max':
                              v.standardRipeningDaysMax,
                        },
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    String? id,
    Map<String, dynamic>? initialValues,
  }) async {
    final values = await _showMasterDataFormDialog(
      context: context,
      title: id == null ? '品種を追加' : '品種を編集',
      fields: _fields,
      initialValues: initialValues,
    );
    if (values == null) return;
    try {
      final repository = ref.read(masterDataRepositoryProvider);
      final name = values['name'] as String;
      final min = values['standard_ripening_days_min'] as int?;
      final max = values['standard_ripening_days_max'] as int?;
      if (id == null) {
        await repository.createVariety(
          name: name,
          standardRipeningDaysMin: min,
          standardRipeningDaysMax: max,
        );
      } else {
        await repository.updateVariety(
          id: id,
          name: name,
          standardRipeningDaysMin: min,
          standardRipeningDaysMax: max,
        );
      }
      ref.invalidate(varietiesProvider);
    } catch (e) {
      if (context.mounted) _showErrorSnackBar(context, e);
    }
  }
}

class _FieldTab extends ConsumerWidget {
  const _FieldTab();

  static const _fields = [
    _FieldSpec(key: 'name', label: '圃場名（例: 第1区画）', required: true),
    _FieldSpec(key: 'location', label: '所在地'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldsProvider);
    return _MasterDataTabScaffold(
      addLabel: '圃場を追加',
      onAddPressed: () => _showDialog(context, ref),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '編集',
                      onPressed: () => _showDialog(
                        context,
                        ref,
                        id: f.id,
                        initialValues: {'name': f.name, 'location': f.location},
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    String? id,
    Map<String, dynamic>? initialValues,
  }) async {
    final values = await _showMasterDataFormDialog(
      context: context,
      title: id == null ? '圃場を追加' : '圃場を編集',
      fields: _fields,
      initialValues: initialValues,
    );
    if (values == null) return;
    try {
      final repository = ref.read(masterDataRepositoryProvider);
      final name = values['name'] as String;
      final location = values['location'] as String?;
      if (id == null) {
        await repository.createField(name: name, location: location);
      } else {
        await repository.updateField(id: id, name: name, location: location);
      }
      ref.invalidate(fieldsProvider);
    } catch (e) {
      if (context.mounted) _showErrorSnackBar(context, e);
    }
  }
}

class _SupplierTab extends ConsumerWidget {
  const _SupplierTab();

  static const _fields = [
    _FieldSpec(key: 'name', label: '仕入先名', required: true),
    _FieldSpec(key: 'location', label: '住所'),
    _FieldSpec(key: 'contact', label: '連絡先（電話番号 or メールアドレス）'),
    _FieldSpec(
      key: 'contract_started_at',
      label: '取引開始日',
      type: _FieldType.date,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final dateFormat = DateFormat('yyyy/MM/dd');
    return _MasterDataTabScaffold(
      addLabel: '仕入先を追加',
      onAddPressed: () => _showDialog(context, ref),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '編集',
                      onPressed: () => _showDialog(
                        context,
                        ref,
                        id: s.id,
                        initialValues: {
                          'name': s.name,
                          'location': s.location,
                          'contact': s.contact,
                          'contract_started_at': s.contractStartedAt,
                        },
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    String? id,
    Map<String, dynamic>? initialValues,
  }) async {
    final values = await _showMasterDataFormDialog(
      context: context,
      title: id == null ? '仕入先を追加' : '仕入先を編集',
      fields: _fields,
      initialValues: initialValues,
    );
    if (values == null) return;
    try {
      final repository = ref.read(masterDataRepositoryProvider);
      final name = values['name'] as String;
      final location = values['location'] as String?;
      final contact = values['contact'] as String?;
      final contractStartedAt = values['contract_started_at'] as DateTime?;
      if (id == null) {
        await repository.createSupplier(
          name: name,
          location: location,
          contact: contact,
          contractStartedAt: contractStartedAt,
        );
      } else {
        await repository.updateSupplier(
          id: id,
          name: name,
          location: location,
          contact: contact,
          contractStartedAt: contractStartedAt,
        );
      }
      ref.invalidate(suppliersProvider);
    } catch (e) {
      if (context.mounted) _showErrorSnackBar(context, e);
    }
  }
}

class _StorageLocationTab extends ConsumerWidget {
  const _StorageLocationTab();

  static const _fields = [
    _FieldSpec(key: 'name', label: '保管場所名（例: 冷蔵庫A）', required: true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageLocationsAsync = ref.watch(storageLocationsProvider);
    return _MasterDataTabScaffold(
      addLabel: '保管場所を追加',
      onAddPressed: () => _showDialog(context, ref),
      child: storageLocationsAsync.when(
        data: (locations) => locations.isEmpty
            ? const _EmptyHint(text: 'まだ保管場所が登録されていません')
            : ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return ListTile(
                    title: Text(location.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '編集',
                      onPressed: () => _showDialog(
                        context,
                        ref,
                        id: location.id,
                        initialValues: {'name': location.name},
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorHint(error: e),
      ),
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    String? id,
    Map<String, dynamic>? initialValues,
  }) async {
    final values = await _showMasterDataFormDialog(
      context: context,
      title: id == null ? '保管場所を追加' : '保管場所を編集',
      fields: _fields,
      initialValues: initialValues,
    );
    if (values == null) return;
    try {
      final repository = ref.read(masterDataRepositoryProvider);
      final name = values['name'] as String;
      if (id == null) {
        await repository.createStorageLocation(name: name);
      } else {
        await repository.updateStorageLocation(id: id, name: name);
      }
      ref.invalidate(storageLocationsProvider);
    } catch (e) {
      if (context.mounted) _showErrorSnackBar(context, e);
    }
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
