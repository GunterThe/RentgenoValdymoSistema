class Naudotojas {
  final String id;
  final String vardas;
  final String pavarde;

  Naudotojas({
    required this.id,
    required this.vardas,
    required this.pavarde,
  });

  factory Naudotojas.fromJson(Map<String, dynamic> j) {
    return Naudotojas(
      id: (j['id'] ?? '').toString(),
      vardas: (j['vardas'] ?? '') as String,
      pavarde: (j['pavarde'] ?? '') as String,
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
}
