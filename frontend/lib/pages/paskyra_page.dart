import 'package:flutter/material.dart';

import '../models/naudotojas.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

class PaskyraPage extends StatefulWidget {
  const PaskyraPage({super.key});

  @override
  State<PaskyraPage> createState() => _PaskyraPageState();
}

class _PaskyraPageState extends State<PaskyraPage> {
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _newPw2 = TextEditingController();
  final _searchCtrl = TextEditingController();

  bool _busy = false;

  List<Naudotojas> _users = const [];
  String? _selectedUserId;
  bool _loadingUsers = false;
  String _search = '';

  bool get _isAdmin => AuthService.instance.isAdmin;
  bool get _isSuperAdmin => AuthService.instance.isSuperAdmin;

  @override
  void initState() {
    super.initState();
    if (_isAdmin || _isSuperAdmin) {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _newPw2.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadUsers() async {
    if (!_isAdmin && !_isSuperAdmin) return;
    if (_loadingUsers) return;

    setState(() => _loadingUsers = true);
    try {
      final list = await Api.fetchNaudotojai();
      final users = list
          .whereType<Map<String, dynamic>>()
          .map(Naudotojas.fromJson)
          .toList();

      users.sort((a, b) => a.fullName.compareTo(b.fullName));

      setState(() {
        _users = users;
        final current = _selectedUserId;
        if (current != null && users.any((u) => u.id == current)) {
          _selectedUserId = current;
        } else {
          if (!_isSuperAdmin) {
            final firstNonAdmin = users.where((u) => u.adminas != true).toList();
            _selectedUserId =
                firstNonAdmin.isEmpty ? (users.isEmpty ? null : users.first.id) : firstNonAdmin.first.id;
          } else {
            _selectedUserId = users.isEmpty ? null : (users.first.id);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Nepavyko gauti naudotojų: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingUsers = false);
      }
    }
  }

  Future<void> _submitChangePassword() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) {
      _snack('Nepavyko nustatyti prisijungusio naudotojo');
      return;
    }

    final current = _currentPw.text;
    final new1 = _newPw.text;
    final new2 = _newPw2.text;

    if (current.trim().isEmpty || new1.trim().isEmpty || new2.trim().isEmpty) {
      _snack('Užpildykite visus slaptažodžio laukus');
      return;
    }

    if (new1 != new2) {
      _snack('Nauji slaptažodžiai nesutampa');
      return;
    }

    if (new1.trim().length < 6) {
      _snack('Naujas slaptažodis turi būti bent 6 simbolių');
      return;
    }

    setState(() => _busy = true);
    try {
      await Api.changePassword(
        userId: userId,
        currentPassword: current,
        newPassword: new1,
      );
      if (!mounted) return;
      _currentPw.clear();
      _newPw.clear();
      _newPw2.clear();
      _snack('Slaptažodis pakeistas');
    } catch (e) {
      if (!mounted) return;
      _snack('Nepavyko pakeisti slaptažodžio: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _ensureUsersLoaded() async {
    if (!_isAdmin && !_isSuperAdmin) return;
    if (_users.isNotEmpty) return;
    await _loadUsers();
  }


  Future<void> _showAdminSetPasswordForUser(String userId) async {
    if (!_isAdmin) return;
    final pw1 = TextEditingController();
    final pw2 = TextEditingController();
    // ignore: unused_local_variable
    var busy = false;
    StateSetter? setStateDialogRef;
    var closing = false;

    Future<void> submit(StateSetter setStateDialog) async {
      if (userId.isEmpty) return;
      final new1 = pw1.text;
      final new2 = pw2.text;
      if (new1.trim().isEmpty || new2.trim().isEmpty) {
        _snack('Įveskite naują slaptažodį');
        return;
      }
      if (new1 != new2) {
        _snack('Nauji slaptažodžiai nesutampa');
        return;
      }
      if (new1.trim().length < 6) {
        _snack('Naujas slaptažodis turi būti bent 6 simbolių');
        return;
      }

      setStateDialog(() => busy = true);
      try {
        await Api.adminSetPassword(userId: userId, newPassword: new1);
        if (!mounted) {
          closing = true;
          return;
        }
        closing = true;
        Navigator.of(context).pop();
        _snack('Naudotojo slaptažodis pakeistas');
      } catch (e) {
        if (!mounted) {
          closing = true;
          return;
        }
        _snack('Nepavyko pakeisti naudotojo slaptažodžio: $e');
      } finally {
        if (!closing) setStateDialog(() => busy = false);
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keisti naudotojo slaptažodį'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            setStateDialogRef = setStateDialog;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pw1,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Naujas slaptažodis',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pw2,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Pakartokite naują slaptažodį',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Atšaukti'),
          ),
          FilledButton(
            onPressed: () {
              final s = setStateDialogRef;
              if (s == null) return;
              submit(s);
            },
            child: const Text('Pakeisti'),
          ),
        ],
      ),
    );

    pw1.dispose();
    pw2.dispose();
  }

  Future<void> _confirmDeleteUser(String userId, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trinti naudotoją'),
        content: Text('Ar tikrai norite ištrinti naudotoją "$label"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Trinti')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteNaudotojas(id: userId);
      _snack('Naudotojas ištrintas');
      await _loadUsers();
    } catch (e) {
      _snack('Nepavyko ištrinti naudotojo: $e');
    }
  }

