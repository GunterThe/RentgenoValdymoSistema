import 'package:flutter/material.dart';
import '../services/api.dart';

class ReportValuesPage extends StatefulWidget {
  final int fatReportId;
  final String fatReportText;
  const ReportValuesPage({super.key, required this.fatReportId, required this.fatReportText});

  @override
  State<ReportValuesPage> createState() => _ReportValuesPageState();
}

class _ReportTemplatesWithValue {
  final int templateId;
  final String templateText;
  final int order;
  String? value;
  int? valueId;

  _ReportTemplatesWithValue({required this.templateId, required this.templateText, required this.order});
}

class _ReportValuesPageState extends State<ReportValuesPage> {
  List<_ReportTemplatesWithValue> _items = [];
  List<Map<String, dynamic>> _irasai = [];
  bool _loading = true;
  int? _selectedIrasasId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final templates = await Api.fetchReportTemplates(widget.fatReportId);
      final list = (templates).map((e) => e as Map<String, dynamic>).toList()..sort((a,b) => (a['order'] as int).compareTo(b['order'] as int));

      _items = list.map((t) => _ReportTemplatesWithValue(templateId: t['id'] as int, templateText: t['text'] as String, order: t['order'] as int)).toList();

      final irasaiRaw = await Api.fetchFATReportIrasai();
      _irasai = (irasaiRaw).where((e) {
        final m = e as Map<String, dynamic>;
        return m['fatreportId'] == widget.fatReportId || m['fatReportId'] == widget.fatReportId || m['fatreport_id'] == widget.fatReportId || m['fatreportid'] == widget.fatReportId;
      }).map((e) => e as Map<String, dynamic>).toList();
      if (_irasai.isNotEmpty) {
        _selectedIrasasId = _irasai.first['id'] as int;
        await _loadValuesForSelected();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadValuesForSelected() async {
    if (_selectedIrasasId == null) return;
    for (final t in _items) {
      try {
        final v = await Api.fetchReportValueByEverything(_selectedIrasasId!, t.templateId);
        final map = v;
        t.value = map['value'] as String?;
        t.valueId = map['id'] as int?;
      } catch (_) {
        t.value = null;
        t.valueId = null;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _createOrEditValue(_ReportTemplatesWithValue t) async {
    final ctrl = TextEditingController(text: t.value ?? '');
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reikšmė: ${t.templateText}'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reikšmė')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Išsaugoti')),
        ],
      ),
    );
    if (ok != true) return;
    final text = ctrl.text.trim();
    if (_selectedIrasasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasirinkite įrašą')));
      return;
    }

    try {
      if (t.valueId == null) {
        final created = await Api.createReportValue({
          'value': text,
          'fatreport_irasasid': _selectedIrasasId,
          'report_template_id': t.templateId,
        });
        final m = created;
        t.value = m['value'] as String?;
        t.valueId = m['id'] as int?;
      } else {
        final payload = {'id': t.valueId, 'value': text, 'fatreport_irasasid': _selectedIrasasId, 'report_template_id': t.templateId};
        await Api.updateReportValue(t.valueId!, payload);
        t.value = text;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  Future<void> _createIrasas() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naujas FATReport įrašas'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Irasas ID (skaičius)')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sukurti')),
        ],
      ),
    );
    if (ok != true) return;
    final text = ctrl.text.trim();
    final irasasId = int.tryParse(text);
    if (irasasId == null) return;
    try {
      final created = await Api.createFATReportIrasas({'fatReportId': widget.fatReportId, 'irasasId': irasasId});
      _irasai.add(created);
      _selectedIrasasId = (created)['id'] as int;
      await _loadValuesForSelected();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reikšmės: ${widget.fatReportText}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedIrasasId,
                            items: _irasai
                                .map((r) => DropdownMenuItem(value: r['id'] as int, child: Text('Įrašas: ${r['irasasId'] ?? r['irasasid'] ?? r['irasasid']} (id: ${r['id']})')))
                                .toList(),
                            onChanged: (v) async {
                              setState(() => _selectedIrasasId = v);
                              await _loadValuesForSelected();
                            },
                            decoration: const InputDecoration(labelText: 'Pasirinkti įrašą'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(onPressed: _createIrasas, icon: const Icon(Icons.add), label: const Text('Naujas įrašas')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _items.isEmpty
                              ? Center(child: Text('Nėra šablonų', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                              : ListView.separated(
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final it = _items[i];
                                    return Card(
                                      margin: EdgeInsets.zero,
                                      child: ListTile(
                                        title: Text(it.templateText),
                                        subtitle: Text(it.value ?? '(tuščia)'),
                                        trailing: IconButton(onPressed: () => _createOrEditValue(it), icon: const Icon(Icons.edit)),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
