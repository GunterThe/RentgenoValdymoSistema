import 'package:flutter/material.dart';

import '../models/testas.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class TestasFormPage extends StatefulWidget {
  final Testas? item;

  const TestasFormPage({super.key, this.item});

  @override
  State<TestasFormPage> createState() => _TestasFormPageState();
}

class _TestasFormPageState extends State<TestasFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tekstasCtrl;
  bool _saving = false;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    _tekstasCtrl = TextEditingController(text: widget.item?.testotekstas ?? '');
  }

  @override
  void dispose() {
    _tekstasCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      if (_isNew) {
        await Api.createTestas({
          'testotekstas': _tekstasCtrl.text.trim()
        });
      } else {
        final it = widget.item!;
        await Api.updateTestas(it.id, {
          'id': it.id,
          'testotekstas': _tekstasCtrl.text.trim()
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida išsaugant: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isNew ? 'Naujas testas' : 'Redaguoti testą',
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
                        controller: _tekstasCtrl,
                        decoration: const InputDecoration(labelText: 'Tekstas'),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Įveskite testo tekstą';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
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
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Išsaugoti'),
                            ),
                          ),
                        ],
                      )
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
