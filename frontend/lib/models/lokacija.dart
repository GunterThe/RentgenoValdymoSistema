class Lokacija {
  final int id;
  final String pavadinimas;

  Lokacija({required this.id, required this.pavadinimas});

  factory Lokacija.fromJson(Map<String, dynamic> j) => Lokacija(
        id: j['id'] as int,
        pavadinimas: (j['pavadinimas'] ?? j['Pavadinimas'] ?? '') as String,
      );
}
