import 'package:flutter/material.dart';

import '../models/irasas.dart';
import '../models/testas.dart';
import '../models/testas_irasas.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class IrasasFormPage extends StatefulWidget {
  final Irasas? item;

  const IrasasFormPage({super.key, this.item});

  @override
  State<IrasasFormPage> createState() => _IrasasFormPageState();
}

class _IrasasFormPageState extends State<IrasasFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idDokumentoCtrl;
  late final TextEditingController _pavadinimasCtrl;
  late final TextEditingController _pradziaCtrl;
  late final TextEditingController _pabaigaCtrl;
  bool _saving = false;

  bool _loadingTestai = false;
  List<TestasIrasas> _attached = [];
  Map<int, Testas> _testaiById = {};

  late DateTime _pradzia;
  late DateTime _pabaiga;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    _idDokumentoCtrl = TextEditingController(
      text: widget.item?.idDokumento ?? '',
    );
    _pavadinimasCtrl = TextEditingController(
      text: widget.item?.pavadinimas ?? '',
    );

    _pradzia = widget.item?.pradzia ?? DateTime.now();
    _pabaiga = widget.item?.pabaiga ?? DateTime.now();
    _pradziaCtrl = TextEditingController(text: _fmtDt(_pradzia));
    _pabaigaCtrl = TextEditingController(text: _fmtDt(_pabaiga));

    if (!_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAttachedTestai();
      });
    }
  }

  @override
  void dispose() {
    _idDokumentoCtrl.dispose();
    _pavadinimasCtrl.dispose();
    _pradziaCtrl.dispose();
    _pabaigaCtrl.dispose();
    super.dispose();
  }

  String _fmtDt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _editPradzia() async {
    final picked = await _pickDateTime(_pradzia);
    if (picked == null) return;
    setState(() {
      _pradzia = picked;
      _pradziaCtrl.text = _fmtDt(_pradzia);
      if (_pabaiga.isBefore(_pradzia)) {
        _pabaiga = _pradzia;
        _pabaigaCtrl.text = _fmtDt(_pabaiga);
      }
    });
  }

  Future<void> _editPabaiga() async {
    final picked = await _pickDateTime(_pabaiga);
    if (picked == null) return;
    setState(() {
      _pabaiga = picked;
      _pabaigaCtrl.text = _fmtDt(_pabaiga);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pabaiga.isBefore(_pradzia)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pabaiga negali būti anksčiau nei pradžia'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isNew) {
        await Api.createIrasas({
          'idDokumento': _idDokumentoCtrl.text.trim(),
          'pavadinimas': _pavadinimasCtrl.text.trim(),
          'pradzia': _pradzia.toIso8601String(),
          'pabaiga': _pabaiga.toIso8601String(),
        });
      } else {
        final it = widget.item!;
        await Api.updateIrasas(it.id, {
          'id': it.id,
          'idDokumento': _idDokumentoCtrl.text.trim(),
          'pavadinimas': _pavadinimasCtrl.text.trim(),
          'pradzia': _pradzia.toIso8601String(),
          'pabaiga': _pabaiga.toIso8601String(),
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida išsaugant: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadAttachedTestai() async {
    final it = widget.item;
    if (it == null) return;
    if (_loadingTestai) return;

    setState(() => _loadingTestai = true);
    try {
      final linksRaw = await Api.fetchTestasIrasai();
      final allLinks = linksRaw
          .map((e) => TestasIrasas.fromJson(e as Map<String, dynamic>))
          .toList();
      final attached = allLinks.where((e) => e.irasasid == it.id).toList();

      final testaiRaw = await Api.fetchTestai();
      final testai = testaiRaw
          .map((e) => Testas.fromJson(e as Map<String, dynamic>))
          .toList();
      final byId = {for (final t in testai) t.id: t};

      if (!mounted) return;
      setState(() {
        _attached = attached;
        _testaiById = byId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kraunant testus: $e')));
    } finally {
      if (mounted) setState(() => _loadingTestai = false);
    }
  }

  Future<Testas?> _pickExistingTestas() async {
    final testaiRaw = await Api.fetchTestai();
    final all = testaiRaw
        .map((e) => Testas.fromJson(e as Map<String, dynamic>))
        .toList();

    if (!mounted) return null;

    return showDialog<Testas>(
      context: context,
      builder: (context) {
        String query = '';
        return AlertDialog(
          title: const Text('Pridėti esamą testą'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              final shown = query.trim().isEmpty
                  ? all
                  : all
                        .where(
                          (t) => t.testotekstas.toLowerCase().contains(
                            query.trim().toLowerCase(),
                          ),
                        )
                        .toList();

              return SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Paieška',
                      ),
                      onChanged: (v) => setStateDialog(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final t = shown[idx];
                          return ListTile(
                            title: Text(t.testotekstas),
                            onTap: () => Navigator.of(context).pop(t),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Uždaryti'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _attachExistingTestas() async {
    final irasas = widget.item;
    if (irasas == null) return;
    try {
      final selected = await _pickExistingTestas();
      if (selected == null) return;

      final already = _attached.any((e) => e.testasid == selected.id);
      if (already) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Šis testas jau pridėtas.')),
        );
        return;
      }

      await Api.createTestasIrasas({
        'testasid': selected.id,
        'irasasid': irasas.id,
        'atliktas': false,
      });

      await _loadAttachedTestai();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida pridedant testą: $e')));
    }
  }

  Future<void> _createAndAttachNewTestasPopup() async {
    final irasas = widget.item;
    if (irasas == null) return;

    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Naujas testas'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Tekstas'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Atšaukti'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sukurti'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final text = ctrl.text.trim();
    if (text.isEmpty) return;

    try {
      final createdRaw = await Api.createTestas({'testotekstas': text});
      final created = Testas.fromJson(createdRaw);
      await Api.createTestasIrasas({
        'testasid': created.id,
        'irasasid': irasas.id,
        'atliktas': false,
      });
      await _loadAttachedTestai();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Klaida kuriant testą: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isNew ? 'Naujas įrašas' : 'Redaguoti įrašą',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _idDokumentoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dokumento ID',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Įveskite dokumento ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pavadinimasCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pavadinimas',
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Įveskite pavadinimą';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pradziaCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Pradžia',
                          suffixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        onTap: _saving ? null : _editPradzia,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pabaigaCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Pabaiga',
                          suffixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        onTap: _saving ? null : _editPabaiga,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Testai',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Atnaujinti testus',
                            onPressed: (_isNew || _loadingTestai)
                                ? null
                                : _loadAttachedTestai,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      if (_isNew)
                        Text(
                          'Išsaugokite įrašą, kad galėtumėte pridėti testus.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: (_saving || _loadingTestai)
                                    ? null
                                    : _attachExistingTestas,
                                child: const Text('Pridėti esamą'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: (_saving || _loadingTestai)
                                    ? null
                                    : _createAndAttachNewTestasPopup,
                                child: const Text('Naujas testas'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_loadingTestai)
                          const Center(child: CircularProgressIndicator())
                        else if (_attached.isEmpty)
                          Text(
                            'Testų nepridėta',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Column(
                            children: _attached.map((link) {
                              final testas = _testaiById[link.testasid];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  testas?.testotekstas ??
                                      'Testas #${link.testasid}',
                                ),
                                subtitle: Text(
                                  link.atliktas ? 'Atliktas' : 'Neatliktas',
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              child: const Text('Atšaukti'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Išsaugoti'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
