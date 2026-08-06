import 'dart:math';

import 'package:flutter/material.dart';

import '../models/irasas.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

class IrasasColumnPage extends StatefulWidget {
  final Irasas irasas;

  const IrasasColumnPage({super.key, required this.irasas});

  @override
  State<IrasasColumnPage> createState() => _IrasasColumnPageState();
}

class _IrasasColumnPageState extends State<IrasasColumnPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rowIrasai = [];
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _columnTemplates = [];
  List<Map<String, dynamic>> _columnValues = [];
  List<Map<String, dynamic>> _headers = [];
  List<Map<String, dynamic>> _rowValues = [];
  Map<String, String> _userNameById = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _editing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Api.fetchRowIrasai(),
        Api.fetchRows(),
        Api.fetchColumnTemplates(),
        Api.fetchColumnValues(),
        Api.fetchHeaders(),
        Api.fetchRowValues(),
        Api.fetchNaudotojai(),
      ]);

      final rowIrasai = (results[0])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final rows = (results[1]).map((e) => e as Map<String, dynamic>).toList();
      final templates = (results[2])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final values = (results[3])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final headers = (results[4])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final rowValues = (results[5])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final naudotojai = results[6];
      setState(() {
        _rowIrasai = rowIrasai
            .where(
              (r) =>
                  (r['irasasId'] ?? r['irasasid'] ?? r['irasas_id']) ==
                  widget.irasas.id,
            )
            .toList();
        _rowIrasai.sort(
          (a, b) =>
              (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0),
        );
        _rows = rows;
        _columnTemplates = templates;
        _columnValues = values;
        _headers = headers;
        _rowValues = rowValues;
        _userNameById = {
          for (final u in (naudotojai).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ))
            ((u['id'] ?? u['Id']).toString()):
                ('${((u['vardas'] ?? u['Vardas'] ?? '') as String).trim()} ${((u['pavarde'] ?? u['Pavarde'] ?? '') as String).trim()}')
                    .trim(),
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant FAT: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attachFat() async {
    try {
      final fats = await Api.fetchFATs();
      int? selectedId;
      if (!mounted) return;
      final ok = await showDialog<bool?>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Pridėti FAT šabloną'),
            content: SizedBox(
              width: 560,
              child: ListView(
                shrinkWrap: true,
                children: fats.map<Widget>((f) {
                  final fm = f as Map<String, dynamic>;
                  return RadioListTile<int>(
                    value: fm['id'] as int,
                    groupValue: selectedId,
                    title: Text(
                      fm['title'] ?? fm['Title'] ?? 'FAT #${fm['id']}',
                    ),
                    onChanged: (v) => setLocal(() => selectedId = v),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Atšaukti'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Pridėti'),
              ),
            ],
          ),
        ),
      );

      if (ok != true || selectedId == null) return;
      await Api.attachFATTemplateToIrasas(widget.irasas.id, selectedId!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('FAT pridėtas')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida pridedant FAT: $e')));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  Map<String, dynamic>? _getRowValueForRowIrasas(Map<String, dynamic> r) {
    final rowIrasasId = (r['id'] ?? r['Id']);
    final rowId = (r['rowId'] ?? r['rowid'] ?? r['row_id']);
    final found = _rowValues.firstWhere(
      (v) =>
          (v['rowIrasasId'] ?? v['row_irasas_id'] ?? v['RowIrasasId']) ==
              rowIrasasId &&
          (v['rowId'] ?? v['row_id'] ?? v['RowId']) == rowId,
      orElse: () => <String, dynamic>{},
    );
    return found.isEmpty ? null : found as Map<String, dynamic>?;
  }

  Future<void> _saveRowValue(Map<String, dynamic> r, String value) async {
    try {
      final existing = _getRowValueForRowIrasas(r);
      final rowIrasasId = (r['id'] ?? r['Id']) as int;
      final rowId = (r['rowId'] ?? r['rowid'] ?? r['row_id']) as int;
      final userId = AuthService.instance.currentUserId ?? '';
      final nowIso = DateTime.now().toIso8601String();
      if (existing == null) {
        final payload = <String, dynamic>{
          'value': value,
          'rowId': rowId,
          'rowIrasasId': rowIrasasId,
          'completedByUserId': userId,
          'completedAt': nowIso,
        };
        await Api.createRowValue(payload);
      } else {
        final id = existing['id'] ?? existing['Id'];
        final payload = <String, dynamic>{
          'id': id,
          'value': value,
          'rowId': rowId,
          'rowIrasasId': rowIrasasId,
          'completedByUserId': userId,
          'completedAt': nowIso,
        };
        await Api.updateRowValue(id as int, payload);
      }
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Eilutės būsena išsaugota')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida įrašant eilutės būseną: $e')),
      );
    }
  }

  Future<void> _saveValue({
    required String key,
    required Map<String, dynamic> r,
    required Map<String, dynamic> tpl,
  }) async {
    final controller = _controllers[key]!;
    final text = controller.text.trim();
    final isArray =
        tpl['isArray'] ?? tpl['is_array'] ?? tpl['IsArray'] ?? false;

    dynamic payloadValue;
    try {
      if (isArray == true || isArray == 1) {
        if (text.isEmpty) {
          payloadValue = <num>[];
        } else {
          final parts = text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          payloadValue = parts.map((p) => num.parse(p)).toList();
        }
      } else {
        if (text.isEmpty) {
          payloadValue = null;
        } else {
          payloadValue = num.parse(text);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neteisingas skaičiaus formatas')),
      );
      return;
    }

    final existing = _columnValues.firstWhere(
      (v) =>
          (v['rowIrasasId'] ?? v['row_irasas_id'] ?? v['RowIrasasId']) ==
              (r['id'] ?? r['Id']) &&
          (v['columnTemplateId'] ??
                  v['column_template_id'] ??
                  v['ColumnTemplateId']) ==
              (tpl['id'] ?? tpl['Id']),
      orElse: () => <String, dynamic>{},
    );

    final rowIrasasId = (r['id'] ?? r['Id']) as int;
    final columnTemplateId = (tpl['id'] ?? tpl['Id']) as int;
    final userId = AuthService.instance.currentUserId ?? '';

    try {
      if (existing.isEmpty) {
        final createPayload = <String, dynamic>{
          'rowIrasasId': rowIrasasId,
          'columnTemplateId': columnTemplateId,
          'completedByUserId': userId,
        };
        if (isArray == true || isArray == 1) {
          createPayload['arrayValue'] = payloadValue;
        } else {
          createPayload['singleValue'] = payloadValue;
        }
        await Api.createColumnValue(createPayload);
      } else {
        final id = existing['id'] ?? existing['Id'];
        final updatePayload = <String, dynamic>{
          'id': id,
          'rowIrasasId': rowIrasasId,
          'columnTemplateId': columnTemplateId,
          'completedByUserId': userId,
        };
        if (isArray == true || isArray == 1) {
          updatePayload['arrayValue'] = payloadValue;
        } else {
          updatePayload['singleValue'] = payloadValue;
        }
        await Api.updateColumnValue(id as int, updatePayload);
      }

      if (!mounted) return;
      _editing.remove(key);
      await _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Įrašyta')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida įrašant reikšmę: $e')));
    }
  }

  Future<void> _saveArrayValue({
    required String key,
    required Map<String, dynamic> r,
    required Map<String, dynamic> tpl,
    required int arrayLen,
  }) async {
    final values = <num>[];
    for (var i = 0; i < arrayLen; i++) {
      final k = '${key}_$i';
      final text = _controllers[k]?.text.trim() ?? '';
      if (text.isEmpty) {
      } else {
        try {
          values.add(num.parse(text));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Neteisingas skaičiaus formatas')),
          );
          return;
        }
      }
    }

    final rowIrasasId = (r['id'] ?? r['Id']) as int;
    final columnTemplateId = (tpl['id'] ?? tpl['Id']) as int;
    final userId = AuthService.instance.currentUserId ?? '';

    final existing = _columnValues.firstWhere(
      (v) =>
          (v['rowIrasasId'] ?? v['row_irasas_id'] ?? v['RowIrasasId']) ==
              rowIrasasId &&
          (v['columnTemplateId'] ??
                  v['column_template_id'] ??
                  v['ColumnTemplateId']) ==
              columnTemplateId,
      orElse: () => <String, dynamic>{},
    );

    try {
      if (existing.isEmpty) {
        final createPayload = <String, dynamic>{
          'rowIrasasId': rowIrasasId,
          'columnTemplateId': columnTemplateId,
          'completedByUserId': userId,
          'arrayValue': values,
        };
        await Api.createColumnValue(createPayload);
      } else {
        final id = existing['id'] ?? existing['Id'];
        final updatePayload = <String, dynamic>{
          'id': id,
          'rowIrasasId': rowIrasasId,
          'columnTemplateId': columnTemplateId,
          'completedByUserId': userId,
          'arrayValue': values,
        };
        await Api.updateColumnValue(id as int, updatePayload);
      }

      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Įrašyta')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida įrašant masyvą: $e')));
    }
  }

  String? _headerTextForTemplate(Map<String, dynamic> template) {
    final hid =
        template['headerId'] ?? template['header_id'] ?? template['HeaderId'];
    if (hid == null) return null;
    final h = _headers.firstWhere(
      (x) => (x['id'] ?? x['Id']) == hid,
      orElse: () => <String, dynamic>{},
    );
    if (h.isEmpty) return null;
    return h['text'] ?? h['Text'];
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Peržiūrėti FAT',
      actions: [
        IconButton(
          tooltip: 'Atnaujinti',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _rowIrasai.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.irasas.pavadinimas,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Šitam įrašui nėra FAT eilučių. Pridėkite FAT šabloną.',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _attachFat,
                            child: const Text('Pridėti FAT šabloną'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _rowIrasai.length,
                        itemBuilder: (ctx, index) {
                          final r = _rowIrasai[index];
                          final rowDef = _rows.firstWhere(
                            (x) =>
                                (x['id'] ?? x['Id']) ==
                                (r['rowId'] ?? r['rowid'] ?? r['row_id']),
                            orElse: () => <String, dynamic>{
                              'description':
                                  'Eilutė #${r['rowId'] ?? r['rowid'] ?? '?'}',
                            },
                          );

                          final rowId = r['rowId'] ?? r['rowid'] ?? r['row_id'];
                          final templates = _columnTemplates
                              .where(
                                (t) =>
                                    (t['rowId'] ?? t['row_id'] ?? t['RowId']) ==
                                    rowId,
                              )
                              .toList();
                          templates.sort(
                            (a, b) => (a['order'] as int? ?? 0).compareTo(
                              b['order'] as int? ?? 0,
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rowDef['description'] ??
                                        rowDef['Description'] ??
                                        'Eilutė',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Control methods and row value selector
                                  if ((rowDef['controlMethods'] ?? '')
                                          is String &&
                                      (rowDef['controlMethods'] ?? '')
                                          .toString()
                                          .isNotEmpty) ...[
                                    Text(
                                      'Kontrolės metodai: ${(rowDef['controlMethods'] ?? '') as String}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Builder(
                                    builder: (ctx) {
                                      final rv = _getRowValueForRowIrasas(r);
                                      final current = (rv == null)
                                          ? 'empty'
                                          : (rv['value'] ??
                                                rv['Value'] ??
                                                'empty');
                                      final completedRaw = rv == null
                                          ? null
                                          : (rv['completed_at'] ??
                                                rv['completedAt'] ??
                                                rv['CompletedAt']);
                                      final completedBy = rv == null
                                          ? null
                                          : (rv['completed_by_user_id'] ??
                                                    rv['completedByUserId'] ??
                                                    rv['CompletedByUserId'])
                                                ?.toString();
                                      String? compText;
                                      if (completedRaw != null) {
                                        final dt = DateTime.tryParse(
                                          completedRaw.toString(),
                                        )?.toLocal();
                                        final dateStr = dt == null
                                            ? ''
                                            : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                        final uname = completedBy == null
                                            ? ''
                                            : (_userNameById[completedBy] ??
                                                  completedBy);
                                        compText =
                                            'Pabaigtas: $dateStr • $uname';
                                      }

                                      // Stack vertically on small screens to avoid horizontal overflow
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          DropdownButton<String>(
                                            value: current is String
                                                ? current
                                                : current.toString(),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'empty',
                                                child: Text('empty'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'compliant',
                                                child: Text('compliant'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'non-compliant',
                                                child: Text('non-compliant'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'not-specified',
                                                child: Text('not-specified'),
                                              ),
                                            ],
                                            onChanged: (v) async {
                                              if (v == null) return;
                                              await _saveRowValue(r, v);
                                            },
                                          ),
                                          if (compText != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              child: Text(
                                                compText,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (templates.isNotEmpty)
                                    Builder(
                                      builder: (ctx) {
                                        // group templates by header id while preserving order
                                        final Map<
                                          dynamic,
                                          List<Map<String, dynamic>>
                                        >
                                        groups = {};
                                        final List<dynamic> groupKeys = [];
                                        for (var tpl in templates) {
                                          final hid =
                                              tpl['headerId'] ??
                                              tpl['header_id'] ??
                                              tpl['HeaderId'];
                                          if (!groups.containsKey(hid)) {
                                            groups[hid] = [];
                                            groupKeys.add(hid);
                                          }
                                          groups[hid]!.add(tpl);
                                        }

                                        Widget buildTplWidget(
                                          Map<String, dynamic> tpl,
                                        ) {
                                          final screenWidth = MediaQuery.of(
                                            ctx,
                                          ).size.width;
                                          final smallScreen = screenWidth < 380;
                                          final inputWidthSmall = smallScreen
                                              ? 56.0
                                              : 72.0;
                                          final singleInputWidth = min(
                                            160.0,
                                            screenWidth * 0.45,
                                          );
                                          final val = _columnValues.firstWhere(
                                            (v) =>
                                                (v['rowIrasasId'] ??
                                                        v['row_irasas_id'] ??
                                                        v['RowIrasasId']) ==
                                                    (r['id'] ?? r['Id']) &&
                                                (v['columnTemplateId'] ??
                                                        v['column_template_id'] ??
                                                        v['ColumnTemplateId']) ==
                                                    (tpl['id'] ?? tpl['Id']),
                                            orElse: () => <String, dynamic>{},
                                          );
                                          final valueMap = val.isEmpty
                                              ? null
                                              : val as Map<String, dynamic>?;
                                          final isArray =
                                              tpl['isArray'] ??
                                              tpl['is_array'] ??
                                              tpl['IsArray'] ??
                                              false;
                                          final arrayLen =
                                              tpl['arrayLength'] ??
                                              tpl['array_length'] ??
                                              tpl['ArrayLength'] ??
                                              0;
                                          final tplId = (tpl['id'] ?? tpl['Id'])
                                              .toString();
                                          final rId = (r['id'] ?? r['Id'])
                                              .toString();
                                          final key = '${rId}_$tplId';

                                          String? _completedText() {
                                            if (valueMap == null) return null;
                                            final raw =
                                                valueMap['completed_at'] ??
                                                valueMap['completedAt'] ??
                                                valueMap['CompletedAt'];
                                            if (raw == null) return null;
                                            final dt = DateTime.tryParse(
                                              raw.toString(),
                                            )?.toLocal();
                                            final dateStr = dt == null
                                                ? ''
                                                : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                            final uid =
                                                (valueMap['completed_by_user_id'] ??
                                                        valueMap['completedByUserId'] ??
                                                        valueMap['CompletedByUserId'])
                                                    ?.toString();
                                            final uname = uid == null
                                                ? ''
                                                : (_userNameById[uid] ?? uid);
                                            return 'Pabaigtas: $dateStr • $uname';
                                          }

                                          if (isArray == true || isArray == 1) {
                                            if (arrayLen is int &&
                                                arrayLen > 0) {
                                              final existingList =
                                                  (valueMap == null)
                                                  ? List<String>.filled(
                                                      arrayLen,
                                                      '',
                                                    )
                                                  : ((valueMap['arrayValue'] ??
                                                                valueMap['array_value'] ??
                                                                valueMap['arrayValue'])
                                                            is List
                                                        ? List<String>.from(
                                                            ((valueMap['arrayValue'] ??
                                                                        valueMap['array_value'] ??
                                                                        valueMap['arrayValue'])
                                                                    as List)
                                                                .map(
                                                                  (e) =>
                                                                      e?.toString() ??
                                                                      '',
                                                                ),
                                                          )
                                                        : List<String>.filled(
                                                            arrayLen,
                                                            '',
                                                          ));
                                              for (
                                                var i = 0;
                                                i < arrayLen;
                                                i++
                                              ) {
                                                final k = '${key}_$i';
                                                _controllers.putIfAbsent(
                                                  k,
                                                  () => TextEditingController(
                                                    text:
                                                        i < existingList.length
                                                        ? existingList[i]
                                                        : '',
                                                  ),
                                                );
                                              }
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tpl['description'] ??
                                                        tpl['Description'] ??
                                                        'Stulpelis #$tplId',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Use Wrap so long arrays flow to multiple rows instead of causing layout issues
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: List.generate(arrayLen, (
                                                      i,
                                                    ) {
                                                      final k = '${key}_$i';
                                                      final c =
                                                          _controllers[k]!;
                                                      return SizedBox(
                                                        width: inputWidthSmall,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                right: 0.0,
                                                              ),
                                                          child: TextField(
                                                            controller: c,
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      '${i + 1}',
                                                                  isDense: true,
                                                                ),
                                                            onSubmitted: (_) async {
                                                              await _saveArrayValue(
                                                                key: key,
                                                                r: r,
                                                                tpl: tpl,
                                                                arrayLen:
                                                                    arrayLen,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ElevatedButton(
                                                    onPressed: () async =>
                                                        await _saveArrayValue(
                                                          key: key,
                                                          r: r,
                                                          tpl: tpl,
                                                          arrayLen: arrayLen,
                                                        ),
                                                    child: const Text(
                                                      'Išsaugoti',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (_completedText() != null)
                                                    Text(
                                                      _completedText()!,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              );
                                            }
                                            final initialText = valueMap == null
                                                ? ''
                                                : ((valueMap['arrayValue'] ??
                                                              valueMap['array_value'] ??
                                                              valueMap['arrayValue'])
                                                          is List
                                                      ? (valueMap['arrayValue'] ??
                                                                valueMap['array_value'] ??
                                                                valueMap['arrayValue'])
                                                            .join(', ')
                                                      : '');
                                            final controller = _controllers
                                                .putIfAbsent(
                                                  key,
                                                  () => TextEditingController(
                                                    text: initialText,
                                                  ),
                                                );
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tpl['description'] ??
                                                      tpl['Description'] ??
                                                      'Stulpelis #$tplId',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller: controller,
                                                        keyboardType:
                                                            TextInputType.text,
                                                        decoration:
                                                            const InputDecoration(
                                                              isDense: true,
                                                            ),
                                                        onSubmitted: (_) =>
                                                            _saveValue(
                                                              key: key,
                                                              r: r,
                                                              tpl: tpl,
                                                            ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.check,
                                                      ),
                                                      onPressed: () =>
                                                          _saveValue(
                                                            key: key,
                                                            r: r,
                                                            tpl: tpl,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                if (_completedText() != null)
                                                  Text(
                                                    _completedText()!,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            );
                                          }

                                          final initialText = valueMap == null
                                              ? ''
                                              : ((valueMap['singleValue'] ??
                                                            valueMap['single_value'] ??
                                                            valueMap['singleValue'])
                                                        ?.toString() ??
                                                    '');
                                          final controller = _controllers
                                              .putIfAbsent(
                                                key,
                                                () => TextEditingController(
                                                  text: initialText,
                                                ),
                                              );
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tpl['description'] ??
                                                    tpl['Description'] ??
                                                    'Stulpelis #$tplId',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: singleInputWidth,
                                                    child: TextField(
                                                      controller: controller,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      decoration:
                                                          const InputDecoration(
                                                            isDense: true,
                                                          ),
                                                      onSubmitted: (_) =>
                                                          _saveValue(
                                                            key: key,
                                                            r: r,
                                                            tpl: tpl,
                                                          ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.check,
                                                    ),
                                                    onPressed: () => _saveValue(
                                                      key: key,
                                                      r: r,
                                                      tpl: tpl,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              if (_completedText() != null)
                                                Text(
                                                  _completedText()!,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          );
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: groupKeys.map<Widget>((k) {
                                            final group = groups[k]!;
                                            final headerText = k == null
                                                ? null
                                                : (group.firstWhere(
                                                            (t) => true,
                                                          )['headerId'] ==
                                                          null
                                                      ? null
                                                      : _headerTextForTemplate(
                                                          group.first,
                                                        ));
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.22),
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .shadowColor
                                                        .withOpacity(0.06),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Header banner spanning the group
                                                  if (headerText != null)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                            horizontal: 14,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                      ),
                                                      child: Text(
                                                        headerText,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  // Templates stacked vertically beneath the banner for mobile
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: group.map<Widget>((
                                                        tpl,
                                                      ) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 12.0,
                                                              ),
                                                          child: ConstrainedBox(
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 640,
                                                                ),
                                                            child:
                                                                buildTplWidget(
                                                                  tpl,
                                                                ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
