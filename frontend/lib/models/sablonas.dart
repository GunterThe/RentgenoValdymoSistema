class Sablonas {
  final int id;
  final String pavadinimas;

  const Sablonas({required this.id, required this.pavadinimas});

  factory Sablonas.fromJson(Map<String, dynamic> j) => Sablonas(
    id: (j['id'] ?? 0) as int,
    pavadinimas: (j['pavadinimas'] ?? j['Pavadinimas'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'pavadinimas': pavadinimas};
}
