class ZingsnisTemplate {
  final int id;
  String pavadinimas;
  String aprasymas;
  int testasId;
  int eile;
  bool komentarasPrivalomas;
  bool nuotraukaPrivaloma;

  ZingsnisTemplate({
    required this.id,
    required this.pavadinimas,
    required this.aprasymas,
    required this.testasId,
    required this.eile,
    this.komentarasPrivalomas = false,
    this.nuotraukaPrivaloma = false,
  });

  factory ZingsnisTemplate.fromJson(Map<String, dynamic> j) => ZingsnisTemplate(
        id: j['id'] as int,
        pavadinimas: j['pavadinimas'] ?? '',
        aprasymas: j['aprasymas'] ?? '',
        testasId: j['testasId'] ?? j['testas_id'] ?? 0,
        eile: j['eile'] ?? 0,
      komentarasPrivalomas: (j['komentarasPrivalomas'] ?? j['komentaras_privalomas'] ?? false) as bool,
      nuotraukaPrivaloma: (j['nuotraukaPrivaloma'] ?? j['nuotrauka_privaloma'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pavadinimas': pavadinimas,
        'aprasymas': aprasymas,
        'testasId': testasId,
        'eile': eile,
      'komentarasPrivalomas': komentarasPrivalomas,
      'nuotraukaPrivaloma': nuotraukaPrivaloma,
      };
}