  Future<void> _toggleAdminForUser(String userId) async {
    if (!_isSuperAdmin) {
      _snack('Reikia superadministratoriaus teisių');
      return;
    }
    try {
      await Api.superAdminToggleAdmin(userId: userId);
      _snack('Teisės atnaujintos');
      await _loadUsers();
    } catch (e) {
      _snack('Nepavyko atnaujinti teisių: $e');
    }
  }

  Future<void> _confirmDeleteOrphanFiles() async {
    if (!_isAdmin) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ištrinti nenaudotus failus'),
        content: const Text('Ar tikrai norite ištrinti diske esančius failus, kurie nėra susieti su DB įrašais?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Atšaukti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ištrinti')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await Api.deleteOrphanFiles();
      _snack('Nenaudoti failai ištrinti');
    } catch (e) {
      _snack('Klaida trinant failus: $e');
    }
  }

  Future<void> _showEditUserDialog(Naudotojas user) async {
    if (!_isAdmin) return;
    final vardasCtrl = TextEditingController(text: user.vardas);
    final pavardeCtrl = TextEditingController(text: user.pavarde);
    DateTime? gimimo;
    var adminas = user.adminas == true;
    var busy = false;
    StateSetter? setStateDialogRef;
    var closing = false;

    Future<void> submit(StateSetter setStateDialog) async {
      final vardas = vardasCtrl.text.trim();
      final pavarde = pavardeCtrl.text.trim();
      if (vardas.isEmpty || pavarde.isEmpty) {
        _snack('Įveskite vardą ir pavardę');
        return;
      }
      setStateDialog(() => busy = true);
      try {
        final payload = {
          'id': user.id,
          'vardas': vardas,
          'pavarde': pavarde,
          'gimimoData': (gimimo ?? DateTime(1990, 1, 1)).toIso8601String(),
          'adminas': adminas,
          // preserve known fields where possible
          'passwordHash': '',
          'prisijungimoId': user.prisijungimoId ?? '',
          'superAdminas': false,
          'mustChangePassword': false,
          'refreshToken': [],
          'zinutes': [],
        };

        await Api.updateNaudotojas(payload: payload, id: user.id);
        if (!mounted) {
          closing = true;
          return;
        }
        closing = true;
        Navigator.of(context).pop();
        _snack('Naudotojas atnaujintas');
        await _loadUsers();
      } catch (e) {
        if (!mounted) {
          closing = true;
          return;
        }
        _snack('Nepavyko atnaujinti naudotojo: $e');
      } finally {
        if (!closing) setStateDialog(() => busy = false);
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redaguoti naudotoją'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            setStateDialogRef = setStateDialog;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: vardasCtrl,
                  decoration: const InputDecoration(labelText: 'Vardas', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pavardeCtrl,
                  decoration: const InputDecoration(labelText: 'Pavardė', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                if (_isSuperAdmin) ...[
                  SwitchListTile(
                    value: adminas,
                    onChanged: busy ? null : (v) => setStateDialog(() => adminas = v),
                    title: const Text('Administratorius'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Atšaukti')),
          FilledButton(
            onPressed: busy
                ? null
                : () {
                    final s = setStateDialogRef;
                    if (s == null) return;
                    submit(s);
                  },
            child: Text(busy ? 'Vykdoma...' : 'Išsaugoti'),
          ),
        ],
      ),
    );

    vardasCtrl.dispose();
    pavardeCtrl.dispose();
  }

  Future<void> _showSuperAdminToggleAdminDialog() async {
    if (!_isSuperAdmin) return;
    await _ensureUsersLoaded();

    var selected = _selectedUserId;
    var busy = false;
    StateSetter? setStateDialogRef;
    var closing = false;

    Future<void> submit(StateSetter setStateDialog) async {
      final targetUserId = selected;
      if (targetUserId == null || targetUserId.isEmpty) {
        _snack('Pasirinkite naudotoją');
        return;
      }

      setStateDialog(() => busy = true);
      try {
        await Api.superAdminToggleAdmin(userId: targetUserId);

        await _loadUsers();

        if (!mounted) {
          closing = true;
          return;
        }
        setState(() => _selectedUserId = targetUserId);

        closing = true;
        Navigator.of(context).pop();
        _snack('Administratoriaus teisės atnaujintos');
      } catch (e) {
        if (!mounted) {
          closing = true;
          return;
        }
        _snack('Nepavyko pakeisti admin teisių: $e');
      } finally {
        if (!closing) {
          setStateDialog(() => busy = false);
        }
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Administratoriaus teisės'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            setStateDialogRef = setStateDialog;

            Naudotojas? selectedUser;
            final selectedId = selected;
            if (selectedId != null && selectedId.isNotEmpty) {
              for (final u in _users) {
                if (u.id == selectedId) {
                  selectedUser = u;
                  break;
                }
              }
            }
            final isAdminNow = selectedUser?.adminas;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadingUsers)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: _users
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (v) {
                          setStateDialog(() => selected = v);
                        },
                  decoration: const InputDecoration(
                    labelText: 'Naudotojas',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isAdminNow != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isAdminNow
                          ? 'Dabartinė būsena: administratorius'
                          : 'Dabartinė būsena: naudotojas',
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(ctx).pop(),
            child: const Text('Atšaukti'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () {
                    final s = setStateDialogRef;
                    if (s == null) return;
                    submit(s);
                  },
            child: Text(busy ? 'Vykdoma...' : 'Perjungti'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminCreateUserDialog() async {
    if (!_isAdmin) return;

    final vardasCtrl = TextEditingController();
    final pavardeCtrl = TextEditingController();
    final pw1 = TextEditingController();
    final pw2 = TextEditingController();

    DateTime? gimimo;
    var adminas = false;
    var busy = false;
    StateSetter? setStateDialogRef;
    var closing = false;

    Future<void> pickDate(StateSetter setStateDialog) async {
      final now = DateTime.now();
      final initial = gimimo ?? DateTime(now.year - 18, now.month, now.day);
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900, 1, 1),
        lastDate: DateTime(now.year + 1, 12, 31),
      );
      if (picked == null) return;
      setStateDialog(() => gimimo = picked);
    }

    Future<void> submit(StateSetter setStateDialog) async {
      final vardas = vardasCtrl.text.trim();
      final pavarde = pavardeCtrl.text.trim();
      final p1 = pw1.text;
      final p2 = pw2.text;

      if (vardas.isEmpty || pavarde.isEmpty) {
        _snack('Įveskite vardą ir pavardę');
        return;
      }
      if (gimimo == null) {
        _snack('Pasirinkite gimimo datą');
        return;
      }
      if (p1.trim().isEmpty || p2.trim().isEmpty) {
        _snack('Įveskite slaptažodį');
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

      setStateDialog(() => busy = true);
      try {
        final created = await Api.adminCreateNaudotojas(
          vardas: vardas,
          pavarde: pavarde,
          gimimoData: gimimo!,
          adminas: _isSuperAdmin ? adminas : false,
          password: p1,
        );

        await _loadUsers();

        if (!mounted) {
          closing = true;
          return;
        }
        final login = (created['prisijungimoId'] ?? created['prisijungimoid'])
            ?.toString();

        closing = true;
        Navigator.of(context).pop();
        _snack(
          login == null || login.isEmpty
              ? 'Naudotojas sukurtas'
              : 'Naudotojas sukurtas: $login',
        );
      } catch (e) {
        if (!mounted) {
          closing = true;
          return;
        }
        _snack('Nepavyko sukurti naudotojo: $e');
      } finally {
        if (!closing) {
          setStateDialog(() => busy = false);
        }
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sukurti naują naudotoją'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            setStateDialogRef = setStateDialog;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: vardasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vardas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pavardeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pavardė',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : () => pickDate(setStateDialog),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          gimimo == null
                              ? 'Gimimo data'
                              : '${gimimo!.year.toString().padLeft(4, '0')}-${gimimo!.month.toString().padLeft(2, '0')}-${gimimo!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isSuperAdmin) ...[
                  SwitchListTile(
                    value: adminas,
                    onChanged: busy
                        ? null
                        : (v) => setStateDialog(() => adminas = v),
                    title: const Text('Administratorius'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                ],
                TextField(
                  controller: pw1,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Slaptažodis',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pw2,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Pakartokite slaptažodį',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(ctx).pop(),
            child: const Text('Atšaukti'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () {
                    final s = setStateDialogRef;
                    if (s == null) return;
                    submit(s);
                  },
            child: Text(busy ? 'Vykdoma...' : 'Sukurti'),
          ),
        ],
      ),
    );

    vardasCtrl.dispose();
    pavardeCtrl.dispose();
    pw1.dispose();
    pw2.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = AuthService.instance.displayName;
    final pid = AuthService.instance.prisijungimoId;

    return AppScaffold(
      title: 'Paskyra',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Naudotojas' : name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (pid.isNotEmpty)
                      Text(
                        pid,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _isAdmin ? Icons.verified_user : Icons.person,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAdmin ? 'Administratorius' : 'Naudotojas',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keisti slaptažodį',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currentPw,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Dabartinis slaptažodis',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPw,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Naujas slaptažodis',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPw2,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Pakartokite naują slaptažodį',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _submitChangePassword,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_reset),
                        label: Text(_busy ? 'Vykdoma...' : 'Pakeisti slaptažodį'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isSuperAdmin) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text(
                    'Super administravimas',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Perjungti naudotojo admin teises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await _showSuperAdminToggleAdminDialog();
                  },
                ),
              ),
            ],
            if (_isAdmin) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Naudotojai',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadingUsers ? null : _loadUsers,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Atnaujinti',
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _loadingUsers ? null : _showAdminCreateUserDialog,
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('Sukurti'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _loadingUsers ? null : () => _confirmDeleteOrphanFiles(),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Ištrinti nenaudotus failus'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Paieška',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingUsers) const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final filtered = _users.where((u) {
                            if (_search.isEmpty) return true;
                            final s = _search;
                            final name = u.fullName.toLowerCase();
                            final pid = (u.prisijungimoId ?? '').toLowerCase();
                            return name.contains(s) || pid.contains(s);
                          }).toList();

                          final isNarrow = constraints.maxWidth < 600;

                          if (isNarrow) {
                            return Column(
                              children: filtered.map((u) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(u.fullName),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if ((u.prisijungimoId ?? '').isNotEmpty) Text(u.prisijungimoId ?? ''),
                                        Text(u.adminas == true ? 'Administratorius' : 'Naudotojas'),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          _showEditUserDialog(u);
                                        } else if (v == 'delete') {
                                          _confirmDeleteUser(u.id, u.displayLabel);
                                        } else if (v == 'pw') {
                                          _showAdminSetPasswordForUser(u.id);
                                        } else if (v == 'toggle' && _isSuperAdmin) {
                                          _toggleAdminForUser(u.id);
                                        }
                                      },
                                      itemBuilder: (ctx) {
                                        final items = <PopupMenuEntry<String>>[
                                          const PopupMenuItem(value: 'edit', child: Text('Redaguoti')),
                                          const PopupMenuItem(value: 'delete', child: Text('Ištrinti')),
                                          const PopupMenuItem(value: 'pw', child: Text('Atstatyti slaptažodį')),
                                        ];
                                        if (_isSuperAdmin) {
                                          items.add(const PopupMenuItem(value: 'toggle', child: Text('Perjungti admin')));
                                        }
                                        return items;
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Vardas')),
                                DataColumn(label: Text('Prisijungimo ID')),
                                DataColumn(label: Text('Taisyklės')),
                                DataColumn(label: Text('Veiksmai')),
                              ],
                              rows: filtered
                                  .map(
                                    (u) => DataRow(cells: [
                                      DataCell(Text(u.fullName)),
                                      DataCell(Text(u.prisijungimoId ?? '')),
                                      DataCell(Text(u.adminas == true ? 'Administratorius' : 'Naudotojas')),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Redaguoti',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showEditUserDialog(u),
                                          ),
                                          IconButton(
                                            tooltip: 'Ištrinti',
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _confirmDeleteUser(u.id, u.displayLabel),
                                          ),
                                          IconButton(
                                            tooltip: 'Atstatyti slaptažodį',
                                            icon: const Icon(Icons.lock_reset),
                                            onPressed: () => _showAdminSetPasswordForUser(u.id),
                                          ),
                                          if (_isSuperAdmin)
                                            IconButton(
                                              tooltip: 'Perjungti admin',
                                              icon: const Icon(Icons.admin_panel_settings_outlined),
                                              onPressed: () => _toggleAdminForUser(u.id),
                                            ),
                                        ],
                                      )),
                                    ]),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
