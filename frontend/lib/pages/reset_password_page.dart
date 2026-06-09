import 'package:flutter/material.dart';
import '../services/api.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? tokenFromArgs;
  const ResetPasswordPage({super.key, this.tokenFromArgs});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = widget.tokenFromArgs ?? Uri.base.queryParameters['token'];
  }

  @override
  void dispose() {
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final t = _token ?? '';
    final p1 = _pw1.text;
    final p2 = _pw2.text;
    if (t.isEmpty) {
      _snack('Trūksta tokeno');
      return;
    }
    if (p1.trim().isEmpty || p2.trim().isEmpty) {
      _snack('Užpildykite laukus');
      return;
    }
    if (p1 != p2) {
      _snack('Slaptažodžiai nesutampa');
      return;
    }
    if (p1.trim().length < 6) {
      _snack('Slaptažodis turi būti bent 6 simbolių');
      return;
    }

    setState(() => _busy = true);
    try {
      await Api.resetPassword(token: t, newPassword: p1);
      if (!mounted) return;
      _pw1.clear();
      _pw2.clear();
      _snack('Slaptažodis pakeistas');
      // Optionally redirect to login
    } catch (e) {
      if (!mounted) return;
      _snack('Klaida: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atstatyti slaptažodį')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_token == null || _token!.isEmpty) ...[
              const Text('Nuoroda neteisinga arba token trūksta.'),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _pw1,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Naujas slaptažodis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pw2,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Pakartokite slaptažodį',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const CircularProgressIndicator() : const Text('Pakeisti slaptažodį'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
