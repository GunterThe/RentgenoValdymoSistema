class Naudotojas {
  final String id;
  final String vardas;
  final String pavarde;
  final String? prisijungimoId;
  final bool? adminas;

  Naudotojas({
    required this.id,
    required this.vardas,
    required this.pavarde,
    this.prisijungimoId,
    this.adminas,
  });

  factory Naudotojas.fromJson(Map<String, dynamic> j) {
    return Naudotojas(
      id: (j['id'] ?? '').toString(),
      vardas: (j['vardas'] ?? '') as String,
      pavarde: (j['pavarde'] ?? '') as String,
      prisijungimoId: (j['prisijungimoId'] ?? j['prisijungimoid'])?.toString(),
      adminas: j['adminas'] is bool ? (j['adminas'] as bool) : null,
    );
  }

  String get fullName {
    final v = vardas.trim();
    final p = pavarde.trim();
    if (v.isEmpty && p.isEmpty) return '';
    if (v.isEmpty) return p;
    if (p.isEmpty) return v;
    return '$v $p';
  }

  String get displayLabel {
    final name = fullName;
    final pid = (prisijungimoId ?? '').trim();
    if (pid.isEmpty) return name.isEmpty ? id : name;
    if (name.isEmpty) return pid;
    return '$name ($pid)';
  }
}
