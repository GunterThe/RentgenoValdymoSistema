import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? nextRoute;

  const LoginPage({
    super.key,
    this.nextRoute,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool _busy = false;
  String? _error;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void dispose() {
    _animController.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    // start animation slightly delayed
    Future.delayed(const Duration(milliseconds: 80), () => _animController.forward());
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await AuthService.instance.login(
        prisijungimoId: _idCtrl.text.trim(),
        password: _pwCtrl.text,
      );

      if (!mounted) return;

      final next = widget.nextRoute;
      if (next != null && next.isNotEmpty && next != '/login') {
        Navigator.of(context).pushNamedAndRemoveUntil(next, (_) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Prisijungti nepavyko: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: Container(
                                width: 64,
                                height: 64,
                                color: cs.primary,
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => Center(child: Text('R', style: TextStyle(color: cs.onPrimary, fontSize: 28, fontWeight: FontWeight.w800))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rentgeno valdymas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface)),
                                const SizedBox(height: 4),
                                Text('Prisijunkite, kad tęstumėte', style: TextStyle(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _idCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Prisijungimo ID',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Įveskite prisijungimo ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwCtrl,
                          obscureText: true,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Slaptažodis',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Įveskite slaptažodį';
                            }
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(color: cs.error),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.tonal(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Prisijungti', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
